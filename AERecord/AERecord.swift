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

import CoreData

let kAERecordPrintLog = true // this will soon be updated to Swift 2.0 error handling.

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