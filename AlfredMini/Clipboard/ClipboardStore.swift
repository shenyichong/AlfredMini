import Foundation
import AppKit
import CoreData

enum SortMode: String, CaseIterable {
    case recent = "Recent"
    case frequent = "Frequent"
}

final class ClipboardStore: ObservableObject {
    static let shared = ClipboardStore()
    private static let frequentWindowDays = 15

    private var context: NSManagedObjectContext { PersistenceController.shared.container.viewContext }
    private var transientItems: [ClipboardItem] = []
    @Published private(set) var items: [ClipboardItem] = []
    @Published var sortMode: SortMode = .recent { didSet { reload() } }

    var retentionLimit: Int {
        get { max(50, UserDefaults.standard.integer(forKey: "retentionLimit").nonZero ?? 500) }
        set { UserDefaults.standard.set(newValue, forKey: "retentionLimit") }
    }

    private init() { reload() }

    func reload() {
        let request = ClipboardItemMO.fetchRequestAll()
        guard let result = try? context.fetch(request) else { items = []; return }
        let mapped = result.map { ClipboardItem(from: $0) }

        let pinned = mapped.filter { $0.pinned }.sorted { $0.createdAt > $1.createdAt }
        let pinnedTexts = Set(pinned.map { $0.text })
        let transientForDisplay = transientItems.filter { !pinnedTexts.contains($0.text) }
        let transientTexts = Set(transientForDisplay.map { $0.text })
        let unpinnedPersisted = mapped.filter { !$0.pinned && !transientTexts.contains($0.text) }
        let unpinned = unpinnedPersisted + transientForDisplay

        let sortedUnpinned: [ClipboardItem]
        switch sortMode {
        case .recent:
            // Sort by most recent activity (copy or use)
            // Pinned items are not shown in recent tab
            sortedUnpinned = unpinned.sorted(by: compareByRecent)
            items = sortedUnpinned
        case .frequent:
            // Sort by use count, then by recent activity as tiebreakers
            // Pinned items are shown at the top in frequent tab
            let sortedPinned = pinned.sorted(by: compareByFrequent)
            sortedUnpinned = unpinned.sorted(by: compareByFrequent)
            items = sortedPinned + sortedUnpinned
        }
    }

    func capture(text: String) {
        let now = Date()
        if let idx = transientItems.firstIndex(where: { $0.text == text }) {
            transientItems[idx] = ClipboardItem(
                id: transientItems[idx].id,
                text: text,
                createdAt: now
            )
        } else {
            transientItems.append(ClipboardItem(text: text, createdAt: now))
        }
        if transientItems.count > retentionLimit {
            transientItems.sort { $0.createdAt > $1.createdAt }
            transientItems = Array(transientItems.prefix(retentionLimit))
        }
        reload()
    }

    func add(text: String, pinned: Bool = false) {
        if let existing = fetch(text: text) {
            existing.createdAt = Date()
            existing.lastUsedAt = Date()
            existing.pinned = existing.pinned || pinned
            existing.useCount += 1
        } else {
            ClipboardItemMO.create(
                in: context,
                text: text,
                pinned: pinned,
                createdAt: Date(),
                lastUsedAt: Date(),
                useCount: 1
            )
        }
        save()
        pruneIfNeeded()
        reload()
    }

    func pin(itemId: UUID, pinned: Bool) {
        if let obj = fetch(id: itemId) {
            obj.pinned = pinned
            save()
            reload()
            return
        }
        guard let item = items.first(where: { $0.id == itemId }) else { return }
        let obj = fetch(text: item.text) ?? ClipboardItemMO.create(
            in: context,
            text: item.text,
            pinned: pinned,
            createdAt: item.createdAt,
            lastUsedAt: item.lastUsedAt,
            useCount: max(1, item.useCount)
        )
        obj.pinned = pinned
        obj.createdAt = item.createdAt
        save()
        removeTransient(text: item.text)
        reload()
    }

    func delete(itemId: UUID) {
        if let obj = fetch(id: itemId) {
            context.delete(obj)
            save()
            reload()
            return
        }
        if let item = items.first(where: { $0.id == itemId }) {
            removeTransient(text: item.text)
            reload()
        }
    }

    func copyToPasteboard(item: ClipboardItem) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.text, forType: .string)

        let now = Date()
        if let obj = fetch(id: item.id) {
            obj.lastUsedAt = now
            obj.useCount += 1
        } else if let obj = fetch(text: item.text) {
            obj.lastUsedAt = now
            obj.useCount += 1
            obj.createdAt = item.createdAt
        } else {
            _ = ClipboardItemMO.create(
                in: context,
                text: item.text,
                pinned: item.pinned,
                createdAt: item.createdAt,
                lastUsedAt: now,
                useCount: 1
            )
        }
        save()
        removeTransient(text: item.text)
        reload()
    }

    func search(_ query: String) -> [ClipboardItem] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return items }
        
        return items
            .compactMap { item -> (ClipboardItem, Double)? in
                let score = FuzzySearch.score(haystack: item.text.lowercased(), needle: q)
                return score > 0 ? (item, Double(score) * (1 + log10(Double(max(1, item.useCount))))) : nil
            }
            .sorted { lhs, rhs in
                if lhs.0.pinned != rhs.0.pinned { return lhs.0.pinned }
                if abs(lhs.1 - rhs.1) >= 1.0 { return lhs.1 > rhs.1 }
                switch sortMode {
                case .recent:
                    return compareByRecent(lhs.0, rhs.0)
                case .frequent:
                    return compareByFrequent(lhs.0, rhs.0)
                }
            }
            .map { $0.0 }
    }

    func pinCurrentClipboard() {
        guard let text = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else { return }
        add(text: text, pinned: true)
    }

    // MARK: - Private

    private func fetch(id: UUID) -> ClipboardItemMO? {
        let req = ClipboardItemMO.fetchRequestAll()
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        req.fetchLimit = 1
        return try? context.fetch(req).first
    }

    private func fetch(text: String) -> ClipboardItemMO? {
        let req = ClipboardItemMO.fetchRequestAll()
        req.predicate = NSPredicate(format: "text == %@", text)
        req.fetchLimit = 1
        return try? context.fetch(req).first
    }

    private func removeTransient(text: String) {
        transientItems.removeAll { $0.text == text }
    }

    private func pruneIfNeeded() {
        let req = ClipboardItemMO.fetchRequestAll()
        guard let all = try? context.fetch(req) else { return }

        let pinned = all.filter { $0.pinned }
        let unpinned = all.filter { !$0.pinned }
        guard pinned.count + unpinned.count > retentionLimit else { return }

        // Keep the most valuable unpinned items, ranked by most recent activity
        // (copy OR use) and then by how often they've been used. This ensures an
        // item you keep reusing is never evicted just because it was first copied
        // a long time ago — using an item via the picker only bumps `lastUsedAt`,
        // not `createdAt`, so ranking by `createdAt` alone silently dropped
        // frequently-used clips.
        let ranked = unpinned.sorted { lhs, rhs in
            let lhsActivity = max(lhs.createdAt, lhs.lastUsedAt ?? .distantPast)
            let rhsActivity = max(rhs.createdAt, rhs.lastUsedAt ?? .distantPast)
            if lhsActivity != rhsActivity { return lhsActivity > rhsActivity }
            return lhs.useCount > rhs.useCount
        }
        ranked.dropFirst(max(0, retentionLimit - pinned.count)).forEach { context.delete($0) }
        save()
    }

    private func save() {
        guard context.hasChanges else { return }
        try? context.save()
    }

    private func lastActivity(of item: ClipboardItem) -> Date {
        max(item.createdAt, item.lastUsedAt ?? .distantPast)
    }

    private func compareByRecent(_ lhs: ClipboardItem, _ rhs: ClipboardItem) -> Bool {
        let lhsActivity = lastActivity(of: lhs)
        let rhsActivity = lastActivity(of: rhs)
        if lhsActivity != rhsActivity { return lhsActivity > rhsActivity }
        if lhs.createdAt != rhs.createdAt { return lhs.createdAt > rhs.createdAt }
        return lhs.text.localizedCaseInsensitiveCompare(rhs.text) == .orderedAscending
    }

    private func compareByFrequent(_ lhs: ClipboardItem, _ rhs: ClipboardItem) -> Bool {
        let cutoff = Calendar.current.date(byAdding: .day, value: -Self.frequentWindowDays, to: Date()) ?? .distantPast
        let lhsInWindow = lastActivity(of: lhs) >= cutoff
        let rhsInWindow = lastActivity(of: rhs) >= cutoff
        if lhsInWindow != rhsInWindow { return lhsInWindow }
        if lhsInWindow, lhs.useCount != rhs.useCount { return lhs.useCount > rhs.useCount }
        return compareByRecent(lhs, rhs)
    }
}

private extension Int {
    var nonZero: Int? { self == 0 ? nil : self }
}
