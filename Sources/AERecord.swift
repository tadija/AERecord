//
// AERecord.swift
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

// MARK: - AERecord (facade for shared instance of AEStack)

/**
    This class is facade for accessing shared instance of `AEStack` (private class which is all about the Core Data Stack).
*/
open class AERecord {
    
    // MARK: Properties
    
    /// Managed object context for current thread.
    open class var defaultContext: NSManagedObjectContext { return AEStack.sharedInstance.defaultContext }
    
    /// Managed object context for main thread.
    open class var mainContext: NSManagedObjectContext { return AEStack.sharedInstance.mainContext }
    
    /// Managed object context for background thread.
    open class var backgroundContext: NSManagedObjectContext { return AEStack.sharedInstance.backgroundContext }
    
    /// Persistent Store Coordinator for current stack.
    open class var persistentStoreCoordinator: NSPersistentStoreCoordinator? { return AEStack.sharedInstance.persistentStoreCoordinator }
    
    // MARK: Setup Stack
    
    /**
        Returns the final URL for the store with given name.
    
        :param: name Filename for the store.
    */
    open class func storeURLForName(_ name: String) -> URL {
        return AEStack.storeURLForName(name)
    }
    
    /**
        Returns merged model from the bundle for given class.
        
        :param: forClass Class inside bundle with data model.
    */
    open class func modelFromBundle(forClass: AnyClass) -> NSManagedObjectModel {
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
    
        :returns: Throws error if something went wrong.
    */
    open class func loadCoreDataStack(
        managedObjectModel: NSManagedObjectModel = AEStack.defaultModel,
        storeType: String = NSSQLiteStoreType,
        configuration: String? = nil,
        storeURL: URL = AEStack.defaultURL,
        options: [AnyHashable: Any]? = nil) throws {
        try AEStack.sharedInstance.loadCoreDataStack(managedObjectModel: managedObjectModel, storeType: storeType, configuration: configuration, storeURL: storeURL, options: options)
    }
    
    /**
        Destroys Core Data Stack for given store URL *(stop notifications, reset contexts, remove persistent store and delete .sqlite file)*. **This action can't be undone.**
    
        :param: storeURL Store URL for stack to destroy.
    
        :returns: Throws error if something went wrong.
    */
    open class func destroyCoreDataStack(_ storeURL: URL = AEStack.defaultURL) throws {
        try AEStack.sharedInstance.destroyCoreDataStack(storeURL: storeURL)
    }
    
    /**
        Deletes all records from all entities contained in the model.
    
        :param: context If not specified, `defaultContext` will be used.
    */
    open class func truncateAllData(_ context: NSManagedObjectContext? = nil) {
        AEStack.sharedInstance.truncateAllData(context: context)
    }
    
    // MARK: Context Execute
    
    /**
        Executes given fetch request.
    
        :param: request Fetch request to execute.
        :param: context If not specified, `defaultContext` will be used.
    */
    open class func executeFetchRequest(_ request: NSFetchRequest<NSFetchRequestResult>, context: NSManagedObjectContext? = nil) -> [NSManagedObject] {
        return AEStack.sharedInstance.executeFetchRequest(request, context: context)
    }
    
    // MARK: Context Save
    
    /**
        Saves context *(without waiting - returns immediately)*.
    
        :param: context If not specified, `defaultContext` will be used.
    */
    open class func saveContext(_ context: NSManagedObjectContext? = nil) {
        AEStack.sharedInstance.saveContext(context)
    }
    
    /**
        Saves context with waiting *(returns when context is saved)*.
        
        :param: context If not specified, `defaultContext` will be used.
    */
    open class func saveContextAndWait(_ context: NSManagedObjectContext? = nil) {
        AEStack.sharedInstance.saveContextAndWait(context)
    }
    
    // MARK: Context Faulting Objects
    
    /**
        Turns objects into faults for given Array of `NSManagedObjectID`.
    
        :param: objectIDS Array of `NSManagedObjectID` objects to turn into fault.
        :param: mergeChanges A Boolean value.
        :param: context If not specified, `defaultContext` will be used.
    */
    open class func refreshObjects(objectIDS: [NSManagedObjectID], mergeChanges: Bool, context: NSManagedObjectContext = AERecord.defaultContext) {
        AEStack.refreshObjects(objectIDS: objectIDS, mergeChanges: mergeChanges, context: context)
    }
    
    /**
        Turns all registered objects into faults.
        
        :param: mergeChanges A Boolean value.
        :param: context If not specified, `defaultContext` will be used.
    */
    open class func refreshAllRegisteredObjects(mergeChanges: Bool, context: NSManagedObjectContext = AERecord.defaultContext) {
        AEStack.refreshAllRegisteredObjects(mergeChanges: mergeChanges, context: context)
    }
    
}

// MARK: - CoreData Stack (AERecord heart:)
private class AEStack {
    
    // MARK: Shared Instance
    
    static let sharedInstance = AEStack()
    
    // MARK: Default settings
    
    class var bundleIdentifier: String {
        if let mainBundleIdentifier = Bundle.main.bundleIdentifier {
            return mainBundleIdentifier
        }
        return Bundle(for: AEStack.self).bundleIdentifier!
    }
    class var defaultURL: URL {
        return storeURLForName(bundleIdentifier)
    }
    class var defaultModel: NSManagedObjectModel {
        return NSManagedObjectModel.mergedModel(from: nil)!
    }
    
    // MARK: Properties
    
    var managedObjectModel: NSManagedObjectModel?
    var persistentStoreCoordinator: NSPersistentStoreCoordinator?
    var mainContext: NSManagedObjectContext!
    var backgroundContext: NSManagedObjectContext!
    var defaultContext: NSManagedObjectContext {
        if Thread.isMainThread {
            return mainContext
        } else {
            return backgroundContext
        }
    }
    
    // MARK: Setup Stack
    
    class var defaultSearchPath: FileManager.SearchPathDirectory {
        #if os(tvOS)
            return .CachesDirectory
        #else
            return .documentDirectory
        #endif
    }
    
    class func storeURLForName(_ name: String) -> URL {
        let fileManager = FileManager.default
        let directoryURL = fileManager.urls(for: defaultSearchPath, in: .userDomainMask).last!
        let storeName = "\(name).sqlite"
        return directoryURL.appendingPathComponent(storeName)
    }
    
    class func modelFromBundle(forClass: AnyClass) -> NSManagedObjectModel {
        let bundle = Bundle(for: forClass)
        return NSManagedObjectModel.mergedModel(from: [bundle])!
    }
    
    func loadCoreDataStack(
        managedObjectModel: NSManagedObjectModel = defaultModel,
        storeType: String = NSSQLiteStoreType,
        configuration: String? = nil,
        storeURL: URL = defaultURL,
        options: [AnyHashable: Any]? = nil) throws {
            
        self.managedObjectModel = managedObjectModel
        
        // setup main and background contexts
        mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        
        // create the coordinator and store
        persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        if let coordinator = persistentStoreCoordinator {
            try coordinator.addPersistentStore(ofType: storeType, configurationName: configuration, at: storeURL, options: options)
            mainContext.persistentStoreCoordinator = coordinator
            backgroundContext.persistentStoreCoordinator = coordinator
            startReceivingContextNotifications()
        }
    }
    
    func destroyCoreDataStack(storeURL: URL = defaultURL) throws {
        // must load this core data stack first
        do {
            try loadCoreDataStack(storeURL: storeURL) // because there is no persistentStoreCoordinator if destroyCoreDataStack is called before loadCoreDataStack
            // also if we're in other stack currently that persistentStoreCoordinator doesn't know about this storeURL
        } catch {
            throw error
        }
        stopReceivingContextNotifications() // stop receiving notifications for these contexts
        
        // reset contexts
        mainContext.reset()
        backgroundContext.reset()
        
        // finally, remove persistent store
        if let coordinator = persistentStoreCoordinator {
            if let store = coordinator.persistentStore(for: storeURL) {
                try coordinator.remove(store)
                try FileManager.default.removeItem(at: storeURL)
            }
        }
        
        // reset coordinator and model
        persistentStoreCoordinator = nil
        managedObjectModel = nil
    }
    
    func truncateAllData(context: NSManagedObjectContext? = nil) {
        let moc = context ?? defaultContext
        if let mom = managedObjectModel {
            for entity in mom.entities {
                if let entityType = NSClassFromString(entity.managedObjectClassName) as? NSManagedObject.Type {
                    entityType.deleteAll(context: moc)
                }
            }
        }
    }
    
    deinit {
        stopReceivingContextNotifications()
    }
    
    // MARK: Context Operations
    
    func executeFetchRequest(_ request: NSFetchRequest<NSFetchRequestResult>, context: NSManagedObjectContext? = nil) -> [NSManagedObject] {
        var fetchedObjects = [NSManagedObject]()
        let moc = context ?? defaultContext
        moc.performAndWait { () -> Void in
            do {
                if let managedObjects = try moc.fetch(request) as? [NSManagedObject] {
                    fetchedObjects = managedObjects
                }
            } catch {
                print(error)
            }
        }
        return fetchedObjects
    }

    func saveContext(_ context: NSManagedObjectContext? = nil) {
        let moc = context ?? defaultContext
        moc.perform { () -> Void in
            if moc.hasChanges {
                do {
                    try moc.save()
                } catch {
                    print(error)
                }
            }
        }
    }
    
    func saveContextAndWait(_ context: NSManagedObjectContext? = nil) {
        let moc = context ?? defaultContext
        moc.performAndWait { () -> Void in
            if moc.hasChanges {
                do {
                    try moc.save()
                } catch {
                    print(error)
                }
            }
        }
    }
    
    func mergeChangesFromNotification(_ notification: Notification, inContext context: NSManagedObjectContext) {
        context.perform({ () -> Void in
            context.mergeChanges(fromContextDidSave: notification)
        })
    }
    
    class func refreshObjects(objectIDS: [NSManagedObjectID], mergeChanges: Bool, context: NSManagedObjectContext = AERecord.defaultContext) {
        for objectID in objectIDS {
            context.performAndWait { () -> Void in
                do {
                    let managedObject = try context.existingObject(with: objectID)
                    // turn managed object into fault
                    context.refresh(managedObject, mergeChanges: mergeChanges)
                }
                catch {
                    print(error)
                }
            }
        }
    }
    
    class func refreshAllRegisteredObjects(mergeChanges: Bool, context: NSManagedObjectContext = AERecord.defaultContext) {
        var registeredObjectIDS = [NSManagedObjectID]()
        for object in context.registeredObjects {
            registeredObjectIDS.append(object.objectID)
        }
        refreshObjects(objectIDS: registeredObjectIDS, mergeChanges: mergeChanges)
    }
    
    // MARK: Notifications
    
    func startReceivingContextNotifications() {
        let center = NotificationCenter.default
        
        // Context Sync
        center.addObserver(self, selector: #selector(AEStack.contextDidSave(_:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: mainContext)
        center.addObserver(self, selector: #selector(AEStack.contextDidSave(_:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: backgroundContext)
        
        // iCloud Support
        center.addObserver(self, selector: #selector(AEStack.storesWillChange(_:)), name: NSNotification.Name.NSPersistentStoreCoordinatorStoresWillChange, object: persistentStoreCoordinator)
        center.addObserver(self, selector: #selector(AEStack.storesDidChange(_:)), name: NSNotification.Name.NSPersistentStoreCoordinatorStoresDidChange, object: persistentStoreCoordinator)
        center.addObserver(self, selector: #selector(AEStack.willRemoveStore(_:)), name: NSNotification.Name.NSPersistentStoreCoordinatorWillRemoveStore, object: persistentStoreCoordinator)
        #if !(os(tvOS) || os(watchOS))
            center.addObserver(self, selector: #selector(AEStack.persistentStoreDidImportUbiquitousContentChanges(_:)), name: NSNotification.Name.NSPersistentStoreDidImportUbiquitousContentChanges, object: persistentStoreCoordinator)
        #endif
    }
    
    func stopReceivingContextNotifications() {
        let center = NotificationCenter.default
        center.removeObserver(self)
    }
    
    // MARK: Context Sync
    
    @objc func contextDidSave(_ notification: Notification) {
        if let context = notification.object as? NSManagedObjectContext {
            let contextToRefresh = context == mainContext ? backgroundContext : mainContext
            mergeChangesFromNotification(notification, inContext: contextToRefresh!)
        }
    }
    
    // MARK: iCloud Support
    
    @objc func storesWillChange(_ notification: Notification) {
        saveContextAndWait()
    }
    
    @objc func storesDidChange(_ notification: Notification) {
        // Does nothing here. You should probably update your UI now.
    }
    
    @objc func willRemoveStore(_ notification: Notification) {
        // Does nothing here (for now).
    }
    
    @objc func persistentStoreDidImportUbiquitousContentChanges(_ changeNotification: Notification) {
        mergeChangesFromNotification(changeNotification, inContext: defaultContext)
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
    class func createFetchRequest(predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) -> NSFetchRequest<NSFetchRequestResult> {
        let request = NSFetchRequest(entityName: entityName) as NSFetchRequest<NSFetchRequestResult>
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        return request
    }
    
    fileprivate static let defaultPredicateType: NSCompoundPredicate.LogicalType = .and
    
    /**
        Creates predicate for given attributes and predicate type.
    
        :param: attributes Dictionary of attribute names and values.
        :param: predicateType If not specified, `.AndPredicateType` will be used.
    
        :returns: The created predicate.
    */
    class func createPredicateForAttributes(_ attributes: [AnyHashable: Any], predicateType: NSCompoundPredicate.LogicalType = defaultPredicateType) -> NSPredicate {
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
    class func createWithAttributes(_ attributes: [String : AnyObject], context: NSManagedObjectContext = AERecord.defaultContext) -> Self {
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
    class func firstOrCreateWithAttribute(_ attribute: String, value: AnyObject, context: NSManagedObjectContext = AERecord.defaultContext) -> Self {
        return _firstOrCreateWithAttribute(attribute, value: value, context: context)
    }
    
    /**
        Finds the first record for given attribute and value or creates new if the it does not exist. Generic version.

        :param: attribute Attribute name.
        :param: value Attribute value.
        :param: context If not specified, `defaultContext` will be used.

        :returns: Instance of `Self`.
    */
    fileprivate class func _firstOrCreateWithAttribute<T>(_ attribute: String, value: AnyObject, context: NSManagedObjectContext = AERecord.defaultContext) -> T {
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
    class func firstOrCreateWithAttributes(_ attributes: [String : AnyObject], predicateType: NSCompoundPredicate.LogicalType = defaultPredicateType, context: NSManagedObjectContext = AERecord.defaultContext) -> Self {
        return _firstOrCreateWithAttributes(attributes, predicateType: predicateType, context: context)
    }
    
    /**
        Finds the first record for given attributes or creates new if the it does not exist. Generic version.

        :param: attributes Dictionary of attribute names and values.
        :param: predicateType If not specified, `.AndPredicateType` will be used.
        :param: context If not specified, `defaultContext` will be used.

        :returns: Instance of `Self`.
    */
    fileprivate class func _firstOrCreateWithAttributes<T>(_ attributes: [String : AnyObject], predicateType: NSCompoundPredicate.LogicalType = defaultPredicateType, context: NSManagedObjectContext = AERecord.defaultContext) -> T {
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
    fileprivate class func _first<T>(sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> T? {
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
    fileprivate class func _firstWithPredicate<T>(_ predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> T? {
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
    class func firstWithAttribute(_ attribute: String, value: AnyObject, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> Self? {
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
    class func firstWithAttributes(_ attributes: [AnyHashable: Any], predicateType: NSCompoundPredicate.LogicalType = defaultPredicateType, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> Self? {
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
    class func allWithAttribute(_ attribute: String, value: AnyObject, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> [NSManagedObject]? {
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
    class func allWithAttribute<T>(_ attribute: String, value: AnyObject, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> [T]? {
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
    class func allWithAttributes(_ attributes: [AnyHashable: Any], predicateType: NSCompoundPredicate.LogicalType = defaultPredicateType, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> [NSManagedObject]? {
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
    class func allWithAttributes<T>(_ attributes: [AnyHashable: Any], predicateType: NSCompoundPredicate.LogicalType = defaultPredicateType, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> [T]? {
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
    class func deleteAllWithAttribute(_ attribute: String, value: AnyObject, context: NSManagedObjectContext = AERecord.defaultContext) {
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
    class func deleteAllWithAttributes(_ attributes: [AnyHashable: Any], predicateType: NSCompoundPredicate.LogicalType = defaultPredicateType, context: NSManagedObjectContext = AERecord.defaultContext) {
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
        }
        catch let error {
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
    class func countWithAttribute(_ attribute: String, value: AnyObject, context: NSManagedObjectContext = AERecord.defaultContext) -> Int {
        return countWithAttributes([attribute : value], context: context)
    }
    
    /**
        Counts all records for given attributes.
        
        :param: attributes Dictionary of attribute names and values.
        :param: predicateType If not specified, `.AndPredicateType` will be used.
        :param: context If not specified, `defaultContext` will be used.
        
        :returns: Count of records.
    */
    class func countWithAttributes(_ attributes: [AnyHashable: Any], predicateType: NSCompoundPredicate.LogicalType = defaultPredicateType, context: NSManagedObjectContext = AERecord.defaultContext) -> Int {
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
    
        :returns: Throws optional Array of `AnyObject`.
    */
    class func distinctValuesForAttribute(_ attribute: String, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) throws -> [AnyObject]? {
        var distinctValues = [AnyObject]()
        
        if let distinctRecords = try distinctRecordsForAttributes([attribute], predicate: predicate, sortDescriptors: sortDescriptors, context: context) {
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
        
        :returns: Throws optional Array of `AnyObject`.
    */
    class func distinctRecordsForAttributes(_ attributes: [String], predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) throws -> [Dictionary<String, AnyObject>]? {
        let request = createFetchRequest(predicate: predicate, sortDescriptors: sortDescriptors)
        request.resultType = .dictionaryResultType
        request.propertiesToFetch = attributes
        request.returnsDistinctResults = true
        
        var distinctRecords: [Dictionary<String, AnyObject>]?
        
        if let distinctResult = try context.fetch(request) as? [Dictionary<String, AnyObject>] {
            distinctRecords = distinctResult
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
    class func batchUpdate(predicate: NSPredicate? = nil, properties: [AnyHashable: Any]? = nil, resultType: NSBatchUpdateRequestResultType = .statusOnlyResultType, context: NSManagedObjectContext = AERecord.defaultContext) -> NSBatchUpdateResult? {
        let request = NSBatchUpdateRequest(entityName: entityName)
        request.predicate = predicate
        request.propertiesToUpdate = properties
        request.resultType = resultType

        var batchResult: NSBatchUpdateResult? = nil

        context.performAndWait { () -> Void in
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
    class func objectsCountForBatchUpdate(_ predicate: NSPredicate? = nil, properties: [AnyHashable: Any]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> Int {
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
    class func batchUpdateAndRefreshObjects(_ predicate: NSPredicate? = nil, properties: [AnyHashable: Any]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) {
        if let result = batchUpdate(predicate: predicate, properties: properties, resultType: .updatedObjectIDsResultType, context: context) {
            if let objectIDS = result.result as? [NSManagedObjectID] {
                AERecord.refreshObjects(objectIDS: objectIDS, mergeChanges: true, context: context)
            }
        }
    }
    
}
