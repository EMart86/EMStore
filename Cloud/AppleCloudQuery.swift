//
//  AppleCloudQuery.swift
//  Pods
//
//  Created by Martin Eberl on 31.01.21.
//

import CloudKit

public struct AppleCloudQuery: Query {
    let predicate: NSPredicate?
    let sortDescriptors: [NSSortDescriptor]
}
