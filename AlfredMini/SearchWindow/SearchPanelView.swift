import SwiftUI

struct SearchPanelView: View {
    @ObservedObject private var store = ClipboardStore.shared
    @State private var query = ""
    @State private var selectionId: UUID?
    @FocusState private var isFocused: Bool
    
    private var results: [ClipboardItem] { store.search(query) }

    var body: some View {
        ZStack {
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow).ignoresSafeArea()
            VStack(spacing: 0) {
                searchField
                resultsList
                footerHints
            }
        }
        .frame(width: 700, height: 450)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.2), lineWidth: 0.5))
        .onAppear { isFocused = true; selectionId = results.first?.id }
        .onChange(of: query) { _ in selectionId = results.first?.id }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willResignActiveNotification)) { _ in
            query = ""
            DispatchQueue.main.async { isFocused = true }
        }
        .background(KeyboardHandler(
            onEsc: { SearchPanelController.shared.hide(restoreFocus: true) },
            onArrow: { moveSelection($0) },
            onEnter: { activateSelection() },
            onCmdEnter: { togglePin() },
            onCmdDigit: { selectByIndex($0) },
            onTab: { toggleSortMode() }
        ))
    }
    
    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundColor(.secondary)
            TextField("Search clips...", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 22, weight: .light))
                .focused($isFocused)
                .onSubmit { activateSelection() }
            
            // Sort mode toggle
            Picker("", selection: $store.sortMode) {
                ForEach(SortMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 140)
        }
        .padding(16)
        .background(Color.white.opacity(0.1))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.1)), alignment: .bottom)
    }
    
    private var resultsList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(results.enumerated()), id: \.element.id) { index, item in
                        ItemRow(item: item, isSelected: selectionId == item.id, index: index)
                            .id(item.id)
                            .onTapGesture { selectionId = item.id; activateSelection() }
                    }
                }
            }
            .onChange(of: selectionId) { id in
                if let id { withAnimation { proxy.scrollTo(id, anchor: .center) } }
            }
        }
    }
    
    private var footerHints: some View {
        HStack(spacing: 12) {
            Label("↵ Paste", systemImage: "return")
            Label("⌘↵ Pin", systemImage: "pin")
            Label("↑↓ Nav", systemImage: "arrow.up.arrow.down")
            Label("⇥ Sort", systemImage: "arrow.left.arrow.right")
            Spacer()
            Text("\(results.count) items")
        }
        .font(.caption).foregroundColor(.secondary).padding(10).background(Color.white.opacity(0.2))
    }

    private func selectByIndex(_ idx: Int) {
        guard idx < results.count else { return }
        selectionId = results[idx].id
        activateSelection()
    }

    private func moveSelection(_ delta: Int) {
        guard !results.isEmpty else { return }
        let idx = selectionId.flatMap { id in results.firstIndex { $0.id == id } } ?? 0
        selectionId = results[max(0, min(idx + delta, results.count - 1))].id
    }

    private func activateSelection() {
        guard let id = selectionId, let item = results.first(where: { $0.id == id }) else { return }
        let targetPid = SearchPanelController.shared.previouslyActiveAppPid
        store.copyToPasteboard(item: item)
        SearchPanelController.shared.hide(restoreFocus: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { PasteHelper.paste(toPid: targetPid) }
    }
    
    private func togglePin() {
        guard let id = selectionId, let item = results.first(where: { $0.id == id }) else { return }
        store.pin(itemId: id, pinned: !item.pinned)
    }
    
    private func toggleSortMode() {
        store.sortMode = store.sortMode == .recent ? .frequent : .recent
        selectionId = results.first?.id
    }
}

// MARK: - Item Row

private struct ItemRow: View {
    let item: ClipboardItem
    let isSelected: Bool
    let index: Int

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(index < 9 ? "⌘\(index + 1)" : "")
                .font(.caption2)
                .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary.opacity(0.5))
                .frame(width: 24, alignment: .trailing)
            
            Text(item.text.replacingOccurrences(of: "\n", with: " ⏎ "))
                .lineLimit(1)
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(isSelected ? .white : .primary)
            
            Spacer()
            
            if item.pinned {
                Image(systemName: "pin.fill").font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
        }
        .padding(.vertical, 8).padding(.horizontal, 12)
        .background(isSelected ? Color.accentColor.opacity(0.8) : Color.clear)
        .contentShape(Rectangle())
    }
}

// MARK: - Keyboard Handler

private struct KeyboardHandler: NSViewRepresentable {
    let onEsc: () -> Void
    let onArrow: (Int) -> Void
    let onEnter: () -> Void
    let onCmdEnter: () -> Void
    let onCmdDigit: (Int) -> Void
    let onTab: () -> Void
    
    private static let digitKeyCodes: [UInt16: Int] = [18:0, 19:1, 20:2, 21:3, 23:4, 22:5, 26:6, 28:7, 25:8]
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        context.coordinator.monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let cmd = event.modifierFlags.contains(.command)
            switch event.keyCode {
            case 53: onEsc(); return nil                                    // ESC
            case 48: onTab(); return nil                                    // Tab
            case 125: onArrow(1); return nil                                // Down
            case 126: onArrow(-1); return nil                               // Up
            case 36: cmd ? onCmdEnter() : onEnter(); return nil             // Enter
            default:
                if cmd, let idx = Self.digitKeyCodes[event.keyCode] {
                    onCmdDigit(idx); return nil
                }
            }
            return event
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        if let m = coordinator.monitor { NSEvent.removeMonitor(m) }
    }
    func makeCoordinator() -> Coordinator { Coordinator() }
    final class Coordinator { var monitor: Any? }
}
