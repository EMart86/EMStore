//
//  Observable.swift
//  Whitelabel
//
//  Created by Martin Eberl on 17.04.17.
//  Copyright © 2017 Martin Eberl. All rights reserved.
//

import Foundation

public protocol Destroyable {
    var identifier: Date { get }
    func destroy()
}

public struct ObserverBlock<T> {
    let object: T
    init(object: T) {
        self.object = object
    }
}

public struct ObserverIdentifier {
    static let added = "added"
    static let removed = "removed"
    static let updated = "updated"
    static let moved = "moved"
    static let completed = "completed"
    static let beginning = "beginning"
}

public class InternalDestroyableTwoParameterObserver<M, N, O>: Destroyable {
    
    public typealias Block = (M, N, O) -> Void
    
    private let object: DestroyableObserver
    private let parameters: Array<Any>?
    private(set) var block: ObserverBlock<Block>?
    public let identifier = Date()
    
    init(object: DestroyableObserver, param: [Any]? = nil, block: ObserverBlock<Block>?) {
        self.object = object
        self.block = block
        self.parameters = param
    }
    
    public func destroy() {
        block = nil
        object.destroy(destroyable: self)
    }
}

public class InternalDestroyableOneParameterObserver<M, N>: Destroyable {
    
    public typealias Block = (M, N) -> Void
    
    private let object: DestroyableObserver
    private let parameters: Array<Any>?
    private(set) var block: ObserverBlock<Block>?
    public let identifier = Date()
    
    init(object: DestroyableObserver, param: [Any]? = nil, block: ObserverBlock<Block>?) {
        self.object = object
        self.block = block
        self.parameters = param
    }
    
    public func destroy() {
        block = nil
        object.destroy(destroyable: self)
    }
}

public class InternalDestroyableObserver<M>: Destroyable {
    
    public typealias Block = (M) -> Void
    
    private let object: DestroyableObserver
    private let parameters: Array<Any>?
    private(set) var block: ObserverBlock<Block>?
    public let identifier = Date()
    
    init(object: DestroyableObserver, param: [Any]? = nil, block: ObserverBlock<Block>?) {
        self.object = object
        self.block = block
        self.parameters = param
    }
    
    public func destroy() {
        block = nil
        object.destroy(destroyable: self)
    }
}

public protocol DestroyableObserver {
    func destroy(destroyable: Destroyable)
}

open class Observable<Value>: NSObject, DestroyableObserver {
    internal var observers = [InternalDestroyableObserver<Value>]()
    
    public var value: Value? {
        didSet {
            notifyObserversValueChanged()
        }
    }
    
    public func onValueChanged(_ closure: @escaping InternalDestroyableObserver<Value>.Block) -> Destroyable {
        let observerBlock = InternalDestroyableObserver<Value>(object: self,
                                                               param: nil,
                                                               block: ObserverBlock(object: closure)
        )
        observers.append(observerBlock)
        return observerBlock
    }
    
    public func destroy(destroyable: Destroyable) {
        guard let index = observers.firstIndex(where: { $0.identifier == destroyable.identifier } ) else {
            return
        }
        
        observers.remove(at: index)
    }
    
    //MARK: - Private
    
    private func notifyObserversValueChanged() {
        guard let value = value else { return }
        observers
            .compactMap { $0.block?.object }
            .forEach { $0(value) }
    }
}
