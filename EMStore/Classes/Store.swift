//
//  Store.swift
//  Whitelabel
//
//  Created by Martin Eberl on 04.04.17.
//  Copyright © 2017 Martin Eberl. All rights reserved.
//

import Foundation

public protocol Store {
    func models<T>(_ type: T.Type) -> Observable<[T]>?
    var storage: Storage { get }

    func new<T>() -> T?
    func add(model: Any)
    func remove(model: Any)
}

extension Store {
    public func add(model: Any) {
        storage.insert(model: model)
        storage.commit()
    }
    
    public func remove(model: Any) {
        storage.remove(model: model)
        storage.commit()
    }
}
