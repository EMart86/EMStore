//
//  ManagedObjectQuery.swift
//  Pods
//
//  Created by Martin Eberl on 31.01.21.
//

import CoreData

public struct ManagedObjectQuery: Query {
    let entity: NSManagedObject.Type
    let predicate: NSPredicate?
    let sortDescriptors: [NSSortDescriptor]
}
