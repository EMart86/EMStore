//
//  AppleCloudProvidable.swift
//  Pods
//
//  Created by Martin Eberl on 31.01.21.
//

import CloudKit

final class AppleCloudProvider: ObjectProvider {
    
    private let database: CKDatabase
    
    init(database: CKDatabase) {
        self.database = database
        super.init()
    }
    
    public func obserable<T: Codable>(where query: Query) -> Observable<T>? {
        guard let query = query as? AppleCloudQuery,
              let entityName = String(describing: T.self).components(separatedBy: ".").last else {
                assertionFailure("Expecting ManagedObjectStore.ManagedObjectQuery as closure parameter")
                return nil
        }
        let cloudQuery = CKQuery(recordType: entityName, predicate: query.predicate ?? NSPredicate(value: true))
        cloudQuery.sortDescriptors = query.sortDescriptors
        
        return AppleCloudObservable<T>(database: database, query: cloudQuery)
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
