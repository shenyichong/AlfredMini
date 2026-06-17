import CoreData

final class PersistenceController {
    static let shared = PersistenceController()
    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "AlfredMini", managedObjectModel: Self.buildModel())
        
        if inMemory {
            container.persistentStoreDescriptions = [{
                let d = NSPersistentStoreDescription()
                d.type = NSInMemoryStoreType
                return d
            }()]
        }

        container.loadPersistentStores { desc, error in
            if error != nil, let url = desc.url {
                try? FileManager.default.removeItem(at: url)
                self.container.loadPersistentStores { _, e in
                    if let e { fatalError("Core Data error: \(e)") }
                }
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    private static func buildModel() -> NSManagedObjectModel {
        let entity = NSEntityDescription()
        entity.name = "ClipboardItem"
        entity.managedObjectClassName = "ClipboardItemMO"
        entity.properties = [
            attr("id", .UUIDAttributeType),
            attr("text", .stringAttributeType),
            attr("pinned", .booleanAttributeType, default: false),
            attr("createdAt", .dateAttributeType),
            attr("lastUsedAt", .dateAttributeType, optional: true),
            attr("useCount", .integer64AttributeType, default: 1)
        ]
        entity.uniquenessConstraints = [["id"]]
        
        let model = NSManagedObjectModel()
        model.entities = [entity]
        return model
    }
    
    private static func attr(_ name: String, _ type: NSAttributeType, optional: Bool = false, default value: Any? = nil) -> NSAttributeDescription {
        let attr = NSAttributeDescription()
        attr.name = name
        attr.attributeType = type
        attr.isOptional = optional
        attr.defaultValue = value
        return attr
    }
}

