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

/// This class is facade for accessing shared instance of `AEStack` (internal class which provides Core Data Stack).
open class AERecord {
    
    // MARK: - Properties
    
    /// Struct that holds different instances of managed object context.
    public struct Context {
        /// Managed object context for current thread.
        public static var `default`: NSManagedObjectContext { return AEStack.shared.defaultContext }
        
        /// Managed object context for main thread.
        public static var main: NSManagedObjectContext { return AEStack.shared.mainContext }
        
        /// Managed object context for background thread.
        public static var background: NSManagedObjectContext { return AEStack.shared.backgroundContext }
    }
    
    /// Persistent Store Coordinator for current stack.
    open class var storeCoordinator: NSPersistentStoreCoordinator? { return AEStack.shared.storeCoordinator }
    
    // MARK: - Stack
    
    /**
        Loads Core Data Stack (creates new if it doesn't already exist) with given options (all options are optional).
    
        - NOTE:
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
    open class func loadCoreDataStack(
        managedObjectModel: NSManagedObjectModel = AEStack.defaultModel,
        storeType: String = NSSQLiteStoreType,
        configuration: String? = nil,
        storeURL: URL = AEStack.defaultURL,
        options: [AnyHashable : Any]? = nil) throws {
        
        try AEStack.shared.loadCoreDataStack(managedObjectModel: managedObjectModel, storeType: storeType,
                                             configuration: configuration, storeURL: storeURL, options: options)
    }
    
    /**
        Destroys Core Data Stack for the given store URL (stop notifications, reset contexts,
        remove persistent store and delete .sqlite file). This action can't be undone.
    
        - parameter storeURL: Store URL for stack to destroy.
    
        - returns: Throws error if something went wrong.
    */
    open class func destroyCoreDataStack(storeURL: URL = AEStack.defaultURL) throws {
        try AEStack.shared.destroyCoreDataStack(storeURL: storeURL)
    }
    
    /**
         Returns the final URL for the store with given name.
         
         - parameter name: Filename for the store.
         
         - returns: File URL for the store with given name.
    */
    open class func storeURL(forName name: String) -> URL {
        return AEStack.storeURL(forName: name)
    }
    
    /**
         Returns merged model from the bundle for given class.
         
         - parameter forClass: Class inside bundle with data model.
         
         - returns: Merged model from the bundle for given class.
    */
    open class func modelFromBundle(for aClass: AnyClass) -> NSManagedObjectModel {
        return AEStack.modelFromBundle(for: aClass)
    }
    
    // MARK: - Context
    
    /**
        Executes given fetch request.
    
        - parameter request: Fetch request to execute.
        - parameter context: If not specified, `defaultContext` will be used.
     
        - returns: Result of executed fetch request.
    */
    open class func execute<T: NSManagedObject>(fetchRequest request: NSFetchRequest<T>,
                            inContext context: NSManagedObjectContext = Context.default) -> [T] {
        
        return AEStack.shared.execute(fetchRequest: request, inContext: context)
    }
    
    /**
        Saves context asynchronously.
    
        - parameter context: If not specified, `defaultContext` will be used.
    */
    open class func save(context: NSManagedObjectContext = Context.default) {
        AEStack.shared.save(context: context)
    }
    
    /**
        Saves context synchronously.
        
        - parameter context: If not specified, `defaultContext` will be used.
    */
    open class func saveAndWait(context: NSManagedObjectContext = Context.default) {
        AEStack.shared.saveAndWait(context: context)
    }
    
    /**
        Turns objects into faults for given Array of `NSManagedObjectID`.
    
        - parameter objectIDS: Array of `NSManagedObjectID` objects to turn into fault.
        - parameter mergeChanges: A Boolean value.
        - parameter context: If not specified, `defaultContext` will be used.
    */
    open class func refreshObjects(inContext context: NSManagedObjectContext = Context.default,
                                   objectIDs: [NSManagedObjectID], mergeChanges: Bool) {
        
        AEStack.refreshObjects(inContext: context, objectIDs: objectIDs, mergeChanges: mergeChanges)
    }
    
    /**
        Turns all registered objects into faults.
        
        - parameter mergeChanges: A Boolean value.
        - parameter context: If not specified, `defaultContext` will be used.
    */
    open class func refreshRegisteredObjects(inContext context: NSManagedObjectContext = Context.default,
                                             mergeChanges: Bool) {
        
        AEStack.refreshRegisteredObjects(inContext: context, mergeChanges: mergeChanges)
    }
    
    /**
        Deletes all records from all entities contained in the model.

        - parameter context: If not specified, `defaultContext` will be used.
    */
    open class func truncateAllData(inContext context: NSManagedObjectContext = Context.default) {
        AEStack.shared.truncateAllData(inContext: context)
    }
    
}
