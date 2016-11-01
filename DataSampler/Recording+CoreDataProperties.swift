//
//  Recording+CoreDataProperties.swift
//  DataSampler
//
//  Created by Brad Howes on 10/12/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
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
    @NSManaged public var endTime: TimeInterval
    @NSManaged public var size: Int64
    @NSManaged public var startTime: TimeInterval
    @NSManaged public var uploaded: Bool
    @NSManaged public var progress: Double
    @NSManaged public var uploading: Bool

}
