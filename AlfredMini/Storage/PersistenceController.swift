import Foundation
import CoreData

final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        let model = PersistenceController.buildModel()
        container = NSPersistentContainer(name: "AlfredMini", managedObjectModel: model)
        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores { description, error in
            if error != nil {
                // If loading fails (likely model mismatch in dev), remove the store and retry
                // WARNING: This deletes user data, acceptable for dev iteration.
                if let url = description.url {
                    try? FileManager.default.removeItem(at: url)
                }
                
                // Retry loading
                self.container.loadPersistentStores { _, retryError in
                    if let retryError = retryError {
                        fatalError("Unresolved error loading persistent stores: \(retryError)")
                    }
                }
            }
        }

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    private static func buildModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // Entity: ClipboardItem
        let entity = NSEntityDescription()
        entity.name = "ClipboardItem"
        entity.managedObjectClassName = "ClipboardItemMO"

        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType
        idAttr.isOptional = false

        let textAttr = NSAttributeDescription()
        textAttr.name = "text"
        textAttr.attributeType = .stringAttributeType
        textAttr.isOptional = false

        let pinnedAttr = NSAttributeDescription()
        pinnedAttr.name = "pinned"
        pinnedAttr.attributeType = .booleanAttributeType
        pinnedAttr.isOptional = false
        pinnedAttr.defaultValue = false

        let createdAtAttr = NSAttributeDescription()
        createdAtAttr.name = "createdAt"
        createdAtAttr.attributeType = .dateAttributeType
        createdAtAttr.isOptional = false

        let lastUsedAtAttr = NSAttributeDescription()
        lastUsedAtAttr.name = "lastUsedAt"
        lastUsedAtAttr.attributeType = .dateAttributeType
        lastUsedAtAttr.isOptional = true

        let useCountAttr = NSAttributeDescription()
        useCountAttr.name = "useCount"
        useCountAttr.attributeType = .integer64AttributeType
        useCountAttr.isOptional = false
        useCountAttr.defaultValue = 1

        entity.properties = [idAttr, textAttr, pinnedAttr, createdAtAttr, lastUsedAtAttr, useCountAttr]

        // Unique constraint on id
        entity.uniquenessConstraints = [["id"]]

        model.entities = [entity]
        return model
    }
}


