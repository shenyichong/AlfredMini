import Foundation
import AppKit
import CoreData

final class ClipboardStore: ObservableObject {
    static let shared = ClipboardStore()

    private let persistence = PersistenceController.shared
    private var context: NSManagedObjectContext { persistence.container.viewContext }

    @Published private(set) var items: [ClipboardItem] = []

    private let defaults = UserDefaults.standard
    private let retentionKey = "retentionLimit"

    var retentionLimit: Int {
        get { max(50, defaults.integer(forKey: retentionKey) == 0 ? 500 : defaults.integer(forKey: retentionKey)) }
        set { defaults.set(newValue, forKey: retentionKey) }
    }

    private init() {
        reload()
    }

    func reload() {
        let request = ClipboardItemMO.fetchRequestAll()
        // Sort by Pinned (desc), UseCount (desc), CreatedAt (desc)
        let sortPinned = NSSortDescriptor(key: "pinned", ascending: false)
        let sortCount = NSSortDescriptor(key: "useCount", ascending: false)
        let sortDate = NSSortDescriptor(key: "createdAt", ascending: false)
        request.sortDescriptors = [sortPinned, sortCount, sortDate]
        
        do {
            let result = try context.fetch(request)
            items = result.map { ClipboardItem(id: $0.id, text: $0.text, pinned: $0.pinned, createdAt: $0.createdAt, lastUsedAt: $0.lastUsedAt, useCount: $0.useCount) }
        } catch {
            items = []
        }
    }

    func add(text: String, pinned: Bool = false) {
        let existing = fetchDuplicate(text: text)
        if let existing = existing {
            existing.createdAt = Date()
            existing.lastUsedAt = Date()
            existing.pinned = existing.pinned || pinned
            existing.useCount += 1
        } else {
            _ = ClipboardItemMO.create(in: context, text: text, pinned: pinned)
        }
        save()
        pruneIfNeeded()
        reload()
    }

    func pin(itemId: UUID, pinned: Bool) {
        if let obj = fetchById(itemId) {
            obj.pinned = pinned
            save()
            reload()
        }
    }

    func delete(itemId: UUID) {
        if let obj = fetchById(itemId) {
            context.delete(obj)
            save()
            reload()
        }
    }

    func copyToPasteboard(item: ClipboardItem) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(item.text, forType: .string)
        if let obj = fetchById(item.id) {
            obj.lastUsedAt = Date()
            obj.useCount += 1
            save()
            reload()
        }
    }

    func search(_ query: String) -> [ClipboardItem] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return items }
        let q = query.lowercased()
        return items
            .map { item in (item, FuzzySearch.score(haystack: item.text.lowercased(), needle: q)) }
            .filter { $0.1 > 0 }
            .sorted { lhs, rhs in
                if lhs.0.pinned != rhs.0.pinned { return lhs.0.pinned }
                // Boost score by log(useCount) to favor frequent items in search too
                let lhsScore = Double(lhs.1) * (1.0 + log10(Double(max(1, lhs.0.useCount))))
                let rhsScore = Double(rhs.1) * (1.0 + log10(Double(max(1, rhs.0.useCount))))
                
                if abs(lhsScore - rhsScore) < 1.0 {
                    return lhs.0.createdAt > rhs.0.createdAt
                }
                return lhsScore > rhsScore
            }
            .map { $0.0 }
    }

    func pinCurrentClipboardIfText() {
        if let text = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
            add(text: text, pinned: true)
        }
    }

    private func fetchById(_ id: UUID) -> ClipboardItemMO? {
        let req = ClipboardItemMO.fetchRequestAll()
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        req.fetchLimit = 1
        return try? context.fetch(req).first
    }

    private func fetchDuplicate(text: String) -> ClipboardItemMO? {
        let req = ClipboardItemMO.fetchRequestAll()
        req.predicate = NSPredicate(format: "text == %@", text)
        req.fetchLimit = 1
        return try? context.fetch(req).first
    }

    private func pruneIfNeeded() {
        let req = ClipboardItemMO.fetchRequestAll()
        let sort = NSSortDescriptor(key: #keyPath(ClipboardItemMO.createdAt), ascending: false)
        req.sortDescriptors = [sort]
        guard let all = try? context.fetch(req) else { return }
        let pinned = all.filter { $0.pinned }
        let others = all.filter { !$0.pinned }
        if others.count + pinned.count <= retentionLimit { return }
        let toDelete = others.dropFirst(max(0, retentionLimit - pinned.count))
        toDelete.forEach { context.delete($0) }
        save()
    }

    private func save() {
        if context.hasChanges {
            try? context.save()
        }
    }
}

struct ClipboardItem: Identifiable, Equatable {
    let id: UUID
    let text: String
    let pinned: Bool
    let createdAt: Date
    let lastUsedAt: Date?
    let useCount: Int64
}


