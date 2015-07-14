//
// AERecord.swift
//
// Copyright (c) 2014 Marko Tadić <tadija@me.com> http://tadija.net
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

import UIKit
import CoreData

let kAERecordPrintLog = true

// MARK: - AERecord (facade for shared instance of AEStack)

/**
    This class is facade for accessing shared instance of `AEStack` (private class which is all about the Core Data Stack).
*/
public class AERecord {
    
    // MARK: Properties
    
    /// Managed object context for current thread.
    public class var defaultContext: NSManagedObjectContext { return AEStack.sharedInstance.defaultContext }
    
    /// Managed object context for main thread.
    public class var mainContext: NSManagedObjectContext { return AEStack.sharedInstance.mainContext }
    
    /// Managed object context for background thread.
    public class var backgroundContext: NSManagedObjectContext { return AEStack.sharedInstance.backgroundContext }
    
    /// Persistent Store Coordinator for current stack.
    public class var persistentStoreCoordinator: NSPersistentStoreCoordinator? { return AEStack.sharedInstance.persistentStoreCoordinator }
    
    // MARK: Setup Stack
    
    /**
        Returns the final URL in Application Documents Directory for the store with given name.
    
        :param: name Filename for the store.
    */
    public class func storeURLForName(name: String) -> NSURL {
        return AEStack.storeURLForName(name)
    }
    
    /**
        Returns merged model from the bundle for given class.
        
        :param: forClass Class inside bundle with data model.
    */
    public class func modelFromBundle(#forClass: AnyClass) -> NSManagedObjectModel {
        return AEStack.modelFromBundle(forClass: forClass)
    }
    
    /**
        Loads Core Data Stack *(creates new if it doesn't already exist)* with given options **(all options are optional)**.
    
        - Default option for `managedObjectModel` is `NSManagedObjectModel.mergedModelFromBundles(nil)!`.
        - Default option for `storeType` is `NSSQLiteStoreType`.
        - Default option for `storeURL` is `bundleIdentifier + ".sqlite"` inside `applicationDocumentsDirectory`.
    
        :param: managedObjectModel Managed object model for Core Data Stack.
        :param: storeType Store type for Persistent Store creation.
        :param: configuration Configuration for Persistent Store creation.
        :param: storeURL URL for Persistent Store creation.
        :param: options Options for Persistent Store creation.
    
        :returns: Optional error if something went wrong.
    */
    public class func loadCoreDataStack(managedObjectModel: NSManagedObjectModel = AEStack.defaultModel, storeType: String = NSSQLiteStoreType, configuration: String? = nil, storeURL: NSURL = AEStack.defaultURL, options: [NSObject : AnyObject]? = nil) -> NSError? {
        return AEStack.sharedInstance.loadCoreDataStack(managedObjectModel: managedObjectModel, storeType: storeType, configuration: configuration, storeURL: storeURL, options: options)
    }
    
    /**
        Destroys Core Data Stack for given store URL *(stop notifications, reset contexts, remove persistent store and delete .sqlite file)*. **This action can't be undone.**
    
        :param: storeURL Store URL for stack to destroy.
    */
    public class func destroyCoreDataStack(storeURL: NSURL = AEStack.defaultURL) {
        AEStack.sharedInstance.destroyCoreDataStack(storeURL: storeURL)
    }
    
    /**
        Deletes all records from all entities contained in the model.
    
        :param: context If not specified, `defaultContext` will be used.
    */
    public class func truncateAllData(context: NSManagedObjectContext? = nil) {
        AEStack.sharedInstance.truncateAllData(context: context)
    }
    
    // MARK: Context Execute
    
    /**
        Executes given fetch request.
    
        :param: request Fetch request to execute.
        :param: context If not specified, `defaultContext` will be used.
    */
    public class func executeFetchRequest(request: NSFetchRequest, context: NSManagedObjectContext? = nil) -> [NSManagedObject] {
        return AEStack.sharedInstance.executeFetchRequest(request, context: context)
    }
    
    // MARK: Context Save
    
    /**
        Saves context *(without waiting - returns immediately)*.
    
        :param: context If not specified, `defaultContext` will be used.
    */
    public class func saveContext(context: NSManagedObjectContext? = nil) {
        AEStack.sharedInstance.saveContext(context: context)
    }
    
    /**
        Saves context with waiting *(returns when context is saved)*.
        
        :param: context If not specified, `defaultContext` will be used.
    */
    public class func saveContextAndWait(context: NSManagedObjectContext? = nil) {
        AEStack.sharedInstance.saveContextAndWait(context: context)
    }
    
    // MARK: Context Faulting Objects
    
    /**
        Turns objects into faults for given Array of `NSManagedObjectID`.
    
        :param: objectIDS Array of `NSManagedObjectID` objects to turn into fault.
        :param: mergeChanges A Boolean value.
        :param: context If not specified, `defaultContext` will be used.
    */
    public class func refreshObjects(#objectIDS: [NSManagedObjectID], mergeChanges: Bool, context: NSManagedObjectContext = AERecord.defaultContext) {
        AEStack.refreshObjects(objectIDS: objectIDS, mergeChanges: mergeChanges, context: context)
    }
    
    /**
    Turns all registered objects into faults.
    
    :param: mergeChanges A Boolean value.
    :param: context If not specified, `defaultContext` will be used.
    */
    public class func refreshAllRegisteredObjects(#mergeChanges: Bool, context: NSManagedObjectContext = AERecord.defaultContext) {
        AEStack.refreshAllRegisteredObjects(mergeChanges: mergeChanges, context: context)
    }
    
}

// MARK: - CoreData Stack (AERecord heart:)
private class AEStack {
    
    // MARK: Shared Instance
    
    class var sharedInstance: AEStack  {
        struct Singleton {
            static let instance = AEStack()
        }
        return Singleton.instance
    }
    
    // MARK: Default settings
    
    class var bundleIdentifier: String {
        return NSBundle.mainBundle().bundleIdentifier!
    }
    class var defaultURL: NSURL {
        return storeURLForName(bundleIdentifier)
    }
    class var defaultModel: NSManagedObjectModel {
        return NSManagedObjectModel.mergedModelFromBundles(nil)!
    }
    
    // MARK: Properties
    
    var managedObjectModel: NSManagedObjectModel?
    var persistentStoreCoordinator: NSPersistentStoreCoordinator?
    var mainContext: NSManagedObjectContext!
    var backgroundContext: NSManagedObjectContext!
    var defaultContext: NSManagedObjectContext {
        if NSThread.isMainThread() {
            return mainContext
        } else {
            return backgroundContext
        }
    }
    
    // MARK: Setup Stack
    
    class func storeURLForName(name: String) -> NSURL {
        let applicationDocumentsDirectory = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last as! NSURL
        let storeName = "\(name).sqlite"
        return applicationDocumentsDirectory.URLByAppendingPathComponent(storeName)
    }
    
    class func modelFromBundle(#forClass: AnyClass) -> NSManagedObjectModel {
        let bundle = NSBundle(forClass: forClass)
        return NSManagedObjectModel.mergedModelFromBundles([bundle])!
    }
    
    func loadCoreDataStack(managedObjectModel: NSManagedObjectModel = defaultModel,
        storeType: String = NSSQLiteStoreType,
        configuration: String? = nil,
        storeURL: NSURL = defaultURL,
        options: [NSObject : AnyObject]? = nil) -> NSError?
    {
        self.managedObjectModel = managedObjectModel
        
        // setup main and background contexts
        mainContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        backgroundContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        
        // create the coordinator and store
        persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        if let coordinator = persistentStoreCoordinator {
            var error: NSError?
            if coordinator.addPersistentStoreWithType(storeType, configuration: configuration, URL: storeURL, options: options, error: &error) == nil {
                var userInfoDictionary = [NSObject : AnyObject]()
                userInfoDictionary[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
                userInfoDictionary[NSLocalizedFailureReasonErrorKey] = "There was an error creating or loading the application's saved data."
                userInfoDictionary[NSUnderlyingErrorKey] = error
                error = NSError(domain: AEStack.bundleIdentifier, code: 1, userInfo: userInfoDictionary)
                if let err = error {
                    if kAERecordPrintLog {
                        println("Error occured in \(NSStringFromClass(self.dynamicType)) - function: \(__FUNCTION__) | line: \(__LINE__)\n\(err)")
                    }
                }
                return error
            } else {
                // everything went ok
                mainContext.persistentStoreCoordinator = coordinator
                backgroundContext.persistentStoreCoordinator = coordinator
                startReceivingContextNotifications()
                return nil
            }
        } else {
            return NSError(domain: AEStack.bundleIdentifier, code: 2, userInfo: [NSLocalizedDescriptionKey : "Could not create NSPersistentStoreCoordinator from given NSManagedObjectModel."])
        }
    }
    
    func destroyCoreDataStack(storeURL: NSURL = defaultURL) -> NSError? {
        // must load this core data stack first
        loadCoreDataStack(storeURL: storeURL) // because there is no persistentStoreCoordinator if destroyCoreDataStack is called before loadCoreDataStack
        // also if we're in other stack currently that persistentStoreCoordinator doesn't know about this storeURL
        stopReceivingContextNotifications() // stop receiving notifications for these contexts
        // reset contexts
        mainContext.reset()
        backgroundContext.reset()
        // finally, remove persistent store
        var error: NSError?
        if let coordinator = persistentStoreCoordinator {
            if let store = coordinator.persistentStoreForURL(storeURL) {
                if coordinator.removePersistentStore(store, error: &error) {
                    NSFileManager.defaultManager().removeItemAtURL(storeURL, error: &error)
                }
            }
        }
        // reset coordinator and model
        persistentStoreCoordinator = nil
        managedObjectModel = nil

        if let err = error {
            if kAERecordPrintLog {
                println("Error occured in \(NSStringFromClass(self.dynamicType)) - function: \(__FUNCTION__) | line: \(__LINE__)\n\(err)")
            }
        }
        return error ?? nil
    }
    
    func truncateAllData(context: NSManagedObjectContext? = nil) {
        let moc = context ?? defaultContext
        if let mom = managedObjectModel {
            for entity in mom.entities as! [NSEntityDescription] {
                if let entityType = NSClassFromString(entity.managedObjectClassName) as? NSManagedObject.Type {
                    entityType.deleteAll(context: moc)
                }
            }
        }
    }
    
    deinit {
        stopReceivingContextNotifications()
        if kAERecordPrintLog {
            println("\(NSStringFromClass(self.dynamicType)) deinitialized - function: \(__FUNCTION__) | line: \(__LINE__)\n")
        }
    }
    
    // MARK: Context Execute
    
    func executeFetchRequest(request: NSFetchRequest, context: NSManagedObjectContext? = nil) -> [NSManagedObject] {
        var fetchedObjects = [NSManagedObject]()
        let moc = context ?? defaultContext
        moc.performBlockAndWait { () -> Void in
            var error: NSError?
            if let result = moc.executeFetchRequest(request, error: &error) {
                if let managedObjects = result as? [NSManagedObject] {
                    fetchedObjects = managedObjects
                }
            }
            if let err = error {
                if kAERecordPrintLog {
                    println("Error occured in \(NSStringFromClass(self.dynamicType)) - function: \(__FUNCTION__) | line: \(__LINE__)\n\(err)")
                }
            }
        }
        return fetchedObjects
    }
    
    // MARK: Context Save
    
    func saveContext(context: NSManagedObjectContext? = nil) {
        let moc = context ?? defaultContext
        moc.performBlock { () -> Void in
            var error: NSError?
            if moc.hasChanges && !moc.save(&error) {
                if let err = error {
                    if kAERecordPrintLog {
                        println("Error occured in \(NSStringFromClass(self.dynamicType)) - function: \(__FUNCTION__) | line: \(__LINE__)\n\(err)")
                    }
                }
            }
        }
    }
    
    func saveContextAndWait(context: NSManagedObjectContext? = nil) {
        let moc = context ?? defaultContext
        moc.performBlockAndWait { () -> Void in
            var error: NSError?
            if moc.hasChanges && !moc.save(&error) {
                if let err = error {
                    if kAERecordPrintLog {
                        println("Error occured in \(NSStringFromClass(self.dynamicType)) - function: \(__FUNCTION__) | line: \(__LINE__)\n\(err)")
                    }
                }
            }
        }
    }
    
    // MARK: Context Sync
    
    func startReceivingContextNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "contextDidSave:", name: NSManagedObjectContextDidSaveNotification, object: mainContext)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "contextDidSave:", name: NSManagedObjectContextDidSaveNotification, object: backgroundContext)
    }
    
    func stopReceivingContextNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    @objc func contextDidSave(notification: NSNotification) {
        if let context = notification.object as? NSManagedObjectContext {
            let contextToRefresh = context == mainContext ? backgroundContext : mainContext
            contextToRefresh.performBlock({ () -> Void in
                contextToRefresh.mergeChangesFromContextDidSaveNotification(notification)
            })
        }
    }
    
    // MARK: Context Faulting Objects
    
    class func refreshObjects(#objectIDS: [NSManagedObjectID], mergeChanges: Bool, context: NSManagedObjectContext = AERecord.defaultContext) {
        for objectID in objectIDS {
            var error: NSError?
            context.performBlockAndWait({ () -> Void in
                if let object = context.existingObjectWithID(objectID, error: &error) {
                    if !object.fault && error == nil {
                        // turn managed object into fault
                        context.refreshObject(object, mergeChanges: mergeChanges)
                    } else {
                        if let err = error {
                            if kAERecordPrintLog {
                                println("Error occured in \(NSStringFromClass(self.dynamicType)) - function: \(__FUNCTION__) | line: \(__LINE__)\n\(err)")
                            }
                        }
                    }
                }
            })
        }
    }
    
    class func refreshAllRegisteredObjects(#mergeChanges: Bool, context: NSManagedObjectContext = AERecord.defaultContext) {
        var registeredObjectIDS = [NSManagedObjectID]()
        for object in context.registeredObjects {
            if let managedObject = object as? NSManagedObject {
                registeredObjectIDS.append(managedObject.objectID)
            }
        }
        refreshObjects(objectIDS: registeredObjectIDS, mergeChanges: mergeChanges)
    }
    
}

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
        name = name.componentsSeparatedByString(".").last
        return name
    }
    
    /// An `NSEntityDescription` object describes an entity in Core Data.
    class var entity: NSEntityDescription? {
        return NSEntityDescription.entityForName(entityName, inManagedObjectContext: AERecord.defaultContext)
    }
    
    /**
        Creates fetch request **(for any entity type)** for given predicate and sort descriptors *(which are optional)*.
    
        :param: predicate Predicate for fetch request.
        :param sortDescriptors Sort Descriptors for fetch request.
    
        :returns: The created fetch request.
    */
    class func createFetchRequest(predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) -> NSFetchRequest {
        let request = NSFetchRequest(entityName: entityName)
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        return request
    }
    
    private static let defaultPredicateType: NSCompoundPredicateType = .AndPredicateType
    
    /**
        Creates predicate for given attributes and predicate type.
    
        :param: attributes Dictionary of attribute names and values.
        :param: predicateType If not specified, `.AndPredicateType` will be used.
    
        :returns: The created predicate.
    */
    class func createPredicateForAttributes(attributes: [NSObject : AnyObject], predicateType: NSCompoundPredicateType = defaultPredicateType) -> NSPredicate {
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
        let entityDescription = NSEntityDescription.entityForName(entityName, inManagedObjectContext: context)
        let object = self(entity: entityDescription!, insertIntoManagedObjectContext: context)
        return object
    }
    
    /**
        Creates new instance of entity object and set it with given attributes.
    
        :param: attributes Dictionary of attribute names and values.
        :param: context If not specified, `defaultContext` will be used.
    
        :returns: New instance of `Self` with set attributes.
    */
    class func createWithAttributes(attributes: [NSObject : AnyObject], context: NSManagedObjectContext = AERecord.defaultContext) -> Self {
        let object = create(context: context)
        if attributes.count > 0 {
            object.setValuesForKeysWithDictionary(attributes)
        }
        return object
    }
    
    /**
        Finds the first record for given attribute and value or creates new if the it does not exist.
    
        :param: attribute Attribute name.
        :param: value Attribute value.
        :param: context If not specified, `defaultContext` will be used.
    
        :returns: Instance of managed object.
    */
    class func firstOrCreateWithAttribute(attribute: String, value: AnyObject, context: NSManagedObjectContext = AERecord.defaultContext) -> NSManagedObject {
        return firstOrCreateWithAttributes([attribute : value], context: context)
    }
    
    /**
        Finds the first record for given attributes or creates new if the it does not exist.
        
        :param: attributes Dictionary of attribute names and values.
        :param: predicateType If not specified, `.AndPredicateType` will be used.
        :param: context If not specified, `defaultContext` will be used.
        
        :returns: Instance of managed object.
    */
    class func firstOrCreateWithAttributes(attributes: [NSObject : AnyObject], predicateType: NSCompoundPredicateType = defaultPredicateType, context: NSManagedObjectContext = AERecord.defaultContext) -> NSManagedObject {
        let predicate = createPredicateForAttributes(attributes, predicateType: predicateType)
        let request = createFetchRequest(predicate: predicate)
        request.fetchLimit = 1
        let objects = AERecord.executeFetchRequest(request, context: context)
        return objects.first ?? createWithAttributes(attributes, context: context)
    }
    
    // MARK: Finding First
    
    /**
        Finds the first record.
    
        :param: sortDescriptors Sort descriptors.
        :param: context If not specified, `defaultContext` will be used.
    
        :returns: Optional managed object.
    */
    class func first(sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> NSManagedObject? {
        let request = createFetchRequest(sortDescriptors: sortDescriptors)
        request.fetchLimit = 1
        let objects = AERecord.executeFetchRequest(request, context: context)
        return objects.first ?? nil
    }
    
    /**
        Finds the first record for given predicate.
        
        :param: predicate Predicate.
        :param: sortDescriptors Sort descriptors.
        :param: context If not specified, `defaultContext` will be used.
        
        :returns: Optional managed object.
    */
    class func firstWithPredicate(predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> NSManagedObject? {
        let request = createFetchRequest(predicate: predicate, sortDescriptors: sortDescriptors)
        request.fetchLimit = 1
        let objects = AERecord.executeFetchRequest(request, context: context)
        return objects.first ?? nil
    }
    
    /**
        Finds the first record for given attribute and value.
        
        :param: attribute Attribute name.
        :param: value Attribute value.
        :param: sortDescriptors Sort descriptors.
        :param: context If not specified, `defaultContext` will be used.
        
        :returns: Optional managed object.
    */
    class func firstWithAttribute(attribute: String, value: AnyObject, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> NSManagedObject? {
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
    class func firstWithAttributes(attributes: [NSObject : AnyObject], predicateType: NSCompoundPredicateType = defaultPredicateType, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> NSManagedObject? {
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
    class func firstOrderedByAttribute(name: String, ascending: Bool = true, context: NSManagedObjectContext = AERecord.defaultContext) -> NSManagedObject? {
        let sortDescriptors = [NSSortDescriptor(key: name, ascending: ascending)]
        return first(sortDescriptors: sortDescriptors, context: context)
    }
    
    // MARK: Finding All
    
    /**
        Finds all records.
    
        :param: sortDescriptors Sort descriptors.
        :param: context If not specified, `defaultContext` will be used.
        
        :returns: Optional managed object.
    */
    class func all(sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> [NSManagedObject]? {
        let request = createFetchRequest(sortDescriptors: sortDescriptors)
        let objects = AERecord.executeFetchRequest(request, context: context)
        return objects.count > 0 ? objects : nil
    }
    
    /**
        Finds all records for given predicate.
        
        :param: predicate Predicate.
        :param: sortDescriptors Sort descriptors.
        :param: context If not specified, `defaultContext` will be used.
        
        :returns: Optional managed object.
    */
    class func allWithPredicate(predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> [NSManagedObject]? {
        let request = createFetchRequest(predicate: predicate, sortDescriptors: sortDescriptors)
        let objects = AERecord.executeFetchRequest(request, context: context)
        return objects.count > 0 ? objects : nil
    }
    
    /**
        Finds all records for given attribute and value.
        
        :param: attribute Attribute name.
        :param: value Attribute value.
        :param: sortDescriptors Sort descriptors.
        :param: context If not specified, `defaultContext` will be used.
        
        :returns: Optional managed object.
    */
    class func allWithAttribute(attribute: String, value: AnyObject, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> [NSManagedObject]? {
        let predicate = NSPredicate(format: "%K = %@", argumentArray: [attribute, value])
        return allWithPredicate(predicate, sortDescriptors: sortDescriptors, context: context)
    }
    
    /**
        Finds all records for given attributes.
        
        :param: attributes Dictionary of attribute names and values.
        :param: predicateType If not specified, `.AndPredicateType` will be used.
        :param: sortDescriptors Sort descriptors.
        :param: context If not specified, `defaultContext` will be used.
        
        :returns: Optional managed object.
    */
    class func allWithAttributes(attributes: [NSObject : AnyObject], predicateType: NSCompoundPredicateType = defaultPredicateType, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> [NSManagedObject]? {
        let predicate = createPredicateForAttributes(attributes, predicateType: predicateType)
        return allWithPredicate(predicate, sortDescriptors: sortDescriptors, context: context)
    }
    
    // MARK: Deleting
    
    /**
        Deletes instance of entity object.
        
        :param: context If not specified, `defaultContext` will be used.
    */
    func delete(context: NSManagedObjectContext = AERecord.defaultContext) {
        context.deleteObject(self)
    }
    
    /**
        Deletes all records.
    
        :param: context If not specified, `defaultContext` will be used.
    */
    class func deleteAll(context: NSManagedObjectContext = AERecord.defaultContext) {
        if let objects = self.all(context: context) {
            for object in objects {
                context.deleteObject(object)
            }
        }
    }
    
    /**
        Deletes all records for given predicate.
        
        :param: predicate Predicate.
        :param: context If not specified, `defaultContext` will be used.
    */
    class func deleteAllWithPredicate(predicate: NSPredicate, context: NSManagedObjectContext = AERecord.defaultContext) {
        if let objects = self.allWithPredicate(predicate, context: context) {
            for object in objects {
                context.deleteObject(object)
            }
        }
    }
    
    /**
        Deletes all records for given attribute name and value.
        
        :param: attribute Attribute name.
        :param: value Attribute value.
        :param: context If not specified, `defaultContext` will be used.
    */
    class func deleteAllWithAttribute(attribute: String, value: AnyObject, context: NSManagedObjectContext = AERecord.defaultContext) {
        if let objects = self.allWithAttribute(attribute, value: value, context: context) {
            for object in objects {
                context.deleteObject(object)
            }
        }
    }
    
    /**
        Deletes all records for given attributes.
        
        :param: attributes Dictionary of attribute names and values.
        :param: predicateType If not specified, `.AndPredicateType` will be used.
        :param: context If not specified, `defaultContext` will be used.
    */
    class func deleteAllWithAttributes(attributes: [NSObject : AnyObject], predicateType: NSCompoundPredicateType = defaultPredicateType, context: NSManagedObjectContext = AERecord.defaultContext) {
        if let objects = self.allWithAttributes(attributes, predicateType: predicateType, context: context) {
            for object in objects {
                context.deleteObject(object)
            }
        }
    }
    
    // MARK: Count
    
    /**
        Counts all records.
        
        :param: context If not specified, `defaultContext` will be used.
        
        :returns: Count of records.
    */
    class func count(context: NSManagedObjectContext = AERecord.defaultContext) -> Int {
        return countWithPredicate(context: context)
    }
    
    /**
        Counts all records for given predicate.
        
        :param: predicate Predicate.
        :param: context If not specified, `defaultContext` will be used.
        
        :returns: Count of records.
    */
    class func countWithPredicate(predicate: NSPredicate? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> Int {
        let request = createFetchRequest(predicate: predicate)
        request.includesSubentities = false
        
        var error: NSError?
        let count = context.countForFetchRequest(request, error: &error)
        
        if let err = error {
            if kAERecordPrintLog {
                println("Error occured in \(NSStringFromClass(self.dynamicType)) - function: \(__FUNCTION__) | line: \(__LINE__)\n\(err)")
            }
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
    class func countWithAttribute(attribute: String, value: AnyObject, context: NSManagedObjectContext = AERecord.defaultContext) -> Int {
        return countWithAttributes([attribute : value], context: context)
    }
    
    /**
        Counts all records for given attributes.
        
        :param: attributes Dictionary of attribute names and values.
        :param: predicateType If not specified, `.AndPredicateType` will be used.
        :param: context If not specified, `defaultContext` will be used.
        
        :returns: Count of records.
    */
    class func countWithAttributes(attributes: [NSObject : AnyObject], predicateType: NSCompoundPredicateType = defaultPredicateType, context: NSManagedObjectContext = AERecord.defaultContext) -> Int {
        let predicate = createPredicateForAttributes(attributes, predicateType: predicateType)
        return countWithPredicate(predicate: predicate, context: context)
    }
    
    // MARK: Distinct
    
    /**
        Gets distinct values for given attribute and predicate.
    
        :param: attribute Attribute name.
        :param: predicate Predicate.
        :param: sortDescriptors Sort descriptors.
        :param: context If not specified, `defaultContext` will be used.
    
        :returns: Optional Array of `AnyObject`.
    */
    class func distinctValuesForAttribute(attribute: String, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> [AnyObject]? {
        var distinctValues = [AnyObject]()
        
        if let distinctRecords = distinctRecordsForAttributes([attribute], predicate: predicate, sortDescriptors: sortDescriptors, context: context) {
            for record in distinctRecords {
                if let value: AnyObject = record[attribute] {
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
        
        :returns: Optional Array of `AnyObject`.
    */
    class func distinctRecordsForAttributes(attributes: [String], predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> [Dictionary<String, AnyObject>]? {
        let request = createFetchRequest(predicate: predicate, sortDescriptors: sortDescriptors)
        
        request.resultType = .DictionaryResultType
        request.propertiesToFetch = attributes
        request.returnsDistinctResults = true
        
        var distinctRecords: [Dictionary<String, AnyObject>]?
        
        var error: NSError?
        if let distinctResult = context.executeFetchRequest(request, error: &error) as? [Dictionary<String, AnyObject>] {
            distinctRecords = distinctResult
        }
        
        if let err = error {
            if kAERecordPrintLog {
                println("Error occured in \(NSStringFromClass(self.dynamicType)) - function: \(__FUNCTION__) | line: \(__LINE__)\n\(err)")
            }
        }
        
        return distinctRecords
    }
    
    // MARK: Auto Increment
    
    /**
        Gets next ID for given attribute name. Attribute must be of `Int` type.
        
        :param: attribute Attribute name.
        :param: context If not specified, `defaultContext` will be used.
    
        :returns: Auto incremented ID.
    */
    class func autoIncrementedIntegerAttribute(attribute: String, context: NSManagedObjectContext = AERecord.defaultContext) -> Int {
        let sortDescriptor = NSSortDescriptor(key: attribute, ascending: false)
        if let object = self.first(sortDescriptors: [sortDescriptor], context: context) {
            if let max = object.valueForKey(attribute) as? Int {
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
    func refresh(mergeChanges: Bool = true, context: NSManagedObjectContext = AERecord.defaultContext) {
        AERecord.refreshObjects(objectIDS: [objectID], mergeChanges: mergeChanges, context: context)
    }
    
    // MARK: Batch Updating
    
    /**
        Updates data directly in persistent store **(iOS 8 and above)**.
    
        :param: predicate Predicate.
        :param: properties Properties to update.
        :param: resultType If not specified, `StatusOnlyResultType` will be used.
        :param: context If not specified, `defaultContext` will be used.
    
        :returns: Batch update result.
    */
    class func batchUpdate(predicate: NSPredicate? = nil, properties: [NSObject : AnyObject]? = nil, resultType: NSBatchUpdateRequestResultType = .StatusOnlyResultType, context: NSManagedObjectContext = AERecord.defaultContext) -> NSBatchUpdateResult? {
        // create request
        let request = NSBatchUpdateRequest(entityName: entityName)
        // set request parameters
        request.predicate = predicate
        request.propertiesToUpdate = properties
        request.resultType = resultType
        // execute request
        var batchResult: NSBatchUpdateResult? = nil
        context.performBlockAndWait { () -> Void in
            var error: NSError?
            if let result = context.executeRequest(request, error: &error) as? NSBatchUpdateResult {
                batchResult = result
            }
            if let err = error {
                if kAERecordPrintLog {
                    println("Error occured in \(NSStringFromClass(self.dynamicType)) - function: \(__FUNCTION__) | line: \(__LINE__)\n\(err)")
                }
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
    class func objectsCountForBatchUpdate(predicate: NSPredicate? = nil, properties: [NSObject : AnyObject]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> Int {
        if let result = batchUpdate(predicate: predicate, properties: properties, resultType: .UpdatedObjectsCountResultType, context: context) {
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
    class func batchUpdateAndRefreshObjects(predicate: NSPredicate? = nil, properties: [NSObject : AnyObject]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) {
        if let result = batchUpdate(predicate: predicate, properties: properties, resultType: .UpdatedObjectIDsResultType, context: context) {
            if let objectIDS = result.result as? [NSManagedObjectID] {
                AERecord.refreshObjects(objectIDS: objectIDS, mergeChanges: true, context: context)
            }
        }
    }
    
}

//  MARK: - CoreData driven UITableViewController

/**
    Swift version of class originaly created for **Stanford CS193p Winter 2013**.

    This class mostly just copies the code from `NSFetchedResultsController` documentation page
    into a subclass of `UITableViewController`.

    Just subclass this and set the `fetchedResultsController` property.
    The only `UITableViewDataSource` method you'll **HAVE** to implement is `tableView:cellForRowAtIndexPath:`.
    And you can use the `NSFetchedResultsController` method `objectAtIndexPath:` to do it.

    Remember that once you create an `NSFetchedResultsController`, you **CANNOT** modify its properties.
    If you want new fetch parameters (predicate, sorting, etc.),
    create a **NEW** `NSFetchedResultsController` and set this class's `fetchedResultsController` property again.
*/
public class CoreDataTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    /// The controller *(this class fetches nothing if this is not set)*.
    public var fetchedResultsController: NSFetchedResultsController? {
        didSet {
            if let frc = fetchedResultsController {
                if frc != oldValue {
                    frc.delegate = self
                    performFetch()
                }
            } else {
                tableView.reloadData()
            }
        }
    }
    
    /**
        Causes the `fetchedResultsController` to refetch the data.
        You almost certainly never need to call this.
        The `NSFetchedResultsController` class observes the context
        (so if the objects in the context change, you do not need to call `performFetch`
        since the `NSFetchedResultsController` will notice and update the table automatically).
        This will also automatically be called if you change the `fetchedResultsController` property.
    */
    public func performFetch() {
        if let frc = fetchedResultsController {
            var error: NSError?
            if !frc.performFetch(&error) {
                if let err = error {
                    if kAERecordPrintLog {
                        println("Error occured in \(NSStringFromClass(self.dynamicType)) - function: \(__FUNCTION__) | line: \(__LINE__)\n\(err)")
                    }
                }
            }
            tableView.reloadData()
        }
    }
    
    private var _suspendAutomaticTrackingOfChangesInManagedObjectContext: Bool = false
    /**
        Turn this on before making any changes in the managed object context that
        are a one-for-one result of the user manipulating rows directly in the table view.
        Such changes cause the context to report them (after a brief delay),
        and normally our `fetchedResultsController` would then try to update the table,
        but that is unnecessary because the changes were made in the table already (by the user)
        so the `fetchedResultsController` has nothing to do and needs to ignore those reports.
        Turn this back off after the user has finished the change.
        Note that the effect of setting this to NO actually gets delayed slightly
        so as to ignore previously-posted, but not-yet-processed context-changed notifications,
        therefore it is fine to set this to YES at the beginning of, e.g., `tableView:moveRowAtIndexPath:toIndexPath:`,
        and then set it back to NO at the end of your implementation of that method.
        It is not necessary (in fact, not desirable) to set this during row deletion or insertion
        (but definitely for row moves).
    */
    public var suspendAutomaticTrackingOfChangesInManagedObjectContext: Bool {
        get {
            return _suspendAutomaticTrackingOfChangesInManagedObjectContext
        }
        set (newValue) {
            if newValue == true {
                _suspendAutomaticTrackingOfChangesInManagedObjectContext = true
            } else {
                dispatch_after(0, dispatch_get_main_queue(), { self._suspendAutomaticTrackingOfChangesInManagedObjectContext = false })
            }
        }
    }
    private var beganUpdates: Bool = false
    
    // MARK: NSFetchedResultsControllerDelegate
    
    /**
        Notifies the receiver that the fetched results controller is about to start processing of one or more changes due to an add, remove, move, or update.
    
        :param: controller The fetched results controller that sent the message.
    */
    public func controllerWillChangeContent(controller: NSFetchedResultsController) {
        if !suspendAutomaticTrackingOfChangesInManagedObjectContext {
            tableView.beginUpdates()
            beganUpdates = true
        }
    }
    
    /**
        Notifies the receiver of the addition or removal of a section.
    
        :param: controller The fetched results controller that sent the message.
        :param: sectionInfo The section that changed.
        :param: sectionIndex The index of the changed section.
        :param: type The type of change (insert or delete).
    */
    public func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        if !suspendAutomaticTrackingOfChangesInManagedObjectContext {
            switch type {
            case .Insert:
                tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
            case .Delete:
                tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
            default:
                return
            }
        }
    }
    
    /**
        Notifies the receiver that a fetched object has been changed due to an add, remove, move, or update.
    
        :param: controller The fetched results controller that sent the message.
        :param: anObject The object in controller’s fetched results that changed.
        :param: indexPath The index path of the changed object (this value is nil for insertions).
        :param: type The type of change.
        :param: newIndexPath The destination path for the object for insertions or moves (this value is nil for a deletion).
    */
    public func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        if !suspendAutomaticTrackingOfChangesInManagedObjectContext {
            switch type {
            case .Insert:
                tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            case .Delete:
                tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            case .Update:
                tableView.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            case .Move:
                tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
                tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            default:
                return
            }
        }
    }
    
    /**
        Notifies the receiver that the fetched results controller has completed processing of one or more changes due to an add, remove, move, or update.
    
        :param: controller The fetched results controller that sent the message.
    */
    public func controllerDidChangeContent(controller: NSFetchedResultsController) {
        if beganUpdates {
            tableView.endUpdates()
        }
    }
    
    // MARK: UITableViewDataSource
    
    /**
        Asks the data source to return the number of sections in the table view.
    
        :param: tableView An object representing the table view requesting this information.
    
        :returns: The number of sections in tableView.
    */
    override public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultsController?.sections?.count ?? 0
    }
    
    /**
        Tells the data source to return the number of rows in a given section of a table view. (required)
        
        :param: tableView The table-view object requesting this information.
        :param: section An index number identifying a section in tableView.
        
        :returns: The number of rows in section.
    */
    override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (fetchedResultsController?.sections?[section] as? NSFetchedResultsSectionInfo)?.numberOfObjects ?? 0
    }
    
    /**
        Asks the data source for the title of the header of the specified section of the table view.
        
        :param: tableView An object representing the table view requesting this information.
        :param: section An index number identifying a section in tableView.
        
        :returns: A string to use as the title of the section header.
    */
    override public func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return (fetchedResultsController?.sections?[section] as? NSFetchedResultsSectionInfo)?.name
    }
    
    /**
        Asks the data source to return the index of the section having the given title and section title index.
        
        :param: tableView An object representing the table view requesting this information.
        :param: title The title as displayed in the section index of tableView.
        :param: index An index number identifying a section title in the array returned by sectionIndexTitlesForTableView:.
        
        :returns: An index number identifying a section.
    */
    override public func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        return fetchedResultsController?.sectionForSectionIndexTitle(title, atIndex: index) ?? 0
    }
    
    /**
        Asks the data source to return the titles for the sections for a table view.
        
        :param: tableView An object representing the table view requesting this information.
        
        :returns: An array of strings that serve as the title of sections in the table view and appear in the index list on the right side of the table view.
    */
    override public func sectionIndexTitlesForTableView(tableView: UITableView) -> [AnyObject]! {
        return fetchedResultsController?.sectionIndexTitles
    }
    
}

//  MARK: - CoreData driven UICollectionViewController

/**
    Same concept as `CoreDataTableViewController`, but modified for use with `UICollectionViewController`.

    This class mostly just copies the code from `NSFetchedResultsController` documentation page
    into a subclass of `UICollectionViewController`.

    Just subclass this and set the `fetchedResultsController`.
    The only `UICollectionViewDataSource` method you'll **HAVE** to implement is `collectionView:cellForItemAtIndexPath:`.
    And you can use the `NSFetchedResultsController` method `objectAtIndexPath:` to do it.

    Remember that once you create an `NSFetchedResultsController`, you **CANNOT** modify its properties.
    If you want new fetch parameters (predicate, sorting, etc.),
    create a **NEW** `NSFetchedResultsController` and set this class's `fetchedResultsController` property again.
*/
public class CoreDataCollectionViewController: UICollectionViewController, NSFetchedResultsControllerDelegate {
    
    /// The controller *(this class fetches nothing if this is not set)*.
    public var fetchedResultsController: NSFetchedResultsController? {
        didSet {
            if let frc = fetchedResultsController {
                if frc != oldValue {
                    frc.delegate = self
                    performFetch()
                }
            } else {
                collectionView?.reloadData()
            }
        }
    }

    /**
        Causes the `fetchedResultsController` to refetch the data.
        You almost certainly never need to call this.
        The `NSFetchedResultsController` class observes the context
        (so if the objects in the context change, you do not need to call `performFetch`
        since the `NSFetchedResultsController` will notice and update the collection view automatically).
        This will also automatically be called if you change the `fetchedResultsController` property.
    */
    public func performFetch() {
        if let frc = fetchedResultsController {
            var error: NSError?
            if !frc.performFetch(&error) {
                if let err = error {
                    if kAERecordPrintLog {
                        println("Error occured in \(NSStringFromClass(self.dynamicType)) - function: \(__FUNCTION__) | line: \(__LINE__)\n\(err)")
                    }
                }
            }
            collectionView?.reloadData()
        }
    }

    private var _suspendAutomaticTrackingOfChangesInManagedObjectContext: Bool = false
    /**
        Turn this on before making any changes in the managed object context that
        are a one-for-one result of the user manipulating cells directly in the collection view.
        Such changes cause the context to report them (after a brief delay),
        and normally our `fetchedResultsController` would then try to update the collection view,
        but that is unnecessary because the changes were made in the collection view already (by the user)
        so the `fetchedResultsController` has nothing to do and needs to ignore those reports.
        Turn this back off after the user has finished the change.
        Note that the effect of setting this to NO actually gets delayed slightly
        so as to ignore previously-posted, but not-yet-processed context-changed notifications,
        therefore it is fine to set this to YES at the beginning of, e.g., `collectionView:moveItemAtIndexPath:toIndexPath:`,
        and then set it back to NO at the end of your implementation of that method.
        It is not necessary (in fact, not desirable) to set this during row deletion or insertion
        (but definitely for cell moves).
    */
    public var suspendAutomaticTrackingOfChangesInManagedObjectContext: Bool {
        get {
            return _suspendAutomaticTrackingOfChangesInManagedObjectContext
        }
        set (newValue) {
            if newValue == true {
                _suspendAutomaticTrackingOfChangesInManagedObjectContext = true
            } else {
                dispatch_after(0, dispatch_get_main_queue(), { self._suspendAutomaticTrackingOfChangesInManagedObjectContext = false })
            }
        }
    }
    
    // MARK: NSFetchedResultsControllerDelegate Helpers
    
    private var sectionInserts = [Int]()
    private var sectionDeletes = [Int]()
    private var sectionUpdates = [Int]()
    
    private var objectInserts = [NSIndexPath]()
    private var objectDeletes = [NSIndexPath]()
    private var objectUpdates = [NSIndexPath]()
    private var objectMoves = [NSIndexPath]()
    private var objectReloads = NSMutableSet()
    
    private func updateSectionsAndObjects() {
        // sections
        if !self.sectionInserts.isEmpty {
            for sectionIndex in self.sectionInserts {
                self.collectionView?.insertSections(NSIndexSet(index: sectionIndex))
            }
            self.sectionInserts.removeAll(keepCapacity: true)
        }
        if !self.sectionDeletes.isEmpty {
            for sectionIndex in self.sectionDeletes {
                self.collectionView?.deleteSections(NSIndexSet(index: sectionIndex))
            }
            self.sectionDeletes.removeAll(keepCapacity: true)
        }
        if !self.sectionUpdates.isEmpty {
            for sectionIndex in self.sectionUpdates {
                self.collectionView?.reloadSections(NSIndexSet(index: sectionIndex))
            }
            self.sectionUpdates.removeAll(keepCapacity: true)
        }
        // objects
        if !self.objectInserts.isEmpty {
            self.collectionView?.insertItemsAtIndexPaths(self.objectInserts)
            self.objectInserts.removeAll(keepCapacity: true)
        }
        if !self.objectDeletes.isEmpty {
            self.collectionView?.deleteItemsAtIndexPaths(self.objectDeletes)
            self.objectDeletes.removeAll(keepCapacity: true)
        }
        if !self.objectUpdates.isEmpty {
            self.collectionView?.reloadItemsAtIndexPaths(self.objectUpdates)
            self.objectUpdates.removeAll(keepCapacity: true)
        }
        if !self.objectMoves.isEmpty {
            let moveOperations = objectMoves.count / 2
            var index = 0
            for i in 0 ..< moveOperations {
                self.collectionView?.moveItemAtIndexPath(self.objectMoves[index], toIndexPath: self.objectMoves[index + 1])
                index = index + 2
            }
            self.objectMoves.removeAll(keepCapacity: true)
        }
    }
    
    // MARK: NSFetchedResultsControllerDelegate
    
    /**
        Notifies the receiver of the addition or removal of a section.
        
        :param: controller The fetched results controller that sent the message.
        :param: sectionInfo The section that changed.
        :param: sectionIndex The index of the changed section.
        :param: type The type of change (insert or delete).
    */
    public func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            sectionInserts.append(sectionIndex)
        case .Delete:
            sectionDeletes.append(sectionIndex)
        case .Update:
            sectionUpdates.append(sectionIndex)
        default:
            break
        }
    }
    
    /**
        Notifies the receiver that a fetched object has been changed due to an add, remove, move, or update.
        
        :param: controller The fetched results controller that sent the message.
        :param: anObject The object in controller’s fetched results that changed.
        :param: indexPath The index path of the changed object (this value is nil for insertions).
        :param: type The type of change.
        :param: newIndexPath The destination path for the object for insertions or moves (this value is nil for a deletion).
    */
    public func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            objectInserts.append(newIndexPath!)
        case .Delete:
            objectDeletes.append(indexPath!)
        case .Update:
            objectUpdates.append(indexPath!)
        case .Move:
            objectMoves.append(indexPath!)
            objectMoves.append(newIndexPath!)
            objectReloads.addObject(indexPath!)
            objectReloads.addObject(newIndexPath!)
        }
    }

    /**
        Notifies the receiver that the fetched results controller has completed processing of one or more changes due to an add, remove, move, or update.
        
        :param: controller The fetched results controller that sent the message.
    */
    public func controllerDidChangeContent(controller: NSFetchedResultsController) {
        if !suspendAutomaticTrackingOfChangesInManagedObjectContext {
            // do batch updates on collection view
            collectionView?.performBatchUpdates({ () -> Void in
                self.updateSectionsAndObjects()
            }, completion: { (finished) -> Void in
                // reload moved items when finished
                if self.objectReloads.count > 0 {
                    self.collectionView?.reloadItemsAtIndexPaths(self.objectReloads.allObjects)
                    self.objectReloads.removeAllObjects()
                }
            })
        }
    }
    
    // MARK: UICollectionViewDataSource
    
    /**
        Asks the data source for the number of sections in the collection view.
    
        :param: collectionView An object representing the collection view requesting this information.
    
        :returns: The number of sections in collectionView.
    */
    override public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return fetchedResultsController?.sections?.count ?? 0
    }
    
    /**
        Asks the data source for the number of items in the specified section. (required)
    
        :param: collectionView An object representing the collection view requesting this information.
        :param: section An index number identifying a section in collectionView.
    
        :returns: The number of rows in section.
    */
    override public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (fetchedResultsController?.sections?[section] as? NSFetchedResultsSectionInfo)?.numberOfObjects ?? 0
    }
    
}