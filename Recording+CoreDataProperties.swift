//
//  Recording+CoreDataProperties.swift
//  
//
//  Created by Brad Howes on 10/11/16.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Recording {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Recording> {
        return NSFetchRequest<Recording>(entityName: "Recording");
    }

    @NSManaged public var awaitingUpload: Bool
    @NSManaged public var driver: String?
    @NSManaged public var emitInterval: Int32
    @NSManaged public var endTime: NSDate?
    @NSManaged public var size: String?
    @NSManaged public var startTime: NSDate?
    @NSManaged public var uploaded: Bool
    @NSManaged public var progress: Double
    @NSManaged public var blah: Bool

}
