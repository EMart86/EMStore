//
//  SqliteStorage.swift
//  Whitelabel
//
//  Created by Martin Eberl on 04.04.17.
//  Copyright © 2017 Martin Eberl. All rights reserved.
//

import CoreData

public var sqlStorageFileUrl: URL?  {
    guard let path = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                         .userDomainMask, true).first else {
                                                            return nil
    }
    
    return URL(fileURLWithPath: path).appendingPathComponent("content.sqlite")
}

@available(iOS 10.0, *)
var sharedPersistentContainer: NSPersistentContainer?
var sharedManagedContext: NSManagedObjectContext?

public class SqliteStorage<T: NSManagedObject>: Storage {
    internal(set) public var provider = ObjectProvider()

    internal let momdName: String
    internal let sqlFileUrl: URL?
    internal var managedObjectContext: NSManagedObjectContext!
    
    public class func new<T: NSManagedObject>(momdName: String,
                                              sqlFileUrl: URL? = sqlStorageFileUrl) -> SqliteStorage<T> {
        let storage = SqliteStorage<T>(momdName, sqlFileUrl: sqlFileUrl)
        storage.createProvider(with: storage.newManagedObjectContext())
        return storage
    }
    
    public class func shared<T: NSManagedObject>(momdName: String,
                                                 sqlFileUrl: URL? = sqlStorageFileUrl) -> SqliteStorage<T> {
        let storage = SqliteStorage<T>(momdName, sqlFileUrl: sqlFileUrl)
        storage.createProvider(with: storage.sharedManagedObjectContext())
        return storage
    }
    
    internal init(_ momdName: String,
                sqlFileUrl: URL? = sqlStorageFileUrl) {
        self.momdName = momdName
        self.sqlFileUrl = sqlFileUrl
    }
    
    private func createProvider(with managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        provider = ManagedObjectProvider(managedObjectContext, cacheName: "Local_Master")
    }
    
    internal func newManagedObjectContext() -> NSManagedObjectContext {
        if #available(iOS 10.0, *) {
            let context = self.persistentContainer.viewContext
            return context
        } else {
            let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
            context.persistentStoreCoordinator = self.persistentStoreCoordinator
            return context
        }
    }
    
    internal func sharedManagedObjectContext() -> NSManagedObjectContext {
        if let sharedManagedContext = sharedManagedContext {
            return sharedManagedContext
        }
        let context = newManagedObjectContext()
        sharedManagedContext = context
        return context
    }
    
    public func insert(model: Any) {
        guard let model = model as? NSManagedObject else {
            return
        }
        managedObjectContext.insert(model)
    }
    
    public func remove(model: Any) {
        guard let model = model as? NSManagedObject else {
            return
        }
        managedObjectContext.delete(model)
    }
    
    public func commit() throws {
        if managedObjectContext.hasChanges {
            try managedObjectContext.save()
        }
    }
    
    public func rollback() {
        if managedObjectContext.hasChanges {
            managedObjectContext.rollback()
        }
    }
    
    enum CoreDataError: Error {
        case modelURLNotFound(forResourceName: String)
        case modelLoadingFailed(forURL: URL)
    }
    
    //MARK: - Helper
    private var _model: NSManagedObjectModel?
    internal func model(name: String) throws -> NSManagedObjectModel {
        if _model == nil {
            _model = try loadModel(name: name, bundle: Bundle.main)
        }
        return _model!
    }
    private func loadModel(name: String, bundle: Bundle) throws -> NSManagedObjectModel {
        guard let modelURL = bundle.url(forResource: name, withExtension: "momd") else {
            throw CoreDataError.modelURLNotFound(forResourceName: name)
        }

        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            throw CoreDataError.modelLoadingFailed(forURL: modelURL)
       }
        return model
    }
    
    @available(iOS 10.0, *)
    private lazy var persistentContainer: NSPersistentContainer = {
        if let sharedPersistentContainer = sharedPersistentContainer {
            return sharedPersistentContainer
        }
        let container = NSPersistentContainer(name: self.momdName)
        sharedPersistentContainer = container
        if let pathUrl = self.sqlFileUrl {
            container.persistentStoreDescriptions = [NSPersistentStoreDescription(url: pathUrl)]
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                print("Ops there was an error \(error.localizedDescription)")
                abort()
            }
        })
        return container
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        guard let model = try? model(name: momdName) else {
            return nil
        }
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        do {
            // If your looking for any kind of migration then here is the time to pass it to the options
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: self.sqlFileUrl, options: nil)
            
        } catch let  error as NSError {
            print("Ops there was an error \(error.localizedDescription)")
            abort()
        }
        return coordinator
    }()
}
