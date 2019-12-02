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
    var storage: Storage { get }
    var new: Model? { get }
    
    func add(model: Model) throws
    func remove(model: Model) throws
    func commit() throws
    func rollback() throws
}

