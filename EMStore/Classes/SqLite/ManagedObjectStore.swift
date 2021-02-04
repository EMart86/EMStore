//
//  ManagedObjectObservable.swift
//  Pods
//
//  Created by Martin Eberl on 31.01.21.
//

import CoreData

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
        return storage.provider.new(type: Model.self)
    }
}
