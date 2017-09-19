//
//  EntryStore.swift
//  EMStore
//
//  Created by Martin Eberl on 19.09.17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//
import EMStore
import Foundation

protocol EntryStore {
    var entries: Observable<[Entry]>? { get }
    var new: Entry? { get }
    func add(model: Entry)
    func remove(model: Entry)
}

final class DefaultEntryStore: ManagedObjectStore<Entry>, EntryStore {
    
    init() {
        super.init(storage: SqliteStorage<Entry>("Model").createProvider(),
                   entity: Entry.self,
                   predicate: nil,
                   sortDescriptors: [NSSortDescriptor(key: "date", ascending: true)])
    }
    
    var entries: Observable<[Entry]>? {
        return models()
    }
    
    var new: Entry? {
        return new()
    }
    
    func add(model: Entry) {
        super.add(model: model)
    }
    
    func remove(model: Entry) {
        super.remove(model: model)
    }
}
