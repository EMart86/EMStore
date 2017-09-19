//
//  Entry+CoreDataProperties.swift
//  
//
//  Created by Martin Eberl on 19.09.17.
//
//

import Foundation
import CoreData


extension Entry {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Entry> {
        return NSFetchRequest<Entry>(entityName: "Entry")
    }

    @NSManaged public var date: NSDate?

}
