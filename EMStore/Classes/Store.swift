//
//  Store.swift
//  Whitelabel
//
//  Created by Martin Eberl on 04.04.17.
//  Copyright © 2017 Martin Eberl. All rights reserved.
//

import Foundation

public protocol Store {
    associatedtype Model
    var models: Observable<[Model]>? { get }
    var storage: Storage { get }

    func new() -> Model?
    func add(model: Model)
    func remove(model: Model)
}
