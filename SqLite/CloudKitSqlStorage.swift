//
//  CloudKitSqlStorage.swift
//  Pods
//
//  Created by Martin Eberl on 05.01.21.
//

import CoreData
import CloudKit

public var cloudSqlStorageFileUrl: URL?  {
    guard let path = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                         .userDomainMask, true).first else {
                                                            return nil
    }
    
    return URL(fileURLWithPath: path).appendingPathComponent("cloud-content.sqlite")
}

@available(iOS 13.0, *)
var sharedCloudPersistentContainer: NSPersistentCloudKitContainer?

@available(iOS 13.0, *)
final public class CloudKitSqliteStorage<T: NSManagedObject>: SqliteStorage<T> {
    private let containerId: String
    private let migrateWithCloud: Bool
    
    public class func new<T: NSManagedObject>(momdName: String,
                                              containerId: String,
                                              sqlFileUrl: URL? = cloudSqlStorageFileUrl,
                                              migrateWithCloud: Bool = false) -> SqliteStorage<T> {
        let storage = CloudKitSqliteStorage<T>(momdName,
                                               containerId: containerId,
                                               sqlFileUrl: sqlFileUrl,
                                               migrateWithCloud: migrateWithCloud)
        storage.createProvider(with: storage.newManagedObjectContext())
        return storage
    }
    
    public class func shared<T: NSManagedObject>(momdName: String,
                                                 containerId: String,
                                                 sqlFileUrl: URL? = cloudSqlStorageFileUrl,
                                                 migrateWithCloud: Bool) -> SqliteStorage<T> {
        let storage = CloudKitSqliteStorage<T>(momdName,
                                               containerId: containerId,
                                               sqlFileUrl: sqlFileUrl,
                                               migrateWithCloud: migrateWithCloud)
        storage.createProvider(with: storage.sharedManagedObjectContext())
        return storage
    }
    
    internal init(_ momdName: String,
                containerId: String,
                sqlFileUrl: URL? = cloudSqlStorageFileUrl,
                migrateWithCloud: Bool) {
        self.containerId = containerId
        self.migrateWithCloud = migrateWithCloud
        super.init(momdName, sqlFileUrl: sqlFileUrl)
        
        NotificationCenter.default.addObserver(
        self,
        selector: #selector(type(of: self).fetchChanges),
        name: .NSPersistentStoreRemoteChange,
        object: cloudKitContainer)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
