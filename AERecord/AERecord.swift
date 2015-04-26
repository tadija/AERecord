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
public class AERecord {
    
    // MARK: Properties
    
    public class var defaultContext: NSManagedObjectContext { return AEStack.sharedInstance.defaultContext } // context for current thread
    public class var mainContext: NSManagedObjectContext { return AEStack.sharedInstance.mainContext } // context for main thread
    public class var backgroundContext: NSManagedObjectContext { return AEStack.sharedInstance.backgroundContext } // context for background thread
    
    public class var persistentStoreCoordinator: NSPersistentStoreCoordinator? { return AEStack.sharedInstance.persistentStoreCoordinator }
    
    // MARK: Setup Stack
    
    public class func storeURLForName(name: String) -> NSURL {
        return AEStack.storeURLForName(name)
    }
    
    public class func loadCoreDataStack(managedObjectModel: NSManagedObjectModel = AEStack.defaultModel, storeType: String = NSSQLiteStoreType, configuration: String? = nil, storeURL: NSURL = AEStack.defaultURL, options: [NSObject : AnyObject]? = nil) -> NSError? {
        return AEStack.sharedInstance.loadCoreDataStack(managedObjectModel: managedObjectModel, storeType: storeType, configuration: configuration, storeURL: storeURL, options: options)
    }
    
    public class func destroyCoreDataStack(storeURL: NSURL = AEStack.defaultURL) {
        AEStack.sharedInstance.destroyCoreDataStack(storeURL: storeURL)
    }
    
    public class func truncateAllData(context: NSManagedObjectContext? = nil) {
        AEStack.sharedInstance.truncateAllData(context: context)
    }
    
    // MARK: Context Execute
    
    public class func executeFetchRequest(request: NSFetchRequest, context: NSManagedObjectContext? = nil) -> [NSManagedObject] {
        return AEStack.sharedInstance.executeFetchRequest(request, context: context)
    }
    
    // MARK: Context Save
    
    public class func saveContext(context: NSManagedObjectContext? = nil) {
        AEStack.sharedInstance.saveContext(context: context)
    }
    
    public class func saveContextAndWait(context: NSManagedObjectContext? = nil) {
        AEStack.sharedInstance.saveContextAndWait(context: context)
    }
    
    // MARK: Context Faulting Objects
    
    public class func refreshObjects(#objectIDS: [NSManagedObjectID], mergeChanges: Bool, context: NSManagedObjectContext = AERecord.defaultContext) {
        AEStack.refreshObjects(objectIDS: objectIDS, mergeChanges: mergeChanges, context: context)
    }
    
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
public extension NSManagedObject {
    
    // MARK: General
    
    class var entityName: String {
        var name = NSStringFromClass(self)
        name = name.componentsSeparatedByString(".").last
        return name
    }
    
    class var entity: NSEntityDescription? {
        return NSEntityDescription.entityForName(entityName, inManagedObjectContext: AERecord.defaultContext)
    }
    
    class func createFetchRequest(predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) -> NSFetchRequest {
        // create request
        let request = NSFetchRequest(entityName: entityName)
        // set request parameters
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        return request
    }
    
    // MARK: Creating
    
    class func create(context: NSManagedObjectContext = AERecord.defaultContext) -> Self {
        let entityDescription = NSEntityDescription.entityForName(entityName, inManagedObjectContext: context)
        let object = self(entity: entityDescription!, insertIntoManagedObjectContext: context)
        return object
    }
    
    class func createWithAttributes(attributes: [NSObject : AnyObject], context: NSManagedObjectContext = AERecord.defaultContext) -> Self {
        let object = create(context: context)
        if attributes.count > 0 {
            object.setValuesForKeysWithDictionary(attributes)
        }
        return object
    }
    
    class func firstOrCreateWithAttribute(attribute: String, value: AnyObject, context: NSManagedObjectContext = AERecord.defaultContext) -> NSManagedObject {
        let predicate = NSPredicate(format: "%K = %@", argumentArray: [attribute, value])
        let request = createFetchRequest(predicate: predicate)
        request.fetchLimit = 1
        let objects = AERecord.executeFetchRequest(request, context: context)
        return objects.first ?? createWithAttributes([attribute : value], context: context)
    }
    
    // MARK: Deleting
    
    func delete(context: NSManagedObjectContext = AERecord.defaultContext) {
        context.deleteObject(self)
    }
    
    class func deleteAll(context: NSManagedObjectContext = AERecord.defaultContext) {
        if let objects = self.all(context: context) {
            for object in objects {
                context.deleteObject(object)
            }
        }
    }
    
    class func deleteAllWithPredicate(predicate: NSPredicate, context: NSManagedObjectContext = AERecord.defaultContext) {
        if let objects = self.allWithPredicate(predicate, context: context) {
            for object in objects {
                context.deleteObject(object)
            }
        }
    }
    
    class func deleteAllWithAttribute(attribute: String, value: AnyObject, context: NSManagedObjectContext = AERecord.defaultContext) {
        if let objects = self.allWithAttribute(attribute, value: value, context: context) {
            for object in objects {
                context.deleteObject(object)
            }
        }
    }
    
    // MARK: Finding First
    
    class func first(sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> NSManagedObject? {
        let request = createFetchRequest(sortDescriptors: sortDescriptors)
        request.fetchLimit = 1
        let objects = AERecord.executeFetchRequest(request, context: context)
        return objects.first ?? nil
    }
    
    class func firstWithPredicate(predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> NSManagedObject? {
        let request = createFetchRequest(predicate: predicate, sortDescriptors: sortDescriptors)
        request.fetchLimit = 1
        let objects = AERecord.executeFetchRequest(request, context: context)
        return objects.first ?? nil
    }
    
    class func firstWithAttribute(attribute: String, value: AnyObject, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> NSManagedObject? {
        let predicate = NSPredicate(format: "%K = %@", argumentArray: [attribute, value])
        return firstWithPredicate(predicate, sortDescriptors: sortDescriptors, context: context)
    }
    
    class func firstOrderedByAttribute(name: String, ascending: Bool = true, context: NSManagedObjectContext = AERecord.defaultContext) -> NSManagedObject? {
        let sortDescriptors = [NSSortDescriptor(key: name, ascending: ascending)]
        return first(sortDescriptors: sortDescriptors, context: context)
    }
    
    // MARK: Finding All
    
    class func all(sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> [NSManagedObject]? {
        let request = createFetchRequest(sortDescriptors: sortDescriptors)
        let objects = AERecord.executeFetchRequest(request, context: context)
        return objects.count > 0 ? objects : nil
    }
    
    class func allWithPredicate(predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> [NSManagedObject]? {
        let request = createFetchRequest(predicate: predicate, sortDescriptors: sortDescriptors)
        let objects = AERecord.executeFetchRequest(request, context: context)
        return objects.count > 0 ? objects : nil
    }
    
    class func allWithAttribute(attribute: String, value: AnyObject, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> [NSManagedObject]? {
        let predicate = NSPredicate(format: "%K = %@", argumentArray: [attribute, value])
        return allWithPredicate(predicate, sortDescriptors: sortDescriptors, context: context)
    }
    
    // MARK: Count
    
    class func count(context: NSManagedObjectContext = AERecord.defaultContext) -> Int {
        return countWithPredicate(context: context)
    }
    
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
    
    class func countWithAttribute(attribute: String, value: AnyObject, context: NSManagedObjectContext = AERecord.defaultContext) -> Int {
        let predicate = NSPredicate(format: "%K = %@", argumentArray: [attribute, value])
        return countWithPredicate(predicate: predicate, context: context)
    }
    
    // MARK: Distinct
    
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
    
    class func distinctRecordsForAttributes(attributes: [String], predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> [Dictionary<String, AnyObject>]? {
        let request = createFetchRequest(predicate: predicate, sortDescriptors: sortDescriptors)
        
        request.resultType = .DictionaryResultType
        request.returnsDistinctResults = true
        request.propertiesToFetch = attributes
        
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
    
    func refresh(mergeChanges: Bool = true, context: NSManagedObjectContext = AERecord.defaultContext) {
        AERecord.refreshObjects(objectIDS: [objectID], mergeChanges: mergeChanges, context: context)
    }
    
    // MARK: Batch Updating
    
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
    
    class func batchUpdateAndRefreshObjects(predicate: NSPredicate? = nil, properties: [NSObject : AnyObject]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) {
        if let result = batchUpdate(predicate: predicate, properties: properties, resultType: .UpdatedObjectIDsResultType, context: context) {
            if let objectIDS = result.result as? [NSManagedObjectID] {
                AERecord.refreshObjects(objectIDS: objectIDS, mergeChanges: true, context: context)
            }
        }
    }
    
}

//  MARK: - CoreData driven UITableViewController
public class CoreDataTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    //
    //  Swift version of class originaly created for Stanford CS193p Winter 2013.
    //
    //  This class mostly just copies the code from NSFetchedResultsController's documentation page
    //  into a subclass of UITableViewController.
    //
    //  Just subclass this and set the fetchedResultsController.
    //  The only UITableViewDataSource method you'll HAVE to implement is tableView:cellForRowAtIndexPath:.
    //  And you can use the NSFetchedResultsController method objectAtIndexPath: to do it.
    //
    //  Remember that once you create an NSFetchedResultsController, you CANNOT modify its @propertys.
    //  If you want new fetch parameters (predicate, sorting, etc.),
    //  create a NEW NSFetchedResultsController and set this class's fetchedResultsController @property again.
    //
    
    // The controller (this class fetches nothing if this is not set).
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
    
    // Causes the fetchedResultsController to refetch the data.
    // You almost certainly never need to call this.
    // The NSFetchedResultsController class observes the context
    //  (so if the objects in the context change, you do not need to call performFetch
    //   since the NSFetchedResultsController will notice and update the table automatically).
    // This will also automatically be called if you change the fetchedResultsController @property.
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
    
    // Turn this on before making any changes in the managed object context that
    //  are a one-for-one result of the user manipulating rows directly in the table view.
    // Such changes cause the context to report them (after a brief delay),
    //  and normally our fetchedResultsController would then try to update the table,
    //  but that is unnecessary because the changes were made in the table already (by the user)
    //  so the fetchedResultsController has nothing to do and needs to ignore those reports.
    // Turn this back off after the user has finished the change.
    // Note that the effect of setting this to NO actually gets delayed slightly
    //  so as to ignore previously-posted, but not-yet-processed context-changed notifications,
    //  therefore it is fine to set this to YES at the beginning of, e.g., tableView:moveRowAtIndexPath:toIndexPath:,
    //  and then set it back to NO at the end of your implementation of that method.
    // It is not necessary (in fact, not desirable) to set this during row deletion or insertion
    //  (but definitely for row moves).
    private var _suspendAutomaticTrackingOfChangesInManagedObjectContext: Bool = false
    private var suspendAutomaticTrackingOfChangesInManagedObjectContext: Bool {
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
    
    public func controllerWillChangeContent(controller: NSFetchedResultsController) {
        if !suspendAutomaticTrackingOfChangesInManagedObjectContext {
            tableView.beginUpdates()
            beganUpdates = true
        }
    }
    
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
    
    public func controllerDidChangeContent(controller: NSFetchedResultsController) {
        if beganUpdates {
            tableView.endUpdates()
        }
    }
    
    // MARK: UITableViewDataSource
    
    override public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultsController?.sections?.count ?? 0
    }
    
    override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (fetchedResultsController?.sections?[section] as? NSFetchedResultsSectionInfo)?.numberOfObjects ?? 0
    }
    
    override public func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return (fetchedResultsController?.sections?[section] as? NSFetchedResultsSectionInfo)?.name
    }
    
    override public func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        return fetchedResultsController?.sectionForSectionIndexTitle(title, atIndex: index) ?? 0
    }
    
    override public func sectionIndexTitlesForTableView(tableView: UITableView) -> [AnyObject]! {
        return fetchedResultsController?.sectionIndexTitles
    }
    
}

//  MARK: - CoreData driven UICollectionViewController
public class CoreDataCollectionViewController: UICollectionViewController, NSFetchedResultsControllerDelegate {
    
    //
    //  Same concept as CoreDataTableViewController, but modified for use with UICollectionViewController.
    //
    //  This class mostly just copies the code from NSFetchedResultsController's documentation page
    //  into a subclass of UICollectionViewController.
    //
    //  Just subclass this and set the fetchedResultsController.
    //  The only UICollectionViewDataSource method you'll HAVE to implement is collectionView:cellForItemAtIndexPath.
    //  And you can use the NSFetchedResultsController method objectAtIndexPath: to do it.
    //
    //  Remember that once you create an NSFetchedResultsController, you CANNOT modify its @propertys.
    //  If you want new fetch parameters (predicate, sorting, etc.),
    //  create a NEW NSFetchedResultsController and set this class's fetchedResultsController @property again.
    //
    
    // The controller (this class fetches nothing if this is not set).
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
    
    // Causes the fetchedResultsController to refetch the data.
    // You almost certainly never need to call this.
    // The NSFetchedResultsController class observes the context
    //  (so if the objects in the context change, you do not need to call performFetch
    //   since the NSFetchedResultsController will notice and update the collection view automatically).
    // This will also automatically be called if you change the fetchedResultsController @property.
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
    
    // Turn this on before making any changes in the managed object context that
    //  are a one-for-one result of the user manipulating cells directly in the collection view.
    // Such changes cause the context to report them (after a brief delay),
    //  and normally our fetchedResultsController would then try to update the collection view,
    //  but that is unnecessary because the changes were made in the collection view already (by the user)
    //  so the fetchedResultsController has nothing to do and needs to ignore those reports.
    // Turn this back off after the user has finished the change.
    // Note that the effect of setting this to NO actually gets delayed slightly
    //  so as to ignore previously-posted, but not-yet-processed context-changed notifications,
    //  therefore it is fine to set this to YES at the beginning of, e.g., collectionView:moveItemAtIndexPath:toIndexPath:,
    //  and then set it back to NO at the end of your implementation of that method.
    // It is not necessary (in fact, not desirable) to set this during row deletion or insertion
    //  (but definitely for cell moves).
    private var _suspendAutomaticTrackingOfChangesInManagedObjectContext: Bool = false
    private var suspendAutomaticTrackingOfChangesInManagedObjectContext: Bool {
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
    
    override public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return fetchedResultsController?.sections?.count ?? 0
    }
    
    override public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (fetchedResultsController?.sections?[section] as? NSFetchedResultsSectionInfo)?.numberOfObjects ?? 0
    }
    
}