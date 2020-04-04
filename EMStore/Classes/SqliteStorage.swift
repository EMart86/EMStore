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
        managedObjectObservers
            .filter { $0.0 == ObserverIdentifier.beginning }
            .compactMap { $0.1 as? InternalDestroyableObserver<Any?> }
            .forEach { $0.block?.object(nil) }
    }
    
    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        managedObjectObservers
            .filter { $0.0 == ObserverIdentifier.completed }
            .compactMap { $0.1 as? InternalDestroyableObserver<Any?> }
            .forEach { $0.block?.object(nil) }
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
        @unknown default:
            break
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
    
    public func onBeginning(_ closure: @escaping InternalDestroyableObserver<Any?>.Block) -> Destroyable {
        let observerBlock = InternalDestroyableObserver<Any?>(object: self,
                                                              block: ObserverBlock(object: closure))
        managedObjectObservers.append((ObserverIdentifier.beginning, observerBlock))
        return observerBlock
    }
    
    public func onComplete(_ closure: @escaping InternalDestroyableObserver<Any?>.Block) -> Destroyable {
        let observerBlock = InternalDestroyableObserver<Any?>(object: self,
                                                              block: ObserverBlock(object: closure))
        managedObjectObservers.append((ObserverIdentifier.completed, observerBlock))
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

public var sqlStorageFileUrl: URL?  {
    guard let path = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                         .userDomainMask, true).first else {
                                                            return nil
    }
    
    return URL(fileURLWithPath: path).appendingPathComponent("content.sqlite")
}

@available(iOS 10.0, *)
var sharedPersistentContainer: NSPersistentContainer?
@available(tvOS 13.0, *)
@available(iOS 13.0, *)
var sharedCloudPersistentContainer: NSPersistentCloudKitContainer?
var sharedManagedContext: NSManagedObjectContext?

final public class SqliteStorage<T: NSManagedObject>: Storage {
    private(set) public var provider = ObjectProvider()

    private let momdName: String
    private let sqlFileUrl: URL?
    
    public init(_ momdName: String,
                sqlFileUrl: URL? = sqlStorageFileUrl) {
        self.momdName = momdName
        self.sqlFileUrl = sqlFileUrl
        createProvider()
    }
    
    private func createProvider() {
        provider = ManagedObjectProvider(self.managedObjectContext)
    }
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        if let sharedManagedContext = sharedManagedContext {
            return sharedManagedContext
        }
        if #available(iOS 10.0, *) {
            let context = self.persistentContainer.viewContext
            sharedManagedContext = context
            return context
        } else {
            var context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
            sharedManagedContext = context
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
    
    public func commit() throws {
        if managedObjectContext.hasChanges {
            try managedObjectContext.save()
        }
    }
    
    public func rollback() throws {
        if managedObjectContext.hasChanges {
            try managedObjectContext.rollback()
        }
    }
    
    //MARK: - Helper
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
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        guard let bundle = Bundle.allBundles.first(where: { bundle in
            bundle.url(forResource: momdName, withExtension: "momd") != nil }),
            let pathUrl = bundle.url(forResource: momdName, withExtension: "momd"),
            let model = NSManagedObjectModel(contentsOf: pathUrl) else {
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

@available(tvOS 13.0, *)
@available(iOS 13.0, *)
final public class CloudKitSqliteStorage<T: NSManagedObject>: Storage {
    private(set) public var provider = ObjectProvider()

    private let momdName: String
    private let containerId: String
    private let sqlFileUrl: URL?
    
    public init(_ momdName: String,
                containerId: String,
                sqlFileUrl: URL? = sqlStorageFileUrl) {
        self.momdName = momdName
        self.containerId = containerId
        self.sqlFileUrl = sqlFileUrl
        createProvider()
    }
    
    private func createProvider() {
        provider = ManagedObjectProvider(self.managedObjectContext)
    }
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        if let sharedManagedContext = sharedManagedContext {
            return sharedManagedContext
        }
        let context = self.cloudKitContainer.viewContext
        context.automaticallyMergesChangesFromParent = true
        try? context.setQueryGenerationFrom(.current)
        sharedManagedContext = context
        return context
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
    
    public func commit() throws {
        if managedObjectContext.hasChanges {
            try managedObjectContext.save()
        }
    }
    
    public func rollback() throws {
        if managedObjectContext.hasChanges {
            try managedObjectContext.rollback()
        }
    }
    
    //MARK: - Helper
    @available(tvOS 13.0, *)
    @available(iOS 13.0, *)
    private lazy var cloudKitContainer: NSPersistentCloudKitContainer = {
        if let sharedPersistentContainer = sharedCloudPersistentContainer {
            return sharedPersistentContainer
        }
        let container = NSPersistentCloudKitContainer(name: self.momdName)
        sharedCloudPersistentContainer = container
        if let pathUrl = self.sqlFileUrl {
            container.persistentStoreDescriptions = [NSPersistentStoreDescription(url: pathUrl)]
            container.persistentStoreDescriptions.first?.cloudKitContainerOptions =  NSPersistentCloudKitContainerOptions(containerIdentifier: containerId)
        }
//        try? container.initializeCloudKitSchema()
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        guard let bundle = Bundle.allBundles.first(where: { bundle in
            bundle.url(forResource: momdName, withExtension: "momd") != nil }),
            let pathUrl = bundle.url(forResource: momdName, withExtension: "momd"),
            let model = NSManagedObjectModel(contentsOf: pathUrl) else {
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
