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
    open class var defaultContext: NSManagedObjectContext { return AEStack.shared.defaultContext }
    
    /// Managed object context for main thread.
    open class var mainContext: NSManagedObjectContext { return AEStack.shared.mainContext }
    
    /// Managed object context for background thread.
    open class var backgroundContext: NSManagedObjectContext { return AEStack.shared.backgroundContext }
    
    /// Persistent Store Coordinator for current stack.
    open class var persistentStoreCoordinator: NSPersistentStoreCoordinator? { return AEStack.shared.persistentStoreCoordinator }
    
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
        options: [AnyHashable : Any]? = nil) throws {
        try AEStack.shared.loadCoreDataStack(managedObjectModel: managedObjectModel, storeType: storeType, configuration: configuration, storeURL: storeURL, options: options)
    }
    
    /**
        Destroys Core Data Stack for given store URL *(stop notifications, reset contexts, remove persistent store and delete .sqlite file)*. **This action can't be undone.**
    
        :param: storeURL Store URL for stack to destroy.
    
        :returns: Throws error if something went wrong.
    */
    open class func destroyCoreDataStack(storeURL: URL = AEStack.defaultURL) throws {
        try AEStack.shared.destroyCoreDataStack(storeURL: storeURL)
    }
    
    /**
        Deletes all records from all entities contained in the model.
    
        :param: context If not specified, `defaultContext` will be used.
    */
    open class func truncateAllData(context: NSManagedObjectContext? = nil) {
        AEStack.shared.truncateAllData(context: context)
    }
    
    // MARK: Context Execute
    
    /**
        Executes given fetch request.
    
        :param: request Fetch request to execute.
        :param: context If not specified, `defaultContext` will be used.
    */
    open class func executeFetchRequest<T: NSManagedObject>(_ request: NSFetchRequest<T>, context: NSManagedObjectContext? = nil) -> [T] {
        return AEStack.shared.executeFetchRequest(request, context: context)
    }
    
    // MARK: Context Save
    
    /**
        Saves context *(without waiting - returns immediately)*.
    
        :param: context If not specified, `defaultContext` will be used.
    */
    open class func saveContext(_ context: NSManagedObjectContext? = nil) {
        AEStack.shared.saveContext(context)
    }
    
    /**
        Saves context with waiting *(returns when context is saved)*.
        
        :param: context If not specified, `defaultContext` will be used.
    */
    open class func saveContextAndWait(_ context: NSManagedObjectContext? = nil) {
        AEStack.shared.saveContextAndWait(context)
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
