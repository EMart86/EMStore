//
//  Observable.swift
//  Whitelabel
//
//  Created by Martin Eberl on 17.04.17.
//  Copyright © 2017 Martin Eberl. All rights reserved.
//

import Foundation

protocol Destroyable {
    var identifier: Date { get }
    func destroy()
}

func ==(lhs: Destroyable, rhs: Destroyable) -> Bool {
    return lhs.identifier == rhs.identifier
}

struct ObserverBlock<T> {
    private(set) var object: T?
    init(object: T) {
        self.object = object
    }
}

struct DestroyableObserver<T>: Destroyable {
    private var object: Observable<T>
    private(set) var block:  ObserverBlock<(T) -> Void>?
    let identifier = Date()
    
    init(object: Observable<T>, block: ObserverBlock<(T) -> Void>) {
        self.object = object
        self.block = block
    }
    
    func destroy() {
        object.destroy(destroyable: self)
    }
}

open class Observable<T>: NSObject {
    internal var observers = [DestroyableObserver<T>]()

    var value: T? {
        didSet {
            notifyObservers()
        }
    }
    
    func onValueChanged(closure: @escaping (T) -> Void) -> Destroyable {
        let observerBlock = DestroyableObserver<T>(object: self, block: ObserverBlock<(T) -> Void>(object: closure))
        observers.append(observerBlock)
        return observerBlock
    }
    
    internal func destroy(destroyable: Destroyable) {
        guard let index = observers.index(where: { return $0 == destroyable } ) else {
            return
        }
        
        observers.remove(at: index)
    }
    
    //MARK: - Private
    
    private func notifyObservers() {
        guard let value = value else { return }
        observers
            .flatMap { return $0.block?.object }
            .forEach { $0(value) }
    }
}
