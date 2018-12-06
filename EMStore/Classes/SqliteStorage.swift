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
    public typealias Model = AnyManagedObject
    
    open lazy var models: Observable<[Model]>? = {
        return (storage.provider as? ManagedObjectProvider)?.managedObservable(where: 
            ManagedObjectQuery(entity: Model.self,
                               predicate: self.predicate,
                               sortDescriptors: self.sortDescriptors)
        )
    }()
    
    open lazy var entities: ManagedObjectObservable<Model>? = {
        return (storage.provider as? ManagedObjectProvider)?.managedObservable(where:
            ManagedObjectQuery(entity: Model.self,
                               predicate: self.predicate,
                               sortDescriptors: self.sortDescriptors)
        )
    }()
    
    public private(set) var storage: Storage
    private let predicate: NSPredicate?
    private let sortDescriptors: [NSSortDescriptor]
    
    
    public init(storage: Storage, predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]) {
        self.storage = storage
        self.predicate = predicate
        self.sortDescriptors = sortDescriptors
        
        if sortDescriptors.isEmpty {
            assertionFailure("Fetchrequest requires at least one sort-descriptor")
        }
    }
    
    public var new: Model? {
        return storage.provider.new()
    }
}

public final class ManagedObjectObservable<T: NSManagedObject>: Observable<[T]>, NSFetchedResultsControllerDelegate {
    private let fetchedResultsController: NSFetchedResultsController<T>
    fileprivate var managedObjectObservers = [(String, Destroyable)]()
    
    public init(_ fetchedResultsController: NSFetchedResultsController<T>) {
        self.fetchedResultsController = fetchedResultsController
        super.init()
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
            DispatchQueue.main.async {[weak self] in
                self?.value = fetchedResultsController.fetchedObjects
            }
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
    
    public override func destroy(destroyable: Destroyable) {
        guard let index = managedObjectObservers.firstIndex(where: { $0.1.identifier == destroyable.identifier } ) else {
            super.destroy(destroyable: destroyable)
            return
        }
        
        observers.remove(at: index)
    }
    
    public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("")
    }
    
    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("")
    }
    
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        value = fetchedResultsController.fetchedObjects
        
        switch type {
        case .delete:
            guard let indexPath = indexPath, let anObject = anObject as? T else {
                return
            }
            managedObjectObservers
                .filter { $0.0 == ObserverIdentifier.removed }
                .compactMap { $0.1 as? InternalDestroyableOneParameterObserver<T, IndexPath> }
                .forEach { $0.block?.object(anObject, indexPath) }
        case .insert:
            guard let indexPath = newIndexPath, let anObject = anObject as? T else {
                return
            }
            managedObjectObservers
                .filter { $0.0 == ObserverIdentifier.added }
                .compactMap { $0.1 as? InternalDestroyableOneParameterObserver<T, IndexPath> }
                .forEach { $0.block?.object(anObject, indexPath) }
        case .move:
            guard let indexPath = indexPath, let newIndexPath = newIndexPath, let anObject = anObject as? T else {
                return
            }
            managedObjectObservers
                .filter { $0.0 == ObserverIdentifier.moved }
                .compactMap { $0.1 as? InternalDestroyableTwoParameterObserver<T, IndexPath, IndexPath> }
                .forEach { $0.block?.object(anObject, indexPath, newIndexPath) }
        case .update:
            guard let indexPath = indexPath, let anObject = anObject as? T else {
                return
            }
            managedObjectObservers
                .filter { $0.0 == ObserverIdentifier.updated }
                .compactMap { $0.1 as? InternalDestroyableOneParameterObserver<T, IndexPath> }
                .forEach { $0.block?.object(anObject, indexPath) }
        }
        
    }
}

extension ManagedObjectObservable {
    public func onItemAdded(_ closure: @escaping InternalDestroyableOneParameterObserver<T, IndexPath>.Block) -> Destroyable {
        let observerBlock = InternalDestroyableOneParameterObserver<T, IndexPath>(object: self,
                                                                                  block: ObserverBlock(object: closure))
        managedObjectObservers.append((ObserverIdentifier.added, observerBlock))
        return observerBlock
    }
    
    public func onItemRemoved(_ closure: @escaping InternalDestroyableOneParameterObserver<T, IndexPath>.Block) -> Destroyable {
        let observerBlock = InternalDestroyableOneParameterObserver<T, IndexPath>(object: self,
                                                                                  block: ObserverBlock(object: closure))
        managedObjectObservers.append((ObserverIdentifier.removed, observerBlock))
        return observerBlock
    }
    
    public func onItemMoved(_ closure: @escaping InternalDestroyableTwoParameterObserver<T, IndexPath, IndexPath>.Block) -> Destroyable {
        let observerBlock = InternalDestroyableTwoParameterObserver<T, IndexPath, IndexPath>(object: self,
                                                                                             block: ObserverBlock(object: closure))
        managedObjectObservers.append((ObserverIdentifier.moved, observerBlock))
        return observerBlock
    }
    
    public func onItemUpdated(_ closure: @escaping InternalDestroyableOneParameterObserver<T, IndexPath>.Block) -> Destroyable {
        let observerBlock = InternalDestroyableOneParameterObserver<T, IndexPath>(object: self,
                                                                                  block: ObserverBlock(object: closure))
        managedObjectObservers.append((ObserverIdentifier.updated, observerBlock))
        return observerBlock
    }
}

final class ManagedObjectProvider: ObjectProvider {
    let managedObjectContext: NSManagedObjectContext
    init(_ managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        super.init()
    }
    
    public func managedObservable<T: NSManagedObject>(where query: Query) -> ManagedObjectObservable<T>? {
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

public func sqlStorageFileUrl() throws -> URL  {
    enum SqlFile: Error {
        case filePathNotFound
    }
    
    guard let path = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                         .userDomainMask, true).first else {
                                                            throw SqlFile.filePathNotFound
    }
    
    return URL(fileURLWithPath: path).appendingPathComponent("content.sqlite")
}

final public class SqliteStorage<T: NSManagedObject>: Storage {    
    private(set) public var provider = ObjectProvider()
    
    private let momdName: String
    private let sqlFileUrl: URL
    
    public init(_ momdName: String,
                sqlFileUrl: URL? = nil) throws {
        self.momdName = momdName
        if let sqlFileUrl = sqlFileUrl {
            self.sqlFileUrl = sqlFileUrl
        } else {
            self.sqlFileUrl = try sqlStorageFileUrl()
        }
        createProvider()
    }
    
    private func createProvider() {
        provider = ManagedObjectProvider(self.managedObjectContext)
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
    
    public func commit() {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    public func rollback() {
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
        container.persistentStoreDescriptions = [NSPersistentStoreDescription(url: sqlFileUrl)]
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        guard let model = NSManagedObjectModel(contentsOf: sqlFileUrl) else {
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
