//
//  Storage.swift
//  Whitelabel
//
//  Created by Martin Eberl on 04.04.17.
//  Copyright © 2017 Martin Eberl. All rights reserved.
//

import Foundation

public protocol Query {
}
open class ObjectProvider {
    public func observable<T>(where query: Query) -> Observable<[T]>? {
        return nil
    }
    
    public func new<T>() -> T?{
        return nil
    }
}

public protocol Storage {
    var provider: ObjectProvider { get }
    func insert(model: Any)
    func remove(model: Any)
    func commit()
    func rollback()
}
