//
//  AppleCloudStorage.swift
//  Pods
//
//  Created by Martin Eberl on 05.01.21.
//

import CloudKit

@available(iOS 11.0, *)
final public class AppleCloudStorage<T: Codable>: Storage {
    enum DatabaseType {
        case `public`
        case `private`
        case shared
        
        func database(with container: CKContainer) -> CKDatabase {
            switch self {
            case .private:
                return container.privateCloudDatabase
            case .public:
                return container.publicCloudDatabase
            case .shared:
                return container.sharedCloudDatabase
            }
        }
    }
    
    internal(set) public var provider = ObjectProvider()
    private let container: CKContainer
    private let database: CKDatabase
    
    public class func new<T: Codable>(containerId: String? = nil,
                                      databaseType: DatabaseType) -> AppleCloudStorage {
        let storage = AppleCloudStorage<T>(containerId: containerId,
                                           databaseType: databaseType)
        storage.crea
        
    }
    
    internal init(containerId: String? = nil,
                databaseType: DatabaseType) {
        
        if let containerId = containerId {
            container = CKContainer(identifier: containerId)
        } else {
            container = CKContainer.default()
        }
        database = databaseType.database(with: container)
    }
    
    private func createProvider() {
        provider = ManagedObjectProvider(managedObjectContext, cacheName: "Local_Master")
    }
    
    public func insert(model: Any) {
        <#code#>
    }
    
    public func remove(model: Any) {
        <#code#>
    }
    
    public func commit() throws {
        <#code#>
    }
    
    public func rollback() throws {
        <#code#>
    }
    
    internal func createProvider(with managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        provider = ManagedObjectProvider(self.managedObjectContext, cacheName: "AppleCloud_Master")
    }
    
    internal override func newManagedObjectContext() -> NSManagedObjectContext {
        if let sharedManagedContext = sharedManagedContext {
            return sharedManagedContext
        }
        let context = self.cloudKitContainer.viewContext
        sharedManagedContext = context
        context.automaticallyMergesChangesFromParent = migrateWithCloud
        try? context.setQueryGenerationFrom(.current)
        return context
    }
    
    //MARK: - Helper
    
    private lazy var cloudKitContainer: NSPersistentCloudKitContainer = {
        if let sharedPersistentContainer = sharedCloudPersistentContainer {
            return sharedPersistentContainer
        }
        do {
            let container = NSPersistentCloudKitContainer(name: self.momdName, managedObjectModel: try model(name: self.momdName))
            sharedCloudPersistentContainer = container
            
            // Enable history tracking and remote notifications
            guard let description = container.persistentStoreDescriptions.first else {
                fatalError("###\(#function): Failed to retrieve a persistent store description.")
            }

            if let pathUrl = self.sqlFileUrl {
                let description = NSPersistentStoreDescription(url: pathUrl)
                description.cloudKitContainerOptions =  NSPersistentCloudKitContainerOptions(containerIdentifier: containerId)
            
                description.setOption(true as NSNumber,
                                           forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
                description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
                container.persistentStoreDescriptions = [description]
            }
            
            container.loadPersistentStores(completionHandler: { (storeDescription, error) in
                if let error = error as NSError? {
                    print("Ops there was an error \(error.localizedDescription)")
                    abort()
                }
            })
            
//            container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            container.viewContext.transactionAuthor = "current"
            
            // Pin the viewContext to the current generation token and set it to keep itself up to date with local changes.
            container.viewContext.automaticallyMergesChangesFromParent = true
            do {
                try container.viewContext.setQueryGenerationFrom(.current)
            } catch {
                fatalError("###\(#function): Failed to pin viewContext to the current generation:\(error)")
            }
            
            return container
        } catch let error {
            print("Model could not be found \(T.self): \(error)")
            abort()
        }
    }()
    
    @objc private func fetchChanges() {
        print()
    }
}
