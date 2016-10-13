//
//  ManagedObject.swift
//  Moody
//
//  Created by Florian on 29/05/15.
//  Copyright (c) 2015 objc.io. All rights reserved.
//

import CoreData

open class ManagedObject: NSManagedObject {
}


public protocol ManagedObjectType: class {
    static var entityName: String { get }
    static var defaultSortDescriptors: [NSSortDescriptor] { get }
    static var defaultPredicate: NSPredicate { get }
    var managedObjectContext: NSManagedObjectContext? { get }
}


public protocol DefaultManagedObjectType: ManagedObjectType {}

extension DefaultManagedObjectType {
    public static var defaultPredicate: NSPredicate { return NSPredicate(value: true) }
}

extension ManagedObjectType where Self: ManagedObject {

    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return []
    }

    public static var sortedFetchRequest: NSFetchRequest<Self> {
        let request = NSFetchRequest<Self>(entityName: entityName)
        request.sortDescriptors = defaultSortDescriptors
        request.predicate = defaultPredicate
        return request
    }

    public static func sortedFetchRequestWithPredicate(_ predicate: NSPredicate) -> NSFetchRequest<Self> {
        let request = sortedFetchRequest
        guard let existingPredicate = request.predicate else { fatalError("must have predicate") }
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [existingPredicate, predicate])
        return request
    }

    public static func sortedFetchRequestWithPredicateFormat(_ format: String, args: CVarArg...) -> NSFetchRequest<Self> {
        let predicate = withVaList(args) { NSPredicate(format: format, arguments: $0) }
        return sortedFetchRequestWithPredicate(predicate)
    }

    public static func predicateWithFormat(_ format: String, args: CVarArg...) -> NSPredicate {
        let predicate = withVaList(args) { NSPredicate(format: format, arguments: $0) }
        return predicateWithPredicate(predicate)
    }

    public static func predicateWithPredicate(_ predicate: NSPredicate) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [defaultPredicate, predicate])
    }

}


extension ManagedObjectType where Self: ManagedObject {

    public static func findOrCreateInContext(_ moc: NSManagedObjectContext, matchingPredicate predicate: NSPredicate, configure: (Self) -> ()) -> Self {
        guard let obj = findOrFetchInContext(moc, matchingPredicate: predicate) else {
            let newObject: Self = moc.insertObject()
            configure(newObject)
            return newObject
        }
        return obj
    }

    public static func findOrFetchInContext(_ moc: NSManagedObjectContext, matchingPredicate predicate: NSPredicate) -> Self? {
        guard let obj = materializedObjectInContext(moc, matchingPredicate: predicate) else {
            return fetchInContext(moc) { request in
                request.predicate = predicate
                request.returnsObjectsAsFaults = false
                request.fetchLimit = 1
                }.first
        }
        return obj
    }

    public static func fetchInContext(_ context: NSManagedObjectContext, configurationBlock: (NSFetchRequest<Self>) -> () = { _ in }) -> [Self] {
        let request = NSFetchRequest<Self>(entityName: Self.entityName)
        configurationBlock(request)
        return try! context.fetch(request)
    }

    public static func countInContext(_ context: NSManagedObjectContext, configurationBlock: (NSFetchRequest<Self>) -> () = { _ in }) -> Int {
        let request = NSFetchRequest<Self>(entityName: entityName)
        configurationBlock(request)
        let result = try! context.count(for: request)
        return result
    }

    public static func materializedObjectInContext(_ moc: NSManagedObjectContext, matchingPredicate predicate: NSPredicate) -> Self? {
        for obj in moc.registeredObjects where !obj.isFault {
            guard let res = obj as? Self , predicate.evaluate(with: res) else { continue }
            return res
        }
        return nil
    }

}


extension ManagedObjectType where Self: ManagedObject {
    public static func fetchSingleObjectInContext(_ moc: NSManagedObjectContext, cacheKey: String, configure: (NSFetchRequest<Self>) -> ()) -> Self? {
        guard let cached = moc.objectForSingleObjectCacheKey(cacheKey) as? Self else {
            let result = fetchSingleObjectInContext(moc, configure: configure)
            moc.setObject(result, forSingleObjectCacheKey: cacheKey)
            return result
        }
        return cached
    }

    fileprivate static func fetchSingleObjectInContext(_ moc: NSManagedObjectContext, configure: (NSFetchRequest<Self>) -> ()) -> Self? {
        let result = fetchInContext(moc) { request in
            configure(request)
            request.fetchLimit = 2
        }
        switch result.count {
        case 0: return nil
        case 1: return result[0]
        default: fatalError("Returned multiple objects, expected max 1")
        }
    }
}

