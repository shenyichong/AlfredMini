import Foundation
import CoreData

// MARK: - View Model

struct ClipboardItem: Identifiable, Equatable {
    let id: UUID
    let text: String
    let pinned: Bool
    let createdAt: Date
    let lastUsedAt: Date?
    let useCount: Int64
    
    init(from mo: ClipboardItemMO) {
        self.id = mo.id
        self.text = mo.text
        self.pinned = mo.pinned
        self.createdAt = mo.createdAt
        self.lastUsedAt = mo.lastUsedAt
        self.useCount = mo.useCount
    }

    init(
        id: UUID = UUID(),
        text: String,
        pinned: Bool = false,
        createdAt: Date = Date(),
        lastUsedAt: Date? = nil,
        useCount: Int64 = 0
    ) {
        self.id = id
        self.text = text
        self.pinned = pinned
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.useCount = useCount
    }
}

// MARK: - Core Data Model

@objc(ClipboardItemMO)
final class ClipboardItemMO: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var text: String
    @NSManaged var pinned: Bool
    @NSManaged var createdAt: Date
    @NSManaged var lastUsedAt: Date?
    @NSManaged var useCount: Int64
    
    @nonobjc static func fetchRequestAll() -> NSFetchRequest<ClipboardItemMO> {
        NSFetchRequest<ClipboardItemMO>(entityName: "ClipboardItem")
    }
    
    @discardableResult
    static func create(
        in context: NSManagedObjectContext,
        text: String,
        pinned: Bool = false,
        createdAt: Date = Date(),
        lastUsedAt: Date? = nil,
        useCount: Int64 = 1
    ) -> ClipboardItemMO {
        let obj = NSEntityDescription.insertNewObject(forEntityName: "ClipboardItem", into: context) as! ClipboardItemMO
        obj.id = UUID()
        obj.text = text
        obj.pinned = pinned
        obj.createdAt = createdAt
        obj.lastUsedAt = lastUsedAt
        obj.useCount = useCount
        return obj
    }
}

