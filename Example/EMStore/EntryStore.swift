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
    func add(model: Entry) throws
    func remove(model: Entry) throws
    func commit() throws
    func rollback() throws
}

final class DefaultEntryStore: ManagedObjectStore<Entry>, EntryStore {
    
    init() {
        super.init(storage: SqliteStorage<Entry>.shared(momdName: "Model"),
                   predicate: nil,
                   sortDescriptors: [NSSortDescriptor(key: "date", ascending: true)])
    }
}

final class CloudEntryStore: ManagedObjectStore<Entry>, EntryStore {
    init() {
        if #available(iOS 13.0, *) {
            super.init(storage: CloudKitSqliteStorage<Entry>.shared(momdName: "Model", containerId: "iCloud.<bundle id>", migrateWithCloud: false),
                       predicate: nil,
                       sortDescriptors: [NSSortDescriptor(key: "date", ascending: true)])
        } else {
            super.init(storage: SqliteStorage<Entry>.shared(momdName: "Model"),
                       predicate: nil,
                       sortDescriptors: [NSSortDescriptor(key: "date", ascending: true)])
        }
    }
    
    public func add(model: Model) throws {
        storage.insert(model: model)
        try storage.commit()
    }
}
