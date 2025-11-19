import SwiftUI

struct SearchPanelView: View {
    @ObservedObject private var store = ClipboardStore.shared
    @State private var query: String = ""
    @State private var selectionId: UUID?
    @FocusState private var isFocused: Bool
    
    private var results: [ClipboardItem] {
        store.search(query)
    }

    var body: some View {
        ZStack {
            // 1. Glass Background
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 2. Search Field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search clips...", text: $query)
                        .textFieldStyle(.plain)
                        .font(.system(size: 22, weight: .light))
                        .focused($isFocused)
                        .onSubmit { activateSelection() }
                }
                .padding(16)
                .background(Color.white.opacity(0.1))
                .overlay(Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.1)), alignment: .bottom)

                // 3. Results List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(results) { item in
                                ItemRow(item: item, isSelected: selectionId == item.id)
                                    .id(item.id)
                                    .onTapGesture {
                                        selectionId = item.id
                                        activateSelection()
                                    }
                            }
                        }
                    }
                    .onChange(of: selectionId) { id in
                        if let id = id {
                            withAnimation {
                                proxy.scrollTo(id, anchor: .center)
                            }
                        }
                    }
                }
            }
        }
        .frame(width: 700, height: 450)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
        )
        .onAppear {
            // Fix 1: Auto-focus text field
            isFocused = true
            // Select first item
            if selectionId == nil { selectionId = results.first?.id }
        }
        .onChange(of: query) { _ in
            selectionId = results.first?.id
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willResignActiveNotification)) { _ in
            query = ""
            // Re-focus when window might reappear later
            DispatchQueue.main.async { isFocused = true }
        }
        .background(
            // Fix 2: Intercept arrows to move selection
            KeyboardMonitor(
                onDown: { moveSelection(1) },
                onUp: { moveSelection(-1) },
                onCmdEnter: { togglePin() }
            )
        )
    }

    private func moveSelection(_ direction: Int) {
        guard !results.isEmpty else { return }
        guard let currentId = selectionId, let idx = results.firstIndex(where: { $0.id == currentId }) else {
            selectionId = results.first?.id
            return
        }
        
        let newIdx = min(max(idx + direction, 0), results.count - 1)
        selectionId = results[newIdx].id
    }

    private func activateSelection() {
        guard let id = selectionId, let item = results.first(where: { $0.id == id }) else { return }
        store.copyToPasteboard(item: item)
        SearchPanelController.shared.hide()
    }

    private func togglePin() {
        guard let id = selectionId, let item = results.first(where: { $0.id == id }) else { return }
        store.pin(itemId: id, pinned: !item.pinned)
    }
}

struct ItemRow: View {
    let item: ClipboardItem
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(item.text.replacingOccurrences(of: "\n", with: " ⏎ "))
                .lineLimit(1)
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(isSelected ? .white : .primary)
            
            Spacer()
            
            if item.pinned {
                Image(systemName: "pin.fill")
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(isSelected ? Color.accentColor.opacity(0.8) : Color.clear)
        .contentShape(Rectangle())
    }
}

// Updated Keyboard Monitor to handle Arrows + CmdEnter
private struct KeyboardMonitor: NSViewRepresentable {
    let onDown: () -> Void
    let onUp: () -> Void
    let onCmdEnter: () -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        let monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            // Arrow Down (125)
            if event.keyCode == 125 {
                onDown()
                return nil // Consume event so text cursor doesn't move
            }
            // Arrow Up (126)
            if event.keyCode == 126 {
                onUp()
                return nil
            }
            // Cmd + Return (36)
            if event.modifierFlags.contains(.command) && event.keyCode == 36 {
                onCmdEnter()
                return nil
            }
            return event
        }
        context.coordinator.monitor = monitor
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        if let monitor = coordinator.monitor { NSEvent.removeMonitor(monitor) }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }
    final class Coordinator { var monitor: Any? }
}
