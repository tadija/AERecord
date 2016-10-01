//
//  AEQuery.swift
//  AERecord
//
//  Created by Marko Tadić on 10/1/16.
//  Copyright © 2016 AE. All rights reserved.
//

import CoreData

// MARK: - NSManagedObject Extension

/**
 This extension is all about **easy querying**.
 
 All queries are called as class functions on `NSManagedObject` (or it's custom subclass), and `defaultContext` is used if you don't specify any.
 */
public extension NSManagedObject {
    
    // MARK: General
    
    /**
     This property **must return correct entity name** because it's used all across other helpers to reference custom `NSManagedObject` subclass.
     
     You may override this property in your custom `NSManagedObject` subclass if needed (but it should work out of the box generally).
     */
    class var entityName: String {
        var name = NSStringFromClass(self)
        name = name.components(separatedBy: ".").last!
        return name
    }
    
    
    /// This parameter were renamed to `entityDescription` because it collided with iOS 10 SDK under Objective-C.
    @objc(nonobjc)
    @available(*, unavailable, renamed: "entityDescription")
    class var entity: NSEntityDescription? {
        return NSEntityDescription.entity(forEntityName: entityName, in: AERecord.defaultContext)
    }
    
    /// An `NSEntityDescription` object describes an entity in Core Data.
    class var entityDescription: NSEntityDescription? {
        return NSEntityDescription.entity(forEntityName: entityName, in: AERecord.defaultContext)
    }
    
    
    /**
     Creates fetch request **(for any entity type)** for given predicate and sort descriptors *(which are optional)*.
     
     :param: predicate Predicate for fetch request.
     :param sortDescriptors Sort Descriptors for fetch request.
     
     :returns: The created fetch request.
     */
    class func createFetchRequest<T: NSManagedObject>(predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) -> NSFetchRequest<T> {
        let request = NSFetchRequest<T>(entityName: entityName)
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        return request
    }
    
    private static let defaultPredicateType: NSCompoundPredicate.LogicalType = .and
    
    /**
     Creates predicate for given attributes and predicate type.
     
     :param: attributes Dictionary of attribute names and values.
     :param: predicateType If not specified, `.AndPredicateType` will be used.
     
     :returns: The created predicate.
     */
    class func createPredicateForAttributes(_ attributes: [AnyHashable : Any], predicateType: NSCompoundPredicate.LogicalType = defaultPredicateType) -> NSPredicate {
        var predicates = [NSPredicate]()
        for (attribute, value) in attributes {
            predicates.append(NSPredicate(format: "%K = %@", argumentArray: [attribute, value]))
        }
        let compoundPredicate = NSCompoundPredicate(type: predicateType, subpredicates: predicates)
        return compoundPredicate
    }
    
    // MARK: Creating
    
    /**
     Creates new instance of entity object.
     
     :param: context If not specified, `defaultContext` will be used.
     
     :returns: New instance of `Self`.
     */
    class func create(context: NSManagedObjectContext = AERecord.defaultContext) -> Self {
        let entityDescription = NSEntityDescription.entity(forEntityName: entityName, in: context)
        
        let object = self.init(entity: entityDescription!, insertInto: context)
        return object
    }
    
    /**
     Creates new instance of entity object and set it with given attributes.
     
     :param: attributes Dictionary of attribute names and values.
     :param: context If not specified, `defaultContext` will be used.
     
     :returns: New instance of `Self` with set attributes.
     */
    class func createWithAttributes(_ attributes: [String : Any], context: NSManagedObjectContext = AERecord.defaultContext) -> Self {
        let object = create(context: context)
        if attributes.count > 0 {
            object.setValuesForKeys(attributes)
        }
        return object
    }
    
    // MARK: Find First or Create
    
    /**
     Finds the first record for given attribute and value or creates new if the it does not exist.
     
     :param: attribute Attribute name.
     :param: value Attribute value.
     :param: context If not specified, `defaultContext` will be used.
     
     :returns: Instance of managed object.
     */
    class func firstOrCreateWithAttribute(_ attribute: String, value: Any, context: NSManagedObjectContext = AERecord.defaultContext) -> Self {
        return _firstOrCreateWithAttribute(attribute, value: value, context: context)
    }
    
    /**
     Finds the first record for given attribute and value or creates new if the it does not exist. Generic version.
     
     :param: attribute Attribute name.
     :param: value Attribute value.
     :param: context If not specified, `defaultContext` will be used.
     
     :returns: Instance of `Self`.
     */
    private class func _firstOrCreateWithAttribute<T>(_ attribute: String, value: Any, context: NSManagedObjectContext = AERecord.defaultContext) -> T {
        let object = firstOrCreateWithAttributes([attribute : value], context: context)
        
        return object as! T
    }
    
    /**
     Finds the first record for given attributes or creates new if the it does not exist.
     
     :param: attributes Dictionary of attribute names and values.
     :param: predicateType If not specified, `.AndPredicateType` will be used.
     :param: context If not specified, `defaultContext` will be used.
     
     :returns: Instance of managed object.
     */
    class func firstOrCreateWithAttributes(_ attributes: [String : Any], predicateType: NSCompoundPredicate.LogicalType = defaultPredicateType, context: NSManagedObjectContext = AERecord.defaultContext) -> Self {
        return _firstOrCreateWithAttributes(attributes, predicateType: predicateType, context: context)
    }
    
    /**
     Finds the first record for given attributes or creates new if the it does not exist. Generic version.
     
     :param: attributes Dictionary of attribute names and values.
     :param: predicateType If not specified, `.AndPredicateType` will be used.
     :param: context If not specified, `defaultContext` will be used.
     
     :returns: Instance of `Self`.
     */
    private class func _firstOrCreateWithAttributes<T>(_ attributes: [String : Any], predicateType: NSCompoundPredicate.LogicalType = defaultPredicateType, context: NSManagedObjectContext = AERecord.defaultContext) -> T {
        let predicate = createPredicateForAttributes(attributes, predicateType: predicateType)
        let request = createFetchRequest(predicate: predicate)
        request.fetchLimit = 1
        let objects = AERecord.executeFetchRequest(request, context: context)
        
        return (objects.first ?? createWithAttributes(attributes, context: context)) as! T
    }
    
    // MARK: Find First
    
    /**
     Finds the first record.
     
     :param: sortDescriptors Sort descriptors.
     :param: context If not specified, `defaultContext` will be used.
     
     :returns: Optional managed object.
     */
    class func first(sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> Self? {
        return _first(sortDescriptors: sortDescriptors, context: context)
    }
    
    /**
     Finds the first record. Generic version.
     
     :param: sortDescriptors Sort descriptors.
     :param: context If not specified, `defaultContext` will be used.
     
     :returns: Optional instance of `Self`.
     */
    private class func _first<T>(sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> T? {
        let request = createFetchRequest(sortDescriptors: sortDescriptors)
        request.fetchLimit = 1
        let objects = AERecord.executeFetchRequest(request, context: context)
        
        return objects.first as? T
    }
    
    /**
     Finds the first record for given predicate.
     
     :param: predicate Predicate.
     :param: sortDescriptors Sort descriptors.
     :param: context If not specified, `defaultContext` will be used.
     
     :returns: Optional managed object.
     */
    class func firstWithPredicate(_ predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> Self? {
        return _firstWithPredicate(predicate, sortDescriptors: sortDescriptors, context: context)
    }
    
    /**
     Finds the first record for given predicate. Generic version
     
     :param: predicate Predicate.
     :param: sortDescriptors Sort descriptors.
     :param: context If not specified, `defaultContext` will be used.
     
     :returns: Optional instance of `Self`.
     */
    private class func _firstWithPredicate<T>(_ predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> T? {
        let request = createFetchRequest(predicate: predicate, sortDescriptors: sortDescriptors)
        request.fetchLimit = 1
        let objects = AERecord.executeFetchRequest(request, context: context)
        
        return objects.first as? T
    }
    
    /**
     Finds the first record for given attribute and value.
     
     :param: attribute Attribute name.
     :param: value Attribute value.
     :param: sortDescriptors Sort descriptors.
     :param: context If not specified, `defaultContext` will be used.
     
     :returns: Optional managed object.
     */
    class func firstWithAttribute(_ attribute: String, value: Any, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> Self? {
        let predicate = NSPredicate(format: "%K = %@", argumentArray: [attribute, value])
        return firstWithPredicate(predicate, sortDescriptors: sortDescriptors, context: context)
    }
    
    /**
     Finds the first record for given attributes.
     
     :param: attributes Dictionary of attribute names and values.
     :param: predicateType If not specified, `.AndPredicateType` will be used.
     :param: sortDescriptors Sort descriptors.
     :param: context If not specified, `defaultContext` will be used.
     
     :returns: Optional managed object.
     */
    class func firstWithAttributes(_ attributes: [AnyHashable : Any], predicateType: NSCompoundPredicate.LogicalType = defaultPredicateType, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> Self? {
        let predicate = createPredicateForAttributes(attributes, predicateType: predicateType)
        return firstWithPredicate(predicate, sortDescriptors: sortDescriptors, context: context)
    }
    
    /**
     Finds the first record ordered by given attribute.
     
     :param: name Attribute name.
     :param: ascending A Boolean value.
     :param: context If not specified, `defaultContext` will be used.
     
     :returns: Optional managed object.
     */
    class func firstOrderedByAttribute(_ name: String, ascending: Bool = true, context: NSManagedObjectContext = AERecord.defaultContext) -> Self? {
        let sortDescriptors = [NSSortDescriptor(key: name, ascending: ascending)]
        return first(sortDescriptors: sortDescriptors, context: context)
    }
    
    // MARK: Find All
    
    /**
     Finds all records.
     
     :param: sortDescriptors Sort descriptors.
     :param: context If not specified, `defaultContext` will be used.
     
     :returns: Optional managed object.
     */
    class func all(_ sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> [NSManagedObject]? {
        let request = createFetchRequest(sortDescriptors: sortDescriptors)
        let objects = AERecord.executeFetchRequest(request, context: context)
        return objects.count > 0 ? objects : nil
    }
    
    /**
     Finds all records. Generic version.
     
     :param: sortDescriptors Sort descriptors.
     :param: context If not specified, `defaultContext` will be used.
     
     :returns: Optional array of `Self` instances.
     */
    class func all<T>(_ sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> [T]? {
        let objects = all(sortDescriptors, context: context)
        return objects?.map { $0 as! T }
    }
    
    /**
     Finds all records for given predicate.
     
     :param: predicate Predicate.
     :param: sortDescriptors Sort descriptors.
     :param: context If not specified, `defaultContext` will be used.
     
     :returns: Optional managed object.
     */
    class func allWithPredicate(_ predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> [NSManagedObject]? {
        let request = createFetchRequest(predicate: predicate, sortDescriptors: sortDescriptors)
        let objects = AERecord.executeFetchRequest(request, context: context)
        return objects.count > 0 ? objects : nil
    }
    
    /**
     Finds all records for given predicate. Generic version
     
     :param: predicate Predicate.
     :param: sortDescriptors Sort descriptors.
     :param: context If not specified, `defaultContext` will be used.
     
     :returns: Optional array of `Self` instances.
     */
    class func allWithPredicate<T>(_ predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> [T]? {
        let objects = allWithPredicate(predicate, sortDescriptors: sortDescriptors, context: context)
        return objects?.map { $0 as! T }
    }
    
    /**
     Finds all records for given attribute and value.
     
     :param: attribute Attribute name.
     :param: value Attribute value.
     :param: sortDescriptors Sort descriptors.
     :param: context If not specified, `defaultContext` will be used.
     
     :returns: Optional managed object.
     */
    class func allWithAttribute(_ attribute: String, value: Any, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> [NSManagedObject]? {
        let predicate = NSPredicate(format: "%K = %@", argumentArray: [attribute, value])
        return allWithPredicate(predicate, sortDescriptors: sortDescriptors, context: context)
    }
    
    /**
     Finds all records for given attribute and value. Generic version
     
     :param: attribute Attribute name.
     :param: value Attribute value.
     :param: sortDescriptors Sort descriptors.
     :param: context If not specified, `defaultContext` will be used.
     
     :returns: Optional array of `Self` instances.
     */
    class func allWithAttribute<T>(_ attribute: String, value: Any, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> [T]? {
        let objects = allWithAttribute(attribute, value: value, sortDescriptors: sortDescriptors, context: context)
        return objects?.map { $0 as! T }
    }
    
    /**
     Finds all records for given attributes.
     
     :param: attributes Dictionary of attribute names and values.
     :param: predicateType If not specified, `.AndPredicateType` will be used.
     :param: sortDescriptors Sort descriptors.
     :param: context If not specified, `defaultContext` will be used.
     
     :returns: Optional managed object.
     */
    class func allWithAttributes(_ attributes: [AnyHashable : Any], predicateType: NSCompoundPredicate.LogicalType = defaultPredicateType, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> [NSManagedObject]? {
        let predicate = createPredicateForAttributes(attributes, predicateType: predicateType)
        return allWithPredicate(predicate, sortDescriptors: sortDescriptors, context: context)
    }
    
    /**
     Finds all records for given attributes. Generic version.
     
     :param: attributes Dictionary of attribute names and values.
     :param: predicateType If not specified, `.AndPredicateType` will be used.
     :param: sortDescriptors Sort descriptors.
     :param: context If not specified, `defaultContext` will be used.
     
     :returns: Optional array of `Self` instances.
     */
    class func allWithAttributes<T>(_ attributes: [AnyHashable : Any], predicateType: NSCompoundPredicate.LogicalType = defaultPredicateType, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> [T]? {
        let objects = allWithAttributes(attributes, predicateType: predicateType, sortDescriptors: sortDescriptors, context: context)
        return objects?.map { $0 as! T }
    }
    
    // MARK: Delete
    
    /**
     Deletes instance of entity object.
     
     :param: context If not specified, `defaultContext` will be used.
     */
    func deleteFromContext(_ context: NSManagedObjectContext = AERecord.defaultContext) {
        context.delete(self)
    }
    
    /**
     Deletes all records.
     
     :param: context If not specified, `defaultContext` will be used.
     */
    class func deleteAll(context: NSManagedObjectContext = AERecord.defaultContext) {
        if let objects = self.all(context: context) {
            for object in objects {
                context.delete(object)
            }
        }
    }
    
    /**
     Deletes all records for given predicate.
     
     :param: predicate Predicate.
     :param: context If not specified, `defaultContext` will be used.
     */
    class func deleteAllWithPredicate(_ predicate: NSPredicate, context: NSManagedObjectContext = AERecord.defaultContext) {
        if let objects = self.allWithPredicate(predicate, context: context) {
            for object in objects {
                context.delete(object)
            }
        }
    }
    
    /**
     Deletes all records for given attribute name and value.
     
     :param: attribute Attribute name.
     :param: value Attribute value.
     :param: context If not specified, `defaultContext` will be used.
     */
    class func deleteAllWithAttribute(_ attribute: String, value: Any, context: NSManagedObjectContext = AERecord.defaultContext) {
        if let objects = self.allWithAttribute(attribute, value: value, context: context) {
            for object in objects {
                context.delete(object)
            }
        }
    }
    
    /**
     Deletes all records for given attributes.
     
     :param: attributes Dictionary of attribute names and values.
     :param: predicateType If not specified, `.AndPredicateType` will be used.
     :param: context If not specified, `defaultContext` will be used.
     */
    class func deleteAllWithAttributes(_ attributes: [AnyHashable : Any], predicateType: NSCompoundPredicate.LogicalType = defaultPredicateType, context: NSManagedObjectContext = AERecord.defaultContext) {
        if let objects = self.allWithAttributes(attributes, predicateType: predicateType, context: context) {
            for object in objects {
                context.delete(object)
            }
        }
    }
    
    // MARK: Count
    
    /**
     Counts all records.
     
     :param: context If not specified, `defaultContext` will be used.
     
     :returns: Count of records.
     */
    class func count(_ context: NSManagedObjectContext = AERecord.defaultContext) -> Int {
        return countWithPredicate(context: context)
    }
    
    /**
     Counts all records for given predicate.
     
     :param: predicate Predicate.
     :param: context If not specified, `defaultContext` will be used.
     
     :returns: Count of records.
     */
    class func countWithPredicate(_ predicate: NSPredicate? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> Int {
        let request = createFetchRequest(predicate: predicate)
        request.includesSubentities = false
        
        var count = 0
        
        do {
            count = try context.count(for: request)
        } catch {
            print(error)
        }
        
        return count
    }
    
    /**
     Counts all records for given attribute name and value.
     
     :param: attribute Attribute name.
     :param: value Attribute value.
     :param: context If not specified, `defaultContext` will be used.
     
     :returns: Count of records.
     */
    class func countWithAttribute(_ attribute: String, value: Any, context: NSManagedObjectContext = AERecord.defaultContext) -> Int {
        return countWithAttributes([attribute : value], context: context)
    }
    
    /**
     Counts all records for given attributes.
     
     :param: attributes Dictionary of attribute names and values.
     :param: predicateType If not specified, `.AndPredicateType` will be used.
     :param: context If not specified, `defaultContext` will be used.
     
     :returns: Count of records.
     */
    class func countWithAttributes(_ attributes: [AnyHashable : Any], predicateType: NSCompoundPredicate.LogicalType = defaultPredicateType, context: NSManagedObjectContext = AERecord.defaultContext) -> Int {
        let predicate = createPredicateForAttributes(attributes, predicateType: predicateType)
        return countWithPredicate(predicate, context: context)
    }
    
    // MARK: Distinct
    
    /**
     Gets distinct values for given attribute and predicate.
     
     :param: attribute Attribute name.
     :param: predicate Predicate.
     :param: sortDescriptors Sort descriptors.
     :param: context If not specified, `defaultContext` will be used.
     
     :returns: Throws optional Array of `Any`.
     */
    class func distinctValuesForAttribute(_ attribute: String, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) throws -> [Any]? {
        var distinctValues = [Any]()
        
        if let distinctRecords = try distinctRecordsForAttributes([attribute], predicate: predicate, sortDescriptors: sortDescriptors, context: context) {
            for record in distinctRecords {
                if let value = record[attribute] {
                    distinctValues.append(value)
                }
            }
        }
        
        return distinctValues.count > 0 ? distinctValues : nil
    }
    
    /**
     Gets distinct values for given attributes and predicate.
     
     :param: attributes Dictionary of attribute names and values.
     :param: predicate Predicate.
     :param: sortDescriptors Sort descriptors.
     :param: context If not specified, `defaultContext` will be used.
     
     :returns: Throws optional Array of `Any`.
     */
    class func distinctRecordsForAttributes(_ attributes: [AnyHashable], predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) throws -> [NSDictionary]? {
        let request = NSFetchRequest<NSDictionary>(entityName: entityName)
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        request.resultType = .dictionaryResultType
        request.propertiesToFetch = attributes
        request.returnsDistinctResults = true
        
        let distinctRecords = try? context.fetch(request)
        
        return distinctRecords
    }
    
    // MARK: Auto Increment
    
    /**
     Gets next ID for given attribute name. Attribute must be of `Int` type.
     
     :param: attribute Attribute name.
     :param: context If not specified, `defaultContext` will be used.
     
     :returns: Auto incremented ID.
     */
    class func autoIncrementedIntegerAttribute(_ attribute: String, context: NSManagedObjectContext = AERecord.defaultContext) -> Int {
        let sortDescriptor = NSSortDescriptor(key: attribute, ascending: false)
        if let object = self.first(sortDescriptors: [sortDescriptor], context: context) {
            if let max = object.value(forKey: attribute) as? Int {
                return max + 1
            } else {
                return 0
            }
        } else {
            return 0
        }
    }
    
    // MARK: Turn Object Into Fault
    
    /**
     Turns object into fault.
     
     :param: mergeChanges A Boolean value.
     :param: context If not specified, `defaultContext` will be used.
     */
    func refresh(_ mergeChanges: Bool = true, context: NSManagedObjectContext = AERecord.defaultContext) {
        AERecord.refreshObjects(objectIDS: [objectID], mergeChanges: mergeChanges, context: context)
    }
    
    // MARK: Batch Update
    
    /**
     Updates data directly in persistent store **(iOS 8 and above)**.
     
     :param: predicate Predicate.
     :param: properties Properties to update.
     :param: resultType If not specified, `StatusOnlyResultType` will be used.
     :param: context If not specified, `defaultContext` will be used.
     
     :returns: Batch update result.
     */
    class func batchUpdate(predicate: NSPredicate? = nil, properties: [AnyHashable : Any]? = nil, resultType: NSBatchUpdateRequestResultType = .statusOnlyResultType, context: NSManagedObjectContext = AERecord.defaultContext) -> NSBatchUpdateResult? {
        let request = NSBatchUpdateRequest(entityName: entityName)
        request.predicate = predicate
        request.propertiesToUpdate = properties
        request.resultType = resultType
        
        var batchResult: NSBatchUpdateResult? = nil
        
        context.performAndWait {
            do {
                if let result = try context.execute(request) as? NSBatchUpdateResult {
                    batchResult = result
                }
            } catch {
                print(error)
            }
        }
        
        return batchResult
    }
    
    /**
     Updates data directly in persistent store **(iOS 8 and above)**.
     
     :param: predicate Predicate.
     :param: properties Properties to update.
     :param: context If not specified, `defaultContext` will be used.
     
     :returns: Count of updated objects.
     */
    class func objectsCountForBatchUpdate(_ predicate: NSPredicate? = nil, properties: [AnyHashable : Any]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> Int {
        if let result = batchUpdate(predicate: predicate, properties: properties, resultType: .updatedObjectsCountResultType, context: context) {
            if let count = result.result as? Int {
                return count
            } else {
                return 0
            }
        } else {
            return 0
        }
    }
    
    /**
     Updates data directly in persistent store **(iOS 8 and above)**.
     
     Objects are turned into faults after updating *(managed object context is refreshed)*.
     
     :param: predicate Predicate.
     :param: properties Properties to update.
     :param: context If not specified, `defaultContext` will be used.
     */
    class func batchUpdateAndRefreshObjects(_ predicate: NSPredicate? = nil, properties: [AnyHashable : Any]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) {
        if let result = batchUpdate(predicate: predicate, properties: properties, resultType: .updatedObjectIDsResultType, context: context) {
            if let objectIDS = result.result as? [NSManagedObjectID] {
                AERecord.refreshObjects(objectIDS: objectIDS, mergeChanges: true, context: context)
            }
        }
    }
    
}
