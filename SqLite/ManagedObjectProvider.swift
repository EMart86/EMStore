//
//  ManagedObjectProvider.swift
//  Pods
//
//  Created by Martin Eberl on 31.01.21.
//

import CoreData

final class ManagedObjectProvider: ObjectProvider {
    let managedObjectContext: NSManagedObjectContext
    private let cacheName: String
    init(_ managedObjectContext: NSManagedObjectContext, cacheName: String = "Master") {
        self.managedObjectContext = managedObjectContext
        self.cacheName = cacheName
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
                                                       cacheName: cacheName)
        return ManagedObjectObservable<T>(controller)
    }
    
    override func new<T>(type: T.Type) -> T? {
        guard let type = type as? NSManagedObject.Type else {
            return nil
        }
//        if #available(iOS 10.0, *) {
//            return type.init(context: managedObjectContext) as? T
//        } else {
            guard let entityDescription =
                NSEntityDescription.entity(
                    forEntityName: NSStringFromClass(type),
                    in: managedObjectContext
                ) else {
                    return nil
            }
            
            return type.init(
                entity: entityDescription,
                insertInto: managedObjectContext
                ) as? T
//        }
    }
}
