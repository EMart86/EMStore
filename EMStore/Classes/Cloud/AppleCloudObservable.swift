//
//  AppleCloudObservable.swift
//  Pods
//
//  Created by Martin Eberl on 31.01.21.
//

import CloudKit

public final class AppleCloudObservable<T: Codable>: Observable<[T]> {
    
    public init(database: CKDatabase, query: CKQuery) {
        super.init()
        database.perform(query, inZoneWith: CKRecordZone.default().zoneID, completionHandler: { [weak self] records, error in
                    self?.processQueryResponseWith(records: records, error: error as NSError?)
        })
    }
    
    private func processQueryResponseWith(records: [CKRecord]?, error: NSError?) {
        guard error == nil else { return }
        guard let records = records, records.count > 0 else { return }
            
        let decoder = Decoder(
        value = records.map { T() }
    }
}
