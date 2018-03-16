/**
 *  https://github.com/tadija/AERecord
 *  Copyright (c) Marko Tadić 2014-2018
 *  Licensed under the MIT license. See LICENSE file.
 */

import CoreData

/// This class is facade for accessing shared instance of `Stack` (internal class which provides Core Data Stack).
open class AERecord {
    
    // MARK: - Properties
    
    /// Struct that holds different instances of managed object context.
    public struct Context {
        /// Managed object context for current thread.
        public static var `default`: NSManagedObjectContext { return Stack.shared.defaultContext }
        
        /// Managed object context for main thread.
        public static var main: NSManagedObjectContext { return Stack.shared.mainContext }
        
        /// Managed object context for background thread.
        public static var background: NSManagedObjectContext { return Stack.shared.backgroundContext }
    }
    
    /// Persistent Store Coordinator for current stack.
    open class var storeCoordinator: NSPersistentStoreCoordinator? { return Stack.shared.coordinator }
    
    // MARK: - Stack
    
    /**
        Loads Core Data Stack (creates new if it doesn't already exist) with given options (all options are optional).
    
        - Note:
        Default option for `managedObjectModel` is `NSManagedObjectModel.mergedModelFromBundles(nil)!`,
        custom may be provided by using `modelFromBundle:` method.
        
        Default option for `storeType` is `NSSQLiteStoreType`
     
        Default option for `storeURL` is `bundleIdentifier + ".sqlite"` inside `applicationDocumentsDirectory`,
        custom may be provided by using `storeURLForName:` method.
    
        - parameter managedObjectModel: Managed object model for Core Data Stack.
        - parameter storeType: Store type for Persistent Store creation.
        - parameter configuration: Configuration for Persistent Store creation.
        - parameter storeURL: File URL for Persistent Store creation.
        - parameter options: Options for Persistent Store creation.
    
        - returns: Throws error if something went wrong.
    */
    open class func loadCoreDataStack(managedObjectModel: NSManagedObjectModel = Stack.defaultModel,
                                      storeType: String = NSSQLiteStoreType,
                                      configuration: String? = nil,
                                      storeURL: URL = Stack.defaultURL,
                                      options: [AnyHashable : Any]? = nil) throws {
        
        try Stack.shared.loadCoreDataStack(managedObjectModel: managedObjectModel, storeType: storeType,
                                             configuration: configuration, storeURL: storeURL, options: options)
    }
    
    /**
        Destroys Core Data Stack for the given store URL (stop notifications, reset contexts,
        remove persistent store and delete .sqlite file). This action can't be undone.
    
        - parameter storeURL: Store URL for stack to destroy.
    
        - returns: Throws error if something went wrong.
    */
    open class func destroyCoreDataStack(storeURL: URL = Stack.defaultURL) throws {
        try Stack.shared.destroyCoreDataStack(storeURL: storeURL)
    }
    
    /**
         Returns the final URL for the store with given name.
         
         - parameter name: Filename for the store.
         
         - returns: File URL for the store with given name.
    */
    open class func storeURL(for name: String) -> URL {
        return Stack.storeURL(for: name)
    }
    
    /**
         Returns merged model from the bundle for given class.
         
         - parameter aClass: Class inside bundle with data model.
         
         - returns: Merged model from the bundle for given class.
    */
    open class func modelFromBundle(for aClass: AnyClass) -> NSManagedObjectModel {
        return Stack.modelFromBundle(for: aClass)
    }
    
    // MARK: - Context
    
    /**
        Executes given fetch request.
    
        - parameter request: Fetch request to execute.
        - parameter context: If not specified, `Context.default` will be used.
     
        - returns: Result of executed fetch request.
    */
    open class func execute<T: NSManagedObject>(fetchRequest request: NSFetchRequest<T>,
                            in context: NSManagedObjectContext = Context.default) -> [T] {
        
        return Stack.shared.execute(fetchRequest: request, in: context)
    }
    
    /**
        Saves context asynchronously.
    
        - parameter context: If not specified, `Context.default` will be used.
    */
    open class func save(context: NSManagedObjectContext = Context.default) {
        Stack.shared.save(context: context)
    }
    
    /**
        Saves context synchronously.
        
        - parameter context: If not specified, `Context.default` will be used.
    */
    open class func saveAndWait(context: NSManagedObjectContext = Context.default) {
        Stack.shared.saveAndWait(context: context)
    }
    
    /**
        Turns objects into faults for given Array of `NSManagedObjectID`.
    
        - parameter context: If not specified, `Context.default` will be used.
        - parameter objectIDS: Array of `NSManagedObjectID` objects to turn into fault.
        - parameter mergeChanges: A Boolean value.
    */
    open class func refreshObjects(with objectIDs: [NSManagedObjectID], mergeChanges: Bool,
                                   in context: NSManagedObjectContext = Context.default) {
        
        Stack.refreshObjects(with: objectIDs, mergeChanges: mergeChanges, in: context)
    }
    
    /**
        Turns all registered objects into faults.
        
        - parameter context: If not specified, `Context.default` will be used.
        - parameter mergeChanges: A Boolean value.
    */
    open class func refreshRegisteredObjects(mergeChanges: Bool,
                                             in context: NSManagedObjectContext = Context.default) {
        
        Stack.refreshRegisteredObjects(mergeChanges: mergeChanges, in: context)
    }
    
    /**
        Deletes all records from all entities contained in the model.

        - parameter context: If not specified, `Context.default` will be used.
    */
    open class func truncateAllData(in context: NSManagedObjectContext = Context.default) {
        Stack.shared.truncateAllData(in: context)
    }
    
}
