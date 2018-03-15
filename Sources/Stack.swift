/**
 *  https://github.com/tadija/AERecord
 *  Copyright (c) Marko Tadić 2014-2018
 *  Licensed under the MIT license. See LICENSE file.
 */

import CoreData

/// This internal class is core of AERecord as it configures and accesses Core Data Stack.
public class Stack {
    
    // MARK: - Singleton
    
    static let shared = Stack()
    
    // MARK: - Defaults
    
    public class var defaultModel: NSManagedObjectModel {
        return NSManagedObjectModel.mergedModel(from: nil)!
    }
    
    public class var defaultName: String {
        guard let identifier = Bundle.main.bundleIdentifier else {
            return Bundle(for: Stack.self).bundleIdentifier!
        }
        return identifier
    }
    
    public class var defaultURL: URL {
        return storeURL(for: defaultName)
    }
    
    class var defaultDirectory: FileManager.SearchPathDirectory {
        #if os(tvOS)
            return .cachesDirectory
        #else
            return .documentDirectory
        #endif
    }
    
    var defaultContext: NSManagedObjectContext {
        if Thread.isMainThread {
            return mainContext
        } else {
            return backgroundContext
        }
    }
    
    // MARK: - Properties
    
    var model: NSManagedObjectModel?
    var coordinator: NSPersistentStoreCoordinator?
    
    var mainContext: NSManagedObjectContext!
    var backgroundContext: NSManagedObjectContext!
    
    // MARK: - Stack
    
    class func storeURL(for name: String) -> URL {
        let fileManager = FileManager.default
        let directoryURL = fileManager.urls(for: defaultDirectory, in: .userDomainMask).last!
        let storeName = "\(name).sqlite"
        return directoryURL.appendingPathComponent(storeName)
    }
    
    class func modelFromBundle(for aClass: AnyClass) -> NSManagedObjectModel {
        let bundle = Bundle(for: aClass)
        return NSManagedObjectModel.mergedModel(from: [bundle])!
    }
    
    func loadCoreDataStack(managedObjectModel: NSManagedObjectModel = defaultModel,
                           storeType: String = NSSQLiteStoreType,
                           configuration: String? = nil,
                           storeURL: URL = defaultURL,
                           options: [AnyHashable : Any]? = nil) throws {
        model = managedObjectModel
        configureManagedObjectContexts()
        try configureStoreCoordinator(model: managedObjectModel,
                                      type: storeType,
                                      configuration: configuration,
                                      url: storeURL,
                                      options: options)
        startReceivingContextNotifications()
    }
    
    private func configureManagedObjectContexts() {
        mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    }
    
    private func configureStoreCoordinator(model: NSManagedObjectModel, type: String,
                                           configuration: String?, url: URL, options: [AnyHashable : Any]?) throws {
        
        coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        try coordinator?.addPersistentStore(ofType: type, configurationName: configuration, at: url, options: options)
        mainContext.persistentStoreCoordinator = coordinator
        backgroundContext.persistentStoreCoordinator = coordinator
    }
    
    func destroyCoreDataStack(storeURL: URL = defaultURL) throws {
        /// - Note: must load this core data stack first
        /// because there is no `storeCoordinator` if `destroyCoreDataStack` is called before `loadCoreDataStack`
        /// also if we're in other stack currently that `storeCoordinator` doesn't know about this `storeURL`
        try loadCoreDataStack(storeURL: storeURL)
        
        stopReceivingContextNotifications()
        resetManagedObjectContexts()
        try removePersistentStore(storeURL: storeURL)
        resetCoordinatorAndModel()
    }
    
    private func resetManagedObjectContexts() {
        mainContext.reset()
        backgroundContext.reset()
    }
    
    private func removePersistentStore(storeURL: URL) throws {
        if let store = coordinator?.persistentStore(for: storeURL) {
            try coordinator?.remove(store)
            try FileManager.default.removeItem(at: storeURL)
        }
    }
    
    private func resetCoordinatorAndModel() {
        coordinator = nil
        model = nil
    }
    
    deinit {
        stopReceivingContextNotifications()
    }
    
    // MARK: - Context
    
    func execute<T: NSManagedObject>(fetchRequest request: NSFetchRequest<T>,
                 in context: NSManagedObjectContext) -> [T] {

        var fetchedObjects = [T]()
        context.performAndWait {
            do {
                fetchedObjects = try context.fetch(request)
            } catch {
                debugPrint(error)
            }
        }
        return fetchedObjects
    }
    
    func save(context: NSManagedObjectContext) {
        context.perform {
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    debugPrint(error)
                }
            }
        }
    }
    
    func saveAndWait(context: NSManagedObjectContext) {
        context.performAndWait {
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    debugPrint(error)
                }
            }
        }
    }
    
    class func refreshObjects(with objectIDs: [NSManagedObjectID], mergeChanges: Bool,
                              in context: NSManagedObjectContext = AERecord.Context.default) {
        
        for objectID in objectIDs {
            context.performAndWait {
                do {
                    let managedObject = try context.existingObject(with: objectID)
                    // turn managed object into fault
                    context.refresh(managedObject, mergeChanges: mergeChanges)
                } catch {
                    print(error)
                }
            }
        }
    }
    
    class func refreshRegisteredObjects(mergeChanges: Bool, in context: NSManagedObjectContext) {
        let registeredObjectIDs = context.registeredObjects.map { return $0.objectID }
        refreshObjects(with: registeredObjectIDs, mergeChanges: mergeChanges, in: context)
    }
    
    func truncateAllData(in context: NSManagedObjectContext) {
        if let mom = model {
            for entity in mom.entities {
                if let entityType = NSClassFromString(entity.managedObjectClassName) as? NSManagedObject.Type {
                    entityType.deleteAll(from: context)
                }
            }
        }
    }
    
    private func mergeChanges(from notification: Notification, in context: NSManagedObjectContext) {
        context.perform {
            context.mergeChanges(fromContextDidSave: notification)
        }
    }
    
    // MARK: - Notifications
    
    func startReceivingContextNotifications() {
        let center = NotificationCenter.default
        
        // Contexts Sync
        let didSave = #selector(Stack.contextDidSave(_:))
        let didSaveName = NSNotification.Name.NSManagedObjectContextDidSave
        center.addObserver(self, selector: didSave, name: didSaveName, object: mainContext)
        center.addObserver(self, selector: didSave, name: didSaveName, object: backgroundContext)
        
        // iCloud Support
        let willChange = #selector(Stack.storesWillChange(_:))
        let willChangeName = NSNotification.Name.NSPersistentStoreCoordinatorStoresWillChange
        center.addObserver(self, selector: willChange, name: willChangeName, object: coordinator)

        let didChange = #selector(Stack.storesDidChange(_:))
        let didChangeName = NSNotification.Name.NSPersistentStoreCoordinatorStoresDidChange
        center.addObserver(self, selector: didChange, name: didChangeName, object: coordinator)

        let willRemove = #selector(Stack.willRemoveStore(_:))
        let willRemoveName = NSNotification.Name.NSPersistentStoreCoordinatorWillRemoveStore
        center.addObserver(self, selector: willRemove, name: willRemoveName, object: coordinator)
        
        #if !(os(tvOS) || os(watchOS))
            let didImport = #selector(Stack.persistentStoreDidImportUbiquitousContentChanges(_:))
            let didImportName = NSNotification.Name.NSPersistentStoreDidImportUbiquitousContentChanges
            center.addObserver(self, selector: didImport, name: didImportName, object: coordinator)
        #endif
    }
    
    func stopReceivingContextNotifications() {
        let center = NotificationCenter.default
        center.removeObserver(self)
    }
    
    // MARK: - Sync
    
    @objc func contextDidSave(_ notification: Notification) {
        guard
            let context = notification.object as? NSManagedObjectContext,
            let contextToRefresh = context == mainContext ? backgroundContext : mainContext
        else {
            return
        }
        mergeChanges(from: notification, in: contextToRefresh)
    }
    
    // MARK: - iCloud
    
    @objc
    func storesWillChange(_ notification: Notification) {
        saveAndWait(context: defaultContext)
    }
    
    @objc
    func storesDidChange(_ notification: Notification) {
        /// - Note: Nothing here. You should probably update your UI now.
    }
    
    @objc
    func willRemoveStore(_ notification: Notification) {
        /// - Note: Nothing here (for now).
    }
    
    @objc
    func persistentStoreDidImportUbiquitousContentChanges(_ changeNotification: Notification) {
        mergeChanges(from: changeNotification, in: defaultContext)
    }
    
}
