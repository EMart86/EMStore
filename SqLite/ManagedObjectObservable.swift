//
//  ManagedObjectObservable.swift
//  Pods
//
//  Created by Martin Eberl on 31.01.21.
//

import CoreData

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
            return
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
