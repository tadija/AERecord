//
// AEStack.swift
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

/// This internal class is core of AERecord as it configures and accesses Core Data Stack.
class AEStack {
    
    // MARK: - Shared Instance
    
    static let shared = AEStack()
    
    // MARK: - Default settings
    
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
    
    // MARK: - Properties
    
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
    
    // MARK: - Configure Stack
    
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
        options: [AnyHashable : Any]? = nil) throws {
        
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
    
    func truncateAllData(context: NSManagedObjectContext) {
        if let mom = managedObjectModel {
            for entity in mom.entities {
                if let entityType = NSClassFromString(entity.managedObjectClassName) as? NSManagedObject.Type {
                    entityType.deleteAll(context: context)
                }
            }
        }
    }
    
    deinit {
        stopReceivingContextNotifications()
    }
    
    // MARK: - Context Operations
    
    func executeFetchRequest<T: NSManagedObject>(_ request: NSFetchRequest<T>, context: NSManagedObjectContext? = nil) -> [T] {
        var fetchedObjects = [T]()
        let moc = context ?? defaultContext
        moc.performAndWait {
            do {
                fetchedObjects = try moc.fetch(request)
            } catch {
                print(error)
            }
        }
        return fetchedObjects
    }
    
    func saveContext(_ context: NSManagedObjectContext? = nil) {
        let moc = context ?? defaultContext
        moc.perform {
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
        moc.performAndWait {
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
        context.perform {
            context.mergeChanges(fromContextDidSave: notification)
        }
    }
    
    class func refreshObjects(objectIDS: [NSManagedObjectID], mergeChanges: Bool, context: NSManagedObjectContext = AERecord.Context.default) {
        for objectID in objectIDS {
            context.performAndWait {
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
    
    class func refreshAllRegisteredObjects(mergeChanges: Bool, context: NSManagedObjectContext = AERecord.Context.default) {
        var registeredObjectIDS = [NSManagedObjectID]()
        for object in context.registeredObjects {
            registeredObjectIDS.append(object.objectID)
        }
        refreshObjects(objectIDS: registeredObjectIDS, mergeChanges: mergeChanges)
    }
    
    // MARK: - Notifications
    
    func startReceivingContextNotifications() {
        let center = NotificationCenter.default
        
        // Context Sync
        center.addObserver(self, selector: #selector(AEStack.contextDidSave(_:)), name: .NSManagedObjectContextDidSave, object: mainContext)
        center.addObserver(self, selector: #selector(AEStack.contextDidSave(_:)), name: .NSManagedObjectContextDidSave, object: backgroundContext)
        
        // iCloud Support
        center.addObserver(self, selector: #selector(AEStack.storesWillChange(_:)), name: .NSPersistentStoreCoordinatorStoresWillChange, object: persistentStoreCoordinator)
        center.addObserver(self, selector: #selector(AEStack.storesDidChange(_:)), name: .NSPersistentStoreCoordinatorStoresDidChange, object: persistentStoreCoordinator)
        center.addObserver(self, selector: #selector(AEStack.willRemoveStore(_:)), name: .NSPersistentStoreCoordinatorWillRemoveStore, object: persistentStoreCoordinator)
        #if !(os(tvOS) || os(watchOS))
            center.addObserver(self, selector: #selector(AEStack.persistentStoreDidImportUbiquitousContentChanges(_:)), name: .NSPersistentStoreDidImportUbiquitousContentChanges, object: persistentStoreCoordinator)
        #endif
    }
    
    func stopReceivingContextNotifications() {
        let center = NotificationCenter.default
        center.removeObserver(self)
    }
    
    @objc func contextDidSave(_ notification: Notification) {
        if let context = notification.object as? NSManagedObjectContext {
            let contextToRefresh = context == mainContext ? backgroundContext : mainContext
            mergeChangesFromNotification(notification, inContext: contextToRefresh!)
        }
    }
    
    // MARK: - iCloud Support
    
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
