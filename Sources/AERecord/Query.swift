/**
 *  https://github.com/tadija/AERecord
 *  Copyright (c) Marko Tadić 2014-2018
 *  Licensed under the MIT license. See LICENSE file.
 */

import CoreData

/**
    This extension of `NSManagedObject` is all about easy querying.
 
    All queries are called as class functions on any object that is kind of `NSManagedObject`,
    and `AERecord.Context.default` is used if you don't specify any custom.
*/
public extension NSManagedObject {
    
    // MARK: - General
    
    /**
        This property must return correct entity name because it's used all across other helpers 
        to reference custom `NSManagedObject` subclass.
     
        You may override this property in your custom `NSManagedObject` subclass if needed, 
        but it should work 'out of the box' generally.
    */
    class var entityName: String {
        var name = NSStringFromClass(self)
        name = name.components(separatedBy: ".").last!
        return name
    }
    
    /// An `NSEntityDescription` object which describes an entity in Core Data.
    class var entityDescription: NSEntityDescription? {
        return NSEntityDescription.entity(forEntityName: entityName, in: AERecord.Context.default)
    }
    
    /**
        Creates fetch request for any entity type with given predicate (optional) and sort descriptors (optional).

        - parameter predicate: Predicate for fetch request.
        - parameter sortDescriptors: Sort Descriptors for fetch request.

        - returns: The created fetch request.
    */
    class func createFetchRequest<T: NSManagedObject>(predicate: NSPredicate? = nil,
                                  sortDescriptors: [NSSortDescriptor]? = nil) -> NSFetchRequest<T> {
        
        let request = NSFetchRequest<T>(entityName: entityName)
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        return request
    }
    
    public static let defaultPredicateType: NSCompoundPredicate.LogicalType = .and
    
    /**
        Creates predicate for given attributes and predicate type.

        - parameter attributes: Dictionary of attribute names and values.
        - parameter predicateType: If not specified, `.and` will be used.

        - returns: The created predicate.
    */
    class func createPredicate(with attributes: [AnyHashable : Any],
                               predicateType: NSCompoundPredicate.LogicalType = defaultPredicateType) -> NSPredicate {
        
        var predicates = [NSPredicate]()
        for (attribute, value) in attributes {
            predicates.append(NSPredicate(format: "%K = %@", argumentArray: [attribute, value]))
        }
        let compoundPredicate = NSCompoundPredicate(type: predicateType, subpredicates: predicates)
        return compoundPredicate
    }
    
    // MARK: - Create
    
    /**
        Creates new instance of entity object.

        - parameter context: If not specified, `AERecord.Context.default` will be used.

        - returns: New instance of `Self`.
    */
    @discardableResult class func create(in context: NSManagedObjectContext = AERecord.Context.default) -> Self {
        let entityDescription = NSEntityDescription.entity(forEntityName: entityName, in: context)!
        let object = self.init(entity: entityDescription, insertInto: context)
        return object
    }
    
    /**
        Creates new instance of entity object and configures it with given attributes.

        - parameter attributes: Dictionary of attribute names and values.
        - parameter context: If not specified, `AERecord.Context.default` will be used.

        - returns: New instance of `Self` with set attributes.
    */
    @discardableResult class func create(with attributes: [String : Any],
                                         in context: NSManagedObjectContext = AERecord.Context.default) -> Self {
        
        let object = create(in: context)
        if attributes.count > 0 {
            object.setValuesForKeys(attributes)
        }
        return object
    }
    
    // MARK: - Find First or Create
    
    /**
        Finds the first record for given attribute and value or creates new if it does not exist.

        - parameter attribute: Attribute name.
        - parameter value: Attribute value.
        - parameter context: If not specified, `AERecord.Context.default` will be used.

        - returns: Instance of managed object.
    */
    class func firstOrCreate(with attribute: String, value: Any,
                             in context: NSManagedObjectContext = AERecord.Context.default) -> Self {
        
        return _firstOrCreate(with: attribute, value: value, in: context)
    }
    
    /**
        Finds the first record for given attribute and value or creates new if it does not exist. Generic version.

        - parameter attribute: Attribute name.
        - parameter value: Attribute value.
        - parameter context: If not specified, `AERecord.Context.default` will be used.

        - returns: Instance of `Self`.
    */
    private class func _firstOrCreate<T>(with attribute: String, value: Any,
                                                   in context: NSManagedObjectContext = AERecord.Context.default) -> T {
        
        let object = firstOrCreate(with: [attribute : value], in: context)
        return object as! T
    }
    
    /**
        Finds the first record for given attributes or creates new if it does not exist.

        - parameter attributes: Dictionary of attribute names and values.
        - parameter predicateType: If not specified, `.AndPredicateType` will be used.
        - parameter context: If not specified, `AERecord.Context.default` will be used.

        - returns: Instance of managed object.
    */
    class func firstOrCreate(with attributes: [String : Any],
                             predicateType: NSCompoundPredicate.LogicalType = defaultPredicateType,
                             in context: NSManagedObjectContext = AERecord.Context.default) -> Self {
        
        return _firstOrCreate(with: attributes, predicateType: predicateType, in: context)
    }
    
    /**
        Finds the first record for given attributes or creates new if it does not exist. Generic version.

        - parameter attributes: Dictionary of attribute names and values.
        - parameter predicateType: If not specified, `.AndPredicateType` will be used.
        - parameter context: If not specified, `AERecord.Context.default` will be used.

        - returns: Instance of `Self`.
    */
    private class func _firstOrCreate<T>(with attributes: [String : Any],
                                      predicateType: NSCompoundPredicate.LogicalType = defaultPredicateType,
                                      in context: NSManagedObjectContext = AERecord.Context.default) -> T {
        
        let predicate = createPredicate(with: attributes, predicateType: predicateType)
        let request = createFetchRequest(predicate: predicate)
        request.fetchLimit = 1
        
        let objects = AERecord.execute(fetchRequest: request, in: context)
        return (objects.first ?? create(with: attributes, in: context)) as! T
    }
    
    // MARK: - Find First
    
    /**
        Finds the first record ordered by given attribute.

        - parameter attribute: Attribute name.
        - parameter ascending: A Boolean value.
        - parameter context: If not specified, `AERecord.Context.default` will be used.

        - returns: Optional managed object.
    */
    class func first(orderedBy attribute: String, ascending: Bool = true,
                     in context: NSManagedObjectContext = AERecord.Context.default) -> Self? {
        
        let sortDescriptors = [NSSortDescriptor(key: attribute, ascending: ascending)]
        return first(orderedBy: sortDescriptors, in: context)
    }
    
    /**
        Finds the first record.

        - parameter sortDescriptors: Sort descriptors.
        - parameter context: If not specified, `AERecord.Context.default` will be used.

        - returns: Optional managed object.
    */
    class func first(orderedBy sortDescriptors: [NSSortDescriptor]? = nil,
                     in context: NSManagedObjectContext = AERecord.Context.default) -> Self? {
        
        return _first(orderedBy: sortDescriptors, in: context)
    }
    
    /**
        Finds the first record. Generic version.

        - parameter sortDescriptors: Sort descriptors.
        - parameter context: If not specified, `AERecord.Context.default` will be used.

        - returns: Optional instance of `Self`.
    */
    private class func _first<T>(orderedBy sortDescriptors: [NSSortDescriptor]? = nil,
                              in context: NSManagedObjectContext = AERecord.Context.default) -> T? {
        
        let request = createFetchRequest(sortDescriptors: sortDescriptors)
        request.fetchLimit = 1
        
        let objects = AERecord.execute(fetchRequest: request, in: context)
        return objects.first as? T
    }
    
    /**
        Finds the first record for given predicate.

        - parameter predicate: Predicate.
        - parameter sortDescriptors: Sort descriptors.
        - parameter context: If not specified, `AERecord.Context.default` will be used.

        - returns: Optional managed object.
    */
    class func first(with predicate: NSPredicate, orderedBy sortDescriptors: [NSSortDescriptor]? = nil,
                     in context: NSManagedObjectContext = AERecord.Context.default) -> Self? {
        
        return _first(with: predicate, orderedBy: sortDescriptors, in: context)
    }
    
    /**
        Finds the first record for given predicate. Generic version

        - parameter predicate: Predicate.
        - parameter sortDescriptors: Sort descriptors.
        - parameter context: If not specified, `AERecord.Context.default` will be used.

        - returns: Optional instance of `Self`.
    */
    private class func _first<T>(with predicate: NSPredicate, orderedBy sortDescriptors: [NSSortDescriptor]? = nil,
                              in context: NSManagedObjectContext = AERecord.Context.default) -> T? {
        
        let request = createFetchRequest(predicate: predicate, sortDescriptors: sortDescriptors)
        request.fetchLimit = 1
        
        let objects = AERecord.execute(fetchRequest: request, in: context)
        return objects.first as? T
    }
    
    /**
        Finds the first record for given attribute and value.

        - parameter attribute: Attribute name.
        - parameter value: Attribute value.
        - parameter sortDescriptors: Sort descriptors.
        - parameter context: If not specified, `AERecord.Context.default` will be used.

        - returns: Optional managed object.
    */
    class func first(with attribute: String, value: Any, orderedBy sortDescriptors: [NSSortDescriptor]? = nil,
                     in context: NSManagedObjectContext = AERecord.Context.default) -> Self? {
        
        let predicate = NSPredicate(format: "%K = %@", argumentArray: [attribute, value])
        return first(with: predicate, orderedBy: sortDescriptors, in: context)
    }
    
    /**
        Finds the first record for given attributes.

        - parameter attributes: Dictionary of attribute names and values.
        - parameter predicateType: If not specified, `.AndPredicateType` will be used.
        - parameter sortDescriptors: Sort descriptors.
        - parameter context: If not specified, `AERecord.Context.default` will be used.

        - returns: Optional managed object.
    */
    class func first(with attributes: [AnyHashable : Any],
                     predicateType: NSCompoundPredicate.LogicalType = defaultPredicateType,
                     orderedBy sortDescriptors: [NSSortDescriptor]? = nil,
                     in context: NSManagedObjectContext = AERecord.Context.default) -> Self? {
        
        let predicate = createPredicate(with: attributes, predicateType: predicateType)
        return first(with: predicate, orderedBy: sortDescriptors, in: context)
    }
    
    // MARK: - Find All
    
    /**
        Finds all records.

        - parameter sortDescriptors: Sort descriptors.
        - parameter context: If not specified, `AERecord.Context.default` will be used.

        - returns: Optional managed object.
    */
    class func all(orderedBy sortDescriptors: [NSSortDescriptor]? = nil,
                   in context: NSManagedObjectContext = AERecord.Context.default) -> [NSManagedObject]? {
        
        let request = createFetchRequest(sortDescriptors: sortDescriptors)
        let objects = AERecord.execute(fetchRequest: request, in: context)
        return objects.count > 0 ? objects : nil
    }
    
    /**
        Finds all records. Generic version.

        - parameter sortDescriptors: Sort descriptors.
        - parameter context: If not specified, `AERecord.Context.default` will be used.

        - returns: Optional array of `Self` instances.
    */
    class func all<T>(orderedBy sortDescriptors: [NSSortDescriptor]? = nil,
                   in context: NSManagedObjectContext = AERecord.Context.default) -> [T]? {
        
        let objects = all(orderedBy: sortDescriptors, in: context)
        return objects?.map { $0 as! T }
    }
    
    /**
        Finds all records for given predicate.

        - parameter predicate: Predicate.
        - parameter sortDescriptors: Sort descriptors.
        - parameter context: If not specified, `AERecord.Context.default` will be used.

        - returns: Optional managed object.
    */
    class func all(with predicate: NSPredicate, orderedBy sortDescriptors: [NSSortDescriptor]? = nil,
                   in context: NSManagedObjectContext = AERecord.Context.default) -> [NSManagedObject]? {
        
        let request = createFetchRequest(predicate: predicate, sortDescriptors: sortDescriptors)
        let objects = AERecord.execute(fetchRequest: request, in: context)
        return objects.count > 0 ? objects : nil
    }
    
    /**
        Finds all records for given predicate. Generic version

        - parameter predicate: Predicate.
        - parameter sortDescriptors: Sort descriptors.
        - parameter context: If not specified, `AERecord.Context.default` will be used.

        - returns: Optional array of `Self` instances.
    */
    class func all<T>(with predicate: NSPredicate, orderedBy sortDescriptors: [NSSortDescriptor]? = nil,
                   in context: NSManagedObjectContext = AERecord.Context.default) -> [T]? {
        
        let objects = all(with: predicate, orderedBy: sortDescriptors, in: context)
        return objects?.map { $0 as! T }
    }
    
    /**
        Finds all records for given attribute and value.

        - parameter attribute: Attribute name.
        - parameter value: Attribute value.
        - parameter sortDescriptors: Sort descriptors.
        - parameter context: If not specified, `AERecord.Context.default` will be used.

        - returns: Optional managed object.
    */
    class func all(with attribute: String, value: Any, orderedBy sortDescriptors: [NSSortDescriptor]? = nil,
                   in context: NSManagedObjectContext = AERecord.Context.default) -> [NSManagedObject]? {
        
        let predicate = NSPredicate(format: "%K = %@", argumentArray: [attribute, value])
        return all(with: predicate, orderedBy: sortDescriptors, in: context)
    }
    
    /**
        Finds all records for given attribute and value. Generic version

        - parameter attribute: Attribute name.
        - parameter value: Attribute value.
        - parameter sortDescriptors: Sort descriptors.
        - parameter context: If not specified, `AERecord.Context.default` will be used.

        - returns: Optional array of `Self` instances.
    */
    class func all<T>(with attribute: String, value: Any, orderedBy sortDescriptors: [NSSortDescriptor]? = nil,
                   in context: NSManagedObjectContext = AERecord.Context.default) -> [T]? {
        
        let objects = all(with: attribute, value: value, orderedBy: sortDescriptors, in: context)
        return objects?.map { $0 as! T }
    }
    
    /**
        Finds all records for given attributes.

        - parameter attributes: Dictionary of attribute names and values.
        - parameter predicateType: If not specified, `.AndPredicateType` will be used.
        - parameter sortDescriptors: Sort descriptors.
        - parameter context: If not specified, `AERecord.Context.default` will be used.

        - returns: Optional managed object.
    */
    class func all(with attributes: [AnyHashable : Any],
                   predicateType: NSCompoundPredicate.LogicalType = defaultPredicateType,
                   orderedBy sortDescriptors: [NSSortDescriptor]? = nil,
                   in context: NSManagedObjectContext = AERecord.Context.default) -> [NSManagedObject]? {
        
        let predicate = createPredicate(with: attributes, predicateType: predicateType)
        return all(with: predicate, orderedBy: sortDescriptors, in: context)
    }
    
    /**
        Finds all records for given attributes. Generic version.

        - parameter attributes: Dictionary of attribute names and values.
        - parameter predicateType: If not specified, `.AndPredicateType` will be used.
        - parameter sortDescriptors: Sort descriptors.
        - parameter context: If not specified, `AERecord.Context.default` will be used.

        - returns: Optional array of `Self` instances.
    */
    class func all<T>(with attributes: [AnyHashable : Any],
                   predicateType: NSCompoundPredicate.LogicalType = defaultPredicateType,
                   orderedBy sortDescriptors: [NSSortDescriptor]? = nil,
                   in context: NSManagedObjectContext = AERecord.Context.default) -> [T]? {
        
        let objects = all(with: attributes, predicateType: predicateType, orderedBy: sortDescriptors, in: context)
        return objects?.map { $0 as! T }
    }
    
    // MARK: - Delete
    
    /**
        Deletes instance of entity object.

        - parameter context: If not specified, `AERecord.Context.default` will be used.
    */
    func delete(from context: NSManagedObjectContext = AERecord.Context.default) {
        context.delete(self)
    }
    
    /**
        Deletes all records.

        - parameter context: If not specified, `AERecord.Context.default` will be used.
    */
    class func deleteAll(from context: NSManagedObjectContext = AERecord.Context.default) {
        if let objects = self.all(in: context) {
            for object in objects {
                context.delete(object)
            }
        }
    }
    
    /**
        Deletes all records for given predicate.

        - parameter predicate: Predicate.
        - parameter context: If not specified, `AERecord.Context.default` will be used.
    */
    class func deleteAll(with predicate: NSPredicate,
                         from context: NSManagedObjectContext = AERecord.Context.default) {
        
        if let objects = all(with: predicate, in: context) {
            for object in objects {
                context.delete(object)
            }
        }
    }
    
    /**
        Deletes all records for given attribute name and value.

        - parameter attribute: Attribute name.
        - parameter value: Attribute value.
        - parameter context: If not specified, `AERecord.Context.default` will be used.
    */
    class func deleteAll(with attribute: String, value: Any,
                         from context: NSManagedObjectContext = AERecord.Context.default) {
        
        if let objects = all(with: attribute, value: value, in: context) {
            for object in objects {
                context.delete(object)
            }
        }
    }
    
    /**
        Deletes all records for given attributes.

        - parameter attributes: Dictionary of attribute names and values.
        - parameter predicateType: If not specified, `.AndPredicateType` will be used.
        - parameter context: If not specified, `AERecord.Context.default` will be used.
    */
    class func deleteAll(with attributes: [AnyHashable : Any],
                         predicateType: NSCompoundPredicate.LogicalType = defaultPredicateType,
                         from context: NSManagedObjectContext = AERecord.Context.default) {
        
        if let objects = all(with: attributes, predicateType: predicateType, in: context) {
            for object in objects {
                context.delete(object)
            }
        }
    }
    
    // MARK: - Count
    
    /**
        Counts all records for given predicate.

        - parameter predicate: Predicate.
        - parameter context: If not specified, `AERecord.Context.default` will be used.

        - returns: Count of records.
    */
    class func count(with predicate: NSPredicate? = nil,
                     in context: NSManagedObjectContext = AERecord.Context.default) -> Int {
        
        let request = createFetchRequest(predicate: predicate)
        request.includesSubentities = false
        
        var count = 0
        
        do {
            count = try context.count(for: request)
        } catch {
            debugPrint(error)
        }
        
        return count
    }
    
    /**
        Counts all records for given attribute name and value.

        - parameter attribute: Attribute name.
        - parameter value: Attribute value.
        - parameter context: If not specified, `AERecord.Context.default` will be used.

        - returns: Count of records.
    */
    class func count(with attribute: String, value: Any,
                     in context: NSManagedObjectContext = AERecord.Context.default) -> Int {
        
        return count(with: [attribute : value], in: context)
    }
    
    /**
        Counts all records for given attributes.

        - parameter attributes: Dictionary of attribute names and values.
        - parameter predicateType: If not specified, `.AndPredicateType` will be used.
        - parameter context: If not specified, `AERecord.Context.default` will be used.

        - returns: Count of records.
    */
    class func count(with attributes: [AnyHashable : Any],
                     predicateType: NSCompoundPredicate.LogicalType = defaultPredicateType,
                     in context: NSManagedObjectContext = AERecord.Context.default) -> Int {
        
        let predicate = createPredicate(with: attributes, predicateType: predicateType)
        return count(with: predicate, in: context)
    }
    
    // MARK: - Distinct
    
    /**
        Gets distinct values for given attribute and predicate.

        - parameter attribute: Attribute name.
        - parameter predicate: Predicate.
        - parameter sortDescriptors: Sort descriptors.
        - parameter context: If not specified, `AERecord.Context.default` will be used.

        - returns: Throws optional Array of `Any`.
    */
    class func distinctValues(for attribute: String,
                              predicate: NSPredicate? = nil, orderedBy sortDescriptors: [NSSortDescriptor]? = nil,
                              in context: NSManagedObjectContext = AERecord.Context.default) throws -> [Any]? {
        
        var distinctValues = [Any]()
        
        if let distinctRecords = try distinctRecords(for: [attribute], predicate: predicate,
                                                     orderedBy: sortDescriptors, in: context)
        {
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

        - parameter attributes: Dictionary of attribute names and values.
        - parameter predicate: Predicate.
        - parameter sortDescriptors: Sort descriptors.
        - parameter context: If not specified, `AERecord.Context.default` will be used.

        - returns: Throws optional Array of `Any`.
    */
    class func distinctRecords(for attributes: [AnyHashable],
                               predicate: NSPredicate? = nil, orderedBy sortDescriptors: [NSSortDescriptor]? = nil,
                               in context: NSManagedObjectContext = AERecord.Context.default) throws -> [NSDictionary]? {
        
        let request = NSFetchRequest<NSDictionary>(entityName: entityName)
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        request.resultType = .dictionaryResultType
        request.propertiesToFetch = attributes
        request.returnsDistinctResults = true
        
        let distinctRecords = try? context.fetch(request)
        
        return distinctRecords
    }
    
    // MARK: - Other
    
    /**
        Gets next ID for given attribute name. Attribute must be of `Int` type.

        - parameter attribute: Attribute name.
        - parameter context: If not specified, `AERecord.Context.default` will be used.

        - returns: Auto incremented ID.
    */
    class func autoIncrementedInteger(for attribute: String,
                                      in context: NSManagedObjectContext = AERecord.Context.default) -> Int {
        
        let sortDescriptor = NSSortDescriptor(key: attribute, ascending: false)
        guard
            let object = self.first(orderedBy: [sortDescriptor], in: context),
            let max = object.value(forKey: attribute) as? Int
        else { return 0 }
        return max + 1
    }
    
    /**
        Turns object into fault.

        - parameter mergeChanges: A Boolean value.
        - parameter context: If not specified, `AERecord.Context.default` will be used.
    */
    func refresh(mergeChanges: Bool = true, in context: NSManagedObjectContext = AERecord.Context.default) {
        AERecord.refreshObjects(with: [objectID], mergeChanges: mergeChanges, in: context)
    }
    
    // MARK: - Batch Update
    
    /**
        Updates data directly in persistent store.

        - parameter properties: Properties to update.
        - parameter predicate: Predicate.
        - parameter resultType: If not specified, `StatusOnlyResultType` will be used.
        - parameter context: If not specified, `AERecord.Context.default` will be used.

        - returns: Batch update result.
    */
    class func batchUpdate(properties: [AnyHashable : Any], predicate: NSPredicate? = nil,
                           resultType: NSBatchUpdateRequestResultType = .statusOnlyResultType,
                           in context: NSManagedObjectContext = AERecord.Context.default) -> NSBatchUpdateResult? {
        
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
                debugPrint(error)
            }
        }
        
        return batchResult
    }
    
    /**
        Updates data directly in persistent store.

        - parameter properties: Properties to update.
        - parameter predicate: Predicate.
        - parameter context: If not specified, `AERecord.Context.default` will be used.

        - returns: Count of updated objects.
    */
    class func objectsCountForBatchUpdate(properties: [AnyHashable : Any], predicate: NSPredicate? = nil,
                                          in context: NSManagedObjectContext = AERecord.Context.default) -> Int {
        
        let type = NSBatchUpdateRequestResultType.updatedObjectsCountResultType
        if let result = batchUpdate(properties: properties, predicate: predicate, resultType: type, in: context) {
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
        Updates data directly in persistent store.

        Objects are turned into faults after updating *(managed object context is refreshed)*.

        - parameter properties: Properties to update.
        - parameter predicate: Predicate.
        - parameter context: If not specified, `AERecord.Context.default` will be used.
    */
    class func batchUpdateAndRefreshObjects(properties: [AnyHashable : Any], predicate: NSPredicate? = nil,
                                            in context: NSManagedObjectContext = AERecord.Context.default) {
        
        let type = NSBatchUpdateRequestResultType.updatedObjectIDsResultType
        if let result = batchUpdate(properties: properties, predicate: predicate, resultType: type, in: context) {
            if let objectIDs = result.result as? [NSManagedObjectID] {
                AERecord.refreshObjects(with: objectIDs, mergeChanges: true, in: context)
            }
        }
    }
    
}
