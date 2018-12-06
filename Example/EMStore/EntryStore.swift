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
    var entities: ManagedObjectObservable<Entry>? { get }
    var new: Entry? { get }
    func add(model: Entry)
    func remove(model: Entry)
}

final class DefaultEntryStore: ManagedObjectStore<Entry>, EntryStore {
    init() throws {
        super.init(storage: try SqliteStorage<Entry>("Model"),
                   predicate: nil,
                   sortDescriptors: [NSSortDescriptor(key: "date", ascending: true)])
    }
}
