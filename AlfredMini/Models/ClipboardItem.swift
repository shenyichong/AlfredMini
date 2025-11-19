import Foundation
import CoreData

@objc(ClipboardItemMO)
final class ClipboardItemMO: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var text: String
    @NSManaged var pinned: Bool
    @NSManaged var createdAt: Date
    @NSManaged var lastUsedAt: Date?
    @NSManaged var useCount: Int64
}

extension ClipboardItemMO {
    @nonobjc static func fetchRequestAll() -> NSFetchRequest<ClipboardItemMO> {
        NSFetchRequest<ClipboardItemMO>(entityName: "ClipboardItem")
    }

    static func create(in context: NSManagedObjectContext, text: String, pinned: Bool = false) -> ClipboardItemMO {
        let obj = NSEntityDescription.insertNewObject(forEntityName: "ClipboardItem", into: context) as! ClipboardItemMO
        obj.id = UUID()
        obj.text = text
        obj.pinned = pinned
        obj.createdAt = Date()
        obj.lastUsedAt = nil
        obj.useCount = 1
        return obj
    }
}


