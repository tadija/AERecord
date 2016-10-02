//
// AEQuery.swift
//
// Copyright (c) 2014-2016 Marko Tadić <tadija@me.com> http://tadija.net
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

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
    
    private static let defaultPredicateType: NSCompoundPredicate.LogicalType = .and
    
    /**
        Creates predicate for given attributes and predicate type.

        - parameter attributes: Dictionary of attribute names and values.
        - parameter predicateType: If not specified, `.and` will be used.

        - returns: The created predicate.
    */
    class func createPredicate(forAttributes attributes: [AnyHashable : Any],
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
    class func create(in context: NSManagedObjectContext = AERecord.Context.default) -> Self {
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
    class func create(withAttributes attributes: [String : Any],
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
    class func firstOrCreate(withAttribute attribute: String, value: Any,
                             in context: NSManagedObjectContext = AERecord.Context.default) -> Self {
        
        return _firstOrCreateWithAttribute(attribute, value: value, in: context)
    }
    
    /**
        Finds the first record for given attribute and value or creates new if it does not exist. Generic version.

        - parameter attribute: Attribute name.
        - parameter value: Attribute value.
        - parameter context: If not specified, `AERecord.Context.default` will be used.

        - returns: Instance of `Self`.
    */
    private class func _firstOrCreateWithAttribute<T>(_ attribute: String, value: Any,
                                                   in context: NSManagedObjectContext = AERecord.Context.default) -> T {
        
        let object = firstOrCreate(withAttributes: [attribute : value], in: context)
        return object as! T
    }
    
    /**
        Finds the first record for given attributes or creates new if it does not exist.

        - parameter attributes: Dictionary of attribute names and values.
        - parameter predicateType: If not specified, `.AndPredicateType` will be used.
        - parameter context: If not specified, `AERecord.Context.default` will be used.

        - returns: Instance of managed object.
    */
    class func firstOrCreate(withAttributes attributes: [String : Any],
                             predicateType: NSCompoundPredicate.LogicalType = defaultPredicateType,
                             in context: NSManagedObjectContext = AERecord.Context.default) -> Self {
        
        return _firstOrCreate(withAttributes: attributes, predicateType: predicateType, in: context)
    }
    
    /**
        Finds the first record for given attributes or creates new if it does not exist. Generic version.

        - parameter attributes: Dictionary of attribute names and values.
        - parameter predicateType: If not specified, `.AndPredicateType` will be used.
        - parameter context: If not specified, `AERecord.Context.default` will be used.

        - returns: Instance of `Self`.
    */
    private class func _firstOrCreate<T>(withAttributes attributes: [String : Any],
                                      predicateType: NSCompoundPredicate.LogicalType = defaultPredicateType,
                                      in context: NSManagedObjectContext = AERecord.Context.default) -> T {
        
        let predicate = createPredicate(forAttributes: attributes, predicateType: predicateType)
        let request = createFetchRequest(predicate: predicate)
        request.fetchLimit = 1
        
        let objects = AERecord.execute(fetchRequest: request, in: context)
        return (objects.first ?? create(withAttributes: attributes, in: context)) as! T
    }
    
    // MARK: - Find First
    
    /**
        Finds the first record.

        - parameter sortDescriptors: Sort descriptors.
        - parameter context: If not specified, `AERecord.Context.default` will be used.

        - returns: Optional managed object.
    */
    class func first(sortDescriptors: [NSSortDescriptor]? = nil,
                     in context: NSManagedObjectContext = AERecord.Context.default) -> Self? {
        
        return _first(sortDescriptors: sortDescriptors, in: context)
    }
    
    /**
        Finds the first record. Generic version.

        - parameter sortDescriptors: Sort descriptors.
        - parameter context: If not specified, `AERecord.Context.default` will be used.

        - returns: Optional instance of `Self`.
    */
    private class func _first<T>(sortDescriptors: [NSSortDescriptor]? = nil,
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
    class func first(withPredicate predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]? = nil,
                     in context: NSManagedObjectContext = AERecord.Context.default) -> Self? {
        
        return _first(withPredicate: predicate, sortDescriptors: sortDescriptors, in: context)
    }
    
    /**
        Finds the first record for given predicate. Generic version

        - parameter predicate: Predicate.
        - parameter sortDescriptors: Sort descriptors.
        - parameter context: If not specified, `AERecord.Context.default` will be used.

        - returns: Optional instance of `Self`.
    */
    private class func _first<T>(withPredicate predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]? = nil,
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
    class func first(withAttribute attribute: String, value: Any, sortDescriptors: [NSSortDescriptor]? = nil,
                     in context: NSManagedObjectContext = AERecord.Context.default) -> Self? {
        
        let predicate = NSPredicate(format: "%K = %@", argumentArray: [attribute, value])
        return first(withPredicate: predicate, sortDescriptors: sortDescriptors, in: context)
    }
    
    /**
        Finds the first record for given attributes.

        - parameter attributes: Dictionary of attribute names and values.
        - parameter predicateType: If not specified, `.AndPredicateType` will be used.
        - parameter sortDescriptors: Sort descriptors.
        - parameter context: If not specified, `AERecord.Context.default` will be used.

        - returns: Optional managed object.
    */
    class func first(withAttributes attributes: [AnyHashable : Any],
                     predicateType: NSCompoundPredicate.LogicalType = defaultPredicateType,
                     sortDescriptors: [NSSortDescriptor]? = nil,
                     in context: NSManagedObjectContext = AERecord.Context.default) -> Self? {
        
        let predicate = createPredicate(forAttributes: attributes, predicateType: predicateType)
        return first(withPredicate: predicate, sortDescriptors: sortDescriptors, in: context)
    }
    
    /**
        Finds the first record ordered by given attribute.

        - parameter name: Attribute name.
        - parameter ascending: A Boolean value.
        - parameter context: If not specified, `AERecord.Context.default` will be used.

        - returns: Optional managed object.
    */
    class func first(orderedByAttribute name: String, ascending: Bool = true,
                     in context: NSManagedObjectContext = AERecord.Context.default) -> Self? {
        
        let sortDescriptors = [NSSortDescriptor(key: name, ascending: ascending)]
        return first(sortDescriptors: sortDescriptors, in: context)
    }
    
    // MARK: - Find All
    
    /**
        Finds all records.

        - parameter sortDescriptors: Sort descriptors.
        - parameter context: If not specified, `AERecord.Context.default` will be used.

        - returns: Optional managed object.
    */
    class func all(withSortDescriptors sortDescriptors: [NSSortDescriptor]? = nil,
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
    class func all<T>(withSortDescriptors sortDescriptors: [NSSortDescriptor]? = nil,
                   in context: NSManagedObjectContext = AERecord.Context.default) -> [T]? {
        
        let objects = all(withSortDescriptors: sortDescriptors, in: context)
        return objects?.map { $0 as! T }
    }
    
    /**
        Finds all records for given predicate.

        - parameter predicate: Predicate.
        - parameter sortDescriptors: Sort descriptors.
        - parameter context: If not specified, `AERecord.Context.default` will be used.

        - returns: Optional managed object.
    */
    class func all(withPredicate predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]? = nil,
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
    class func all<T>(withPredicate predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]? = nil,
                   in context: NSManagedObjectContext = AERecord.Context.default) -> [T]? {
        
        let objects = all(withPredicate: predicate, sortDescriptors: sortDescriptors, in: context)
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
    class func all(withAttribute attribute: String, value: Any, sortDescriptors: [NSSortDescriptor]? = nil,
                   in context: NSManagedObjectContext = AERecord.Context.default) -> [NSManagedObject]? {
        
        let predicate = NSPredicate(format: "%K = %@", argumentArray: [attribute, value])
        return all(withPredicate: predicate, sortDescriptors: sortDescriptors, in: context)
    }
    
    /**
        Finds all records for given attribute and value. Generic version

        - parameter attribute: Attribute name.
        - parameter value: Attribute value.
        - parameter sortDescriptors: Sort descriptors.
        - parameter context: If not specified, `AERecord.Context.default` will be used.

        - returns: Optional array of `Self` instances.
    */
    class func all<T>(withAttribute attribute: String, value: Any, sortDescriptors: [NSSortDescriptor]? = nil,
                   in context: NSManagedObjectContext = AERecord.Context.default) -> [T]? {
        
        let objects = all(withAttribute: attribute, value: value, sortDescriptors: sortDescriptors, in: context)
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
    class func all(withAttributes attributes: [AnyHashable : Any],
                   predicateType: NSCompoundPredicate.LogicalType = defaultPredicateType,
                   sortDescriptors: [NSSortDescriptor]? = nil,
                   in context: NSManagedObjectContext = AERecord.Context.default) -> [NSManagedObject]? {
        
        let predicate = createPredicate(forAttributes: attributes, predicateType: predicateType)
        return all(withPredicate: predicate, sortDescriptors: sortDescriptors, in: context)
    }
    
    /**
        Finds all records for given attributes. Generic version.

        - parameter attributes: Dictionary of attribute names and values.
        - parameter predicateType: If not specified, `.AndPredicateType` will be used.
        - parameter sortDescriptors: Sort descriptors.
        - parameter context: If not specified, `AERecord.Context.default` will be used.

        - returns: Optional array of `Self` instances.
    */
    class func all<T>(withAttributes attributes: [AnyHashable : Any],
                   predicateType: NSCompoundPredicate.LogicalType = defaultPredicateType,
                   sortDescriptors: [NSSortDescriptor]? = nil,
                   in context: NSManagedObjectContext = AERecord.Context.default) -> [T]? {
        
        let objects = all(withAttributes: attributes, predicateType: predicateType,
                          sortDescriptors: sortDescriptors, in: context)
        return objects?.map { $0 as! T }
    }
    
    // MARK: - Delete
    
    /**
        Deletes instance of entity object.

        - parameter context: If not specified, `AERecord.Context.default` will be used.
    */
    func delete(in context: NSManagedObjectContext = AERecord.Context.default) {
        context.delete(self)
    }
    
    /**
        Deletes all records.

        - parameter context: If not specified, `AERecord.Context.default` will be used.
    */
    class func deleteAll(in context: NSManagedObjectContext = AERecord.Context.default) {
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
    class func deleteAll(withPredicate predicate: NSPredicate,
                         in context: NSManagedObjectContext = AERecord.Context.default) {
        
        if let objects = all(withPredicate: predicate, in: context) {
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
    class func deleteAll(withAttribute attribute: String, value: Any,
                         in context: NSManagedObjectContext = AERecord.Context.default) {
        
        if let objects = all(withAttribute: attribute, value: value, in: context) {
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
    class func deleteAll(withAttributes attributes: [AnyHashable : Any],
                         predicateType: NSCompoundPredicate.LogicalType = defaultPredicateType,
                         in context: NSManagedObjectContext = AERecord.Context.default) {
        
        if let objects = all(withAttributes: attributes, predicateType: predicateType, in: context) {
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
    class func count(withPredicate predicate: NSPredicate? = nil,
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
    class func count(withAttribute attribute: String, value: Any,
                     in context: NSManagedObjectContext = AERecord.Context.default) -> Int {
        
        return count(withAttributes: [attribute : value], in: context)
    }
    
    /**
        Counts all records for given attributes.

        - parameter attributes: Dictionary of attribute names and values.
        - parameter predicateType: If not specified, `.AndPredicateType` will be used.
        - parameter context: If not specified, `AERecord.Context.default` will be used.

        - returns: Count of records.
    */
    class func count(withAttributes attributes: [AnyHashable : Any],
                     predicateType: NSCompoundPredicate.LogicalType = defaultPredicateType,
                     in context: NSManagedObjectContext = AERecord.Context.default) -> Int {
        
        let predicate = createPredicate(forAttributes: attributes, predicateType: predicateType)
        return count(withPredicate: predicate, in: context)
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
    class func distinctValues(withAttribute attribute: String,
                              predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil,
                              in context: NSManagedObjectContext = AERecord.Context.default) throws -> [Any]? {
        
        var distinctValues = [Any]()
        
        if let distinctRecords = try distinctRecords(withAttributes: [attribute], predicate: predicate,
                                                     sortDescriptors: sortDescriptors, in: context)
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
    class func distinctRecords(withAttributes attributes: [AnyHashable],
                               predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil,
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
    class func autoIncrementedInteger(forAttribute attribute: String,
                                      in context: NSManagedObjectContext = AERecord.Context.default) -> Int {
        
        let sortDescriptor = NSSortDescriptor(key: attribute, ascending: false)
        if let object = self.first(sortDescriptors: [sortDescriptor], in: context) {
            if let max = object.value(forKey: attribute) as? Int {
                return max + 1
            } else {
                return 0
            }
        } else {
            return 0
        }
    }
    
    /**
        Turns object into fault.

        - parameter mergeChanges: A Boolean value.
        - parameter context: If not specified, `AERecord.Context.default` will be used.
    */
    func refresh(in context: NSManagedObjectContext = AERecord.Context.default, mergeChanges: Bool = true) {
        AERecord.refreshObjects(in: context, objectIDs: [objectID], mergeChanges: mergeChanges)
    }
    
    // MARK: - Batch Update
    
    /**
        Updates data directly in persistent store.

        - parameter predicate: Predicate.
        - parameter properties: Properties to update.
        - parameter resultType: If not specified, `StatusOnlyResultType` will be used.
        - parameter context If: not specified, `AERecord.Context.default` will be used.

        - returns: Batch update result.
    */
    class func batchUpdate(properties: [AnyHashable : Any]? = nil, predicate: NSPredicate? = nil,
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
                print(error)
            }
        }
        
        return batchResult
    }
    
    /**
        Updates data directly in persistent store.

        - parameter predicate: Predicate.
        - parameter properties: Properties to update.
        - parameter context: If not specified, `AERecord.Context.default` will be used.

        - returns: Count of updated objects.
    */
    class func objectsCountForBatchUpdate(properties: [AnyHashable : Any]? = nil, predicate: NSPredicate? = nil,
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

        - parameter predicate: Predicate.
        - parameter properties: Properties to update.
        - parameter context: If not specified, `AERecord.Context.default` will be used.
    */
    class func batchUpdateAndRefreshObjects(properties: [AnyHashable : Any]? = nil, predicate: NSPredicate? = nil,
                                            in context: NSManagedObjectContext = AERecord.Context.default) {
        
        let type = NSBatchUpdateRequestResultType.updatedObjectIDsResultType
        if let result = batchUpdate(properties: properties, predicate: predicate, resultType: type, in: context) {
            if let objectIDs = result.result as? [NSManagedObjectID] {
                AERecord.refreshObjects(in: context, objectIDs: objectIDs, mergeChanges: true)
            }
        }
    }
    
}
