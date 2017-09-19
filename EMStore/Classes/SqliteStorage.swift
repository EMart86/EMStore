//
//  SqliteStorage.swift
//  Whitelabel
//
//  Created by Martin Eberl on 04.04.17.
//  Copyright © 2017 Martin Eberl. All rights reserved.
//

import Foundation
import CoreData

public struct ManagedObjectQuery: Query {
    let entity: NSManagedObject.Type
    let predicate: NSPredicate?
    let sortDescriptors: [NSSortDescriptor]
}

open class ManagedObjectStore<AnyManagedObject: NSManagedObject>: Store {
    private var observableModels: Observable<[AnyManagedObject]>?
    
    public func models<AnyManagedObject>() -> Observable<[AnyManagedObject]>? {
        if observableModels == nil {
            observableModels = storage.provider.observable(where: ManagedObjectQuery(entity: entity, predicate: predicate, sortDescriptors: sortDescriptors))
        }
        return observableModels as? Observable<[AnyManagedObject]>
    }
    
    public private(set) var storage: Storage
    private let entity: NSManagedObject.Type
    private let predicate: NSPredicate?
    private let sortDescriptors: [NSSortDescriptor]
    
    
    public init(storage: Storage, entity: NSManagedObject.Type, predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]) {
        self.storage = storage
        self.entity = entity
        self.predicate = predicate
        self.sortDescriptors = sortDescriptors
        
        if sortDescriptors.isEmpty {
            assertionFailure("Fetchrequest requires at least one sort-descriptor")
        }
    }
    
    public func new<T>() -> T? {
        return storage.provider.new()
    }
}

public final class ManagedObjectObservable<T: NSManagedObject>: Observable<[T]>, NSFetchedResultsControllerDelegate {
    private let fetchedResultsController: NSFetchedResultsController<T>
    
    public init(_ fetchedResultsController: NSFetchedResultsController<T>) {
        self.fetchedResultsController = fetchedResultsController
        super.init()
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
            value = fetchedResultsController.fetchedObjects
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
    
    public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("")
    }
    
    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("")
    }
    
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        value = fetchedResultsController.fetchedObjects
    }
}

final class ManagedObjectProvider: ObjectProvider {
    let managedObjectContext: NSManagedObjectContext
    init(_ managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        super.init()
    }
    
    override func observable<T: NSManagedObject>(where query: Query) -> Observable<[T]>? {
        guard let query = query as? ManagedObjectQuery,
            let entityName = NSStringFromClass(query.entity.self).components(separatedBy: ".").last else {
                assertionFailure("Expecting ManagedObjectStore.ManagedObjectQuery as closure parameter")
                return nil
        }
        let request = NSFetchRequest<T>(entityName: entityName)
        //request.fetchBatchSize = 20
        request.predicate = query.predicate
        request.sortDescriptors = query.sortDescriptors
        
        let controller = NSFetchedResultsController<T>(fetchRequest: request,
                                                       managedObjectContext: managedObjectContext,
                                                       sectionNameKeyPath: nil,
                                                       cacheName: "Master")
        return ManagedObjectObservable<T>(controller)
    }
    
    override func new<T: NSManagedObject>() -> T?{
        if #available(iOS 10.0, *) {
            return T(context: managedObjectContext)
        } else {
            guard let entityDescription =
                NSEntityDescription.entity(forEntityName: NSStringFromClass(T.self), in: managedObjectContext) else {
                return nil
            }
            
            return T(entity: entityDescription,
                            insertInto: managedObjectContext)
        }
    }
}

final class SqliteStorage<T: NSManagedObject>: Storage {

    private(set) var provider: ObjectProvider = ObjectProvider()
    
    private let momdName: String
    private let sqlFileUrl: URL?
    
    init(_ momdName: String,
         sqlFileUrl: URL? = nil) {
        self.momdName = momdName
        self.sqlFileUrl = sqlFileUrl
    }
    
    func createProvider() -> SqliteStorage<T> {
        let managedObjectContext = self.managedObjectContext
        provider = ManagedObjectProvider(managedObjectContext)
        return self
    }
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        if #available(iOS 10.0, *) {
            return self.persistentContainer.viewContext
        } else {
            var context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
            context.persistentStoreCoordinator = self.persistentStoreCoordinator
            return context
        }
    }()
    
    func insert(model: Any) {
        guard let model = model as? NSManagedObject else {
            return
        }
        managedObjectContext.insert(model)
    }
    
    func remove(model: Any) {
        guard let model = model as? NSManagedObject else {
            return
        }
        managedObjectContext.delete(model)
    }
    
    func commit() {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func rollback() {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.rollback()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    //MARK: - Helper
    
    @available(iOS 10.0, *)
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: self.momdName)
        if let pathUrl = self.sqlFileUrl {
            container.persistentStoreDescriptions = [NSPersistentStoreDescription(url: pathUrl)]
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: NSManagedObjectModel(contentsOf: self.sqlFileUrl!)!)
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
