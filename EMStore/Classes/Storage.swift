//
//  Storage.swift
//  Whitelabel
//
//  Created by Martin Eberl on 04.04.17.
//  Copyright © 2017 Martin Eberl. All rights reserved.
//

import Foundation
import CoreData

public protocol Query {
}

public class ObjectProvider {
    public func observable<T, Type: Observable<T>>(where query: Query) -> Type? {
        return nil
    }
    
    public func new<T>(type: T.Type) -> T?{
        return nil
    }
}

public protocol Storage {
    var provider: ObjectProvider { get }
    func insert(model: Any)
    func remove(model: Any)
    func commit() throws
    func rollback() throws
}

extension Store where Model: NSManagedObject {
    public func add(model: Model) throws {
        storage.insert(model: model)
        //try storage.commit()
    }
    
    public func remove(model: Model) throws {
        storage.remove(model: model)
        //try storage.commit()
    }
    
    public func commit() throws {
        try storage.commit()
    }
    
    public func rollback() throws {
        try storage.rollback()
    }
}
