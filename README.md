# AERecord
**Super awesome Core Data wrapper for iOS written in Swift**


Why do we need yet another one Core Data wrapper? You tell me!

>Inspired by many different (spoiler alert) magical solutions, I needed something which combines complexity and functionality just the way I want.
All that boilerplate code for setting up of Core Data stack should be packed in one reusable and customizible line of code.
Passing the right `NSManagedObjectContext` all accross the project, different threads and stuff, shouldn't be our concern in every single project.
Not to mention that boring `NSFetchRequest` boilerplates for any kind of creating or querying the data.
Finally when it comes to connecting your data with the UI, the best approach is to use `NSFetchedResultsController`.
`CoreDataTableViewController` wrapper from [Stanford's CS193p](http://www.stanford.edu/class/cs193p/cgi-bin/drupal/downloads-2013-winter) is so great at it, that I've made `CoreDataCollectionViewController` too in the same fashion.  
So, `AERecord` should solve all of these problems for me, I hope you will like it too.


**AERecord** is a [minion](http://tadija.net/public/minion.png) which consists of these classes / extensions:  

Class | Description
------------ | -------------
`AERecord` | main public class (facade)
`AEStack` | private class which takes care of the stack
`NSManagedObject extension` | super easy data querying (and more)
`CoreDataTableViewController` | Core Data driven UITableViewController
`CoreDataCollectionViewController` | Core Data driven UICollectionViewController


## Features
- Create default or custom Core Data stack **(or more stacks)** easily accessible from everywhere
- Have **main and background contexts**, always in sync, but don't worry about it
- Create, find, count or delete data in many ways with **one liners**
- Batch updating directly in persistent store by using `NSBatchUpdateRequest` **(new in iOS 8)**
- Connect UI **(tableView or collectionView)** with Core Data, and just manage the data
- That's all folks **(for now)**


## Index
- [Examples](#examples)
  - [About AERecordExample project](#about-aerecordexample-project)
  - [Create Core Data stack](#create-core-data-stack)
  - [Context operations](#context-operations)
  - [Easy querying](#easy-querying)
  	- [General](#general)
  	- [Creating](#creating)
  	- [Deleting](#deleting)
  	- [Finding first](#finding-first)
  	- [Finding all](#finding-all)
  	- [Count](#count)
  	- [Distinct](#distinct)
  	- [Auto increment](#auto-increment)
    - [Turn managed object into fault](#turn-managed-object-into-fault)
  	- [Batch updating](#batch-updating)
  - [Use Core Data with tableView](#use-core-data-with-tableview)
  - [Use Core Data with collectionView](#use-core-data-with-collectionview)
- [API](#api)
  - [AERecord](#aerecord-class)
  - [NSManagedObject extension](#nsmanagedobject-extension)
  - [CoreDataTableViewController](#coredatatableviewcontroller)
  - [CoreDataCollectionViewController](#coredatacollectionviewcontroller)
- [Requirements](#requirements)
- [Installation](#installation)
- [License](#license)


## Examples

### About AERecordExample project
This project is made of default Master-Detail Application template with Core Data enabled,
but modified to show off some of the `AERecord` features such as creating of Core Data stack,
using data driven tableView and collectionView, along with few simple querying.  
I mean, just compare it with the default template and think about that.

### Create Core Data stack
Almost everything in `AERecord` is made with optional parameters (with default values if you don't specify anything).
So you can load (create if doesn't already exist) CoreData stack like this:

```swift
AERecord.loadCoreDataStack()
```

or like this:

```swift
let myModel: NSManagedObjectModel = ...
let myStoreType = NSInMemoryStoreType
let myConfiguration = ...
let myStoreURL = AERecord.storeURLForName("MyName")
let myOptions = [NSMigratePersistentStoresAutomaticallyOption : true]
AERecord.loadCoreDataStack(managedObjectModel: myModel, storeType: myStoreType, configuration: myConfiguration, storeURL: myStoreURL, options: myOptions)
```

or any combination of these.

If for any reason you want to completely remove your stack and start over (separate demo data stack for example) you can do it as simple as this:

```swift
AERecord.destroyCoreDataStack() // destroy deafult stack

let demoStoreURL = AERecord.storeURLForName("Demo")
AERecord.destroyCoreDataStack(storeURL: demoStoreURL) // destroy custom stack
```

Similarly you can delete all data from all entities (without messing with the stack) like this:

```swift
AERecord.truncateAllData()
```

### Context operations
Context for current thread (defaultContext) is used if you don't specify any (all examples below are using defaultContext).

```swift
// get context
AERecord.mainContext // get NSManagedObjectContext for main thread
AERecord.backgroundContext // get NSManagedObjectContext for background thread
AERecord.defaultContext // get NSManagedObjectContext for current thread

// execute NSFetchRequest
let request = ...
let managedObjects = AERecord.executeFetchRequest(request) // returns array of objects

// save context
AERecord.saveContext() // save default context
AERecord.saveContextAndWait() // save default context and wait for save to finish

// turn managed objects into faults (you don't need this often, but sometimes you do)
let objectIDS = ...
AERecord.refreshObjects(objectIDS: objectIDS, mergeChanges: true) // turn objects for given IDs into faults
AERecord.refreshAllRegisteredObjects(mergeChanges: true) // turn all registered objects into faults
```

### Easy querying
Easy querying helpers are created as NSManagedObject extension.  
All queries are called on NSManagedObject (or it's subclass), and defaultContext is used if you don't specify any (all examples below are using defaultContext).  
All finders have optional parameter for `NSSortDescriptor` which is not used in these examples.

#### General
If you need custom `NSFetchRequest`, you can use `createFetchRequest`, tweak it as you wish and execute with `AERecord`.

```swift
// create request for any entity type
let predicate = ...
let sortDescriptors = ...
let request = NSManagedObject.createFetchRequest(predicate: predicate, sortDescriptors: sortDescriptors)

// set some custom request properties
request.someProperty = someValue

// execute request and get array of entity objects
let managedObjects = AERecord.executeFetchRequest(request)
```

Of course, all of the often needed requests for creating, finding, counting or deleting entities are already there, so just keep reading.

#### Creating
```swift
NSManagedObject.create() // create new object

let attributes = ...
NSManagedObject.createWithAttributes(attributes) // create new object and sets it's attributes

NSManagedObject.firstOrCreateWithAttribute("city", value: "Belgrade") // get existing object or create new (if there's not existing object) with given attribute name and value
```

#### Deleting
```swift
let managedObject = ...
managedObject.delete() // delete object (call on instance)

NSManagedObject.deleteAll() // delete all objects

NSManagedObject.deleteAllWithAttribute("fat", value: true) // delete all objects with given attribute name and value

let predicate = ...
NSManagedObject.deleteAllWithPredicate(predicate) // delete all objects with given predicate
```

#### Finding first
```swift
NSManagedObject.first() // get first object

let predicate = ...
NSManagedObject.firstWithPredicate(predicate) // get first object with predicate

NSManagedObject.firstWithAttribute("bike", value: "KTM") // get first object with given attribute name and value

NSManagedObject.firstOrderedByAttribute("speed", ascending: false) // get first object ordered by given attribute name
```

#### Finding all
```swift
NSManagedObject.all() // get all objects

let predicate = ...
NSManagedObject.allWithPredicate(predicate) // get all objects with predicate

NSManagedObject.allWithAttribute("year", value: 1984) // get all objects with given attribute name and value
```

#### Count
```swift
NSManagedObject.count() // count all objects

let predicate = ...
NSManagedObject.countWithPredicate(predicate) // count all objects with predicate

NSManagedObject.countWithAttribute("selected", value: true) // count all objects with given attribute name and value
```

#### Distinct
```swift
NSManagedObject.distinctValuesForAttribute("city") // get array of all distinct values for given attribute name

let attributes = ["country", "city"]
NSManagedObject.distinctRecordsForAttributes(attributes) // get dictionary with name and values of all distinct records for multiple given attributes
```

#### Auto Increment
If you need to have auto incremented attribute, just create one with Int type and get next ID like this:

```swift
NSManagedObject.autoIncrementedIntegerAttribute("myCustomAutoID") // returns next ID for given attribute of Integer type
```

#### Turn managed object into fault
`NSFetchedResultsController` is designed to watch only one entity at a time, but when there is a bit more complex UI (ex. showing data from related entities too),
you sometimes have to manually refresh this related data, which can be done by turning 'watched' entity object into fault.
This is shortcut for doing just that (`mergeChanges` parameter defaults to `true`). You can read more about turning objects into faults in Core Data documentation.

```swift
let managedObject = ...
managedObject.refresh() // turns instance of managed object into fault
```

#### Batch updating
Batch updating is the new feature in iOS 8. It's doing stuff directly in persistent store, so be carefull with this and read the docs first. Btw, `NSPredicate` is also optional parameter here.

```swift
NSManagedObject.batchUpdate(properties: ["timeStamp" : NSDate()]) // returns NSBatchUpdateResult?

NSManagedObject.objectsCountForBatchUpdate(properties: ["timeStamp" : NSDate()]) // returns count of updated objects

NSManagedObject.batchUpdateAndRefreshObjects(properties: ["timeStamp" : NSDate()]) // turns updated objects into faults after updating them in persistent store
```

### Use Core Data with tableView
`CoreDataTableViewController` mostly just copies the code from `NSFetchedResultsController`
documentation page into a subclass of UITableViewController.

Just subclass it and set it's `fetchedResultsController` property.

After that you'll only have to implement `tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell` and `fetchedResultsController` will take care of other required data source methods.
It will also update `UITableView` whenever the underlying data changes (insert, delete, update, move).

#### CoreDataTableViewController Example
```swift
import UIKit
import CoreData

class MyTableViewController: CoreDataTableViewController {

	override func viewDidLoad() {
	    super.viewDidLoad()
	    
	    refreshData()
	}

	func refreshData() {
	    let sortDescriptors = [NSSortDescriptor(key: "timeStamp", ascending: true)]
	    let request = Event.createFetchRequest(sortDescriptors: sortDescriptors)
	    fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: AERecord.defaultContext, sectionNameKeyPath: nil, cacheName: nil)
	}

	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
	    let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell
	    if let frc = fetchedResultsController {
	        if let object = frc.objectAtIndexPath(indexPath) as? Event {
	            cell.textLabel.text = object.timeStamp.description
	        }
	    }
	    return cell
	}

}
```

### Use Core Data with collectionView
Same as with the tableView.


## API

### AERecord class
`class AERecord`

Property | Description
------------ | -------------
`class var defaultContext: NSManagedObjectContext` | context for current thread
`class var mainContext: NSManagedObjectContext` | context for main thread
`class var backgroundContext: NSManagedObjectContext` | context for background thread
`class var persistentStoreCoordinator: NSPersistentStoreCoordinator?` | persistent store coordinator

Setup Stack | Description
------------ | -------------
`class func storeURLForName(name: String) -> NSURL` | get complete URL for store with given name (in Application Documents Directory)
`class func loadCoreDataStack(managedObjectModel: NSManagedObjectModel = AEStack.defaultModel, storeType: String = NSSQLiteStoreType, configuration: String? = nil, storeURL: NSURL = AEStack.defaultURL, options: [NSObject : AnyObject]? = nil) -> NSError?` | You need to do this only once. `AEStack.defaultModel` is `NSManagedObjectModel.mergedModelFromBundles(nil)!` and `AEStack.defaultURL` is `bundleIdentifier + ".sqlite"` in `applicationDocumentsDirectory`.
`class func destroyCoreDataStack(storeURL: NSURL = AEStack.defaultURL)` | stop notifications, reset contexts, remove persistent store and delete .sqlite file.
`class func truncateAllData(context: NSManagedObjectContext? = nil)` | delete all data from all entities contained in the model

Context Execute | Description
------------ | -------------
`class func executeFetchRequest(request: NSFetchRequest, context: NSManagedObjectContext? = nil) -> [NSManagedObject]` | execute given fetch request (if not specified `defaultContext` is used)

Context Save | Description
------------ | -------------
`class func saveContext(context: NSManagedObjectContext? = nil)` | save context (if not specified `defaultContext` is used)
`class func saveContextAndWait(context: NSManagedObjectContext? = nil)` | save context and wait for save to finish (if not specified `defaultContext` is used)

Context Faulting Objects | Description
------------ | -------------
`class func refreshObjects(#objectIDS: [NSManagedObjectID], mergeChanges: Bool, context: NSManagedObjectContext = AERecord.defaultContext)` | turn objects into faults (for given object IDs)
`class func refreshAllRegisteredObjects(#mergeChanges: Bool, context: NSManagedObjectContext = AERecord.defaultContext)` | turn all registered objects into faults


### NSManagedObject extension
`extension NSManagedObject`

General | Description
------------ | -------------
`class var entityName: String` | used all across these helpers to reference custom `NSManagedObject` subclass. It must return correct entity name. You may override this property in your custom `NSManagedObject` subclass if needed (but it should work out of the box generally).
`class var entity: NSEntityDescription?` | NSEntityDescription object
`class func createFetchRequest(predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) -> NSFetchRequest` | create fetch request for any entity type

Creating | Description
------------ | -------------
`class func create(context: NSManagedObjectContext = AERecord.defaultContext) -> Self` | create new object
`class func createWithAttributes(attributes: [NSObject : AnyObject], context: NSManagedObjectContext = AERecord.defaultContext) -> Self` | create new object and sets it's attributes
`class func firstOrCreateWithAttribute(attribute: String, value: AnyObject, context: NSManagedObjectContext = AERecord.defaultContext) -> NSManagedObject` | get existing object or create new (if there's not existing object) with given attribute name and value

Deleting | Description
------------ | -------------
`func delete(context: NSManagedObjectContext = AERecord.defaultContext)` | delete object
`class func deleteAll(context: NSManagedObjectContext = AERecord.defaultContext)` | delete all objects
`class func deleteAllWithPredicate(predicate: NSPredicate, context: NSManagedObjectContext = AERecord.defaultContext)` | delete all objects with given attribute name and value
`class func deleteAllWithAttribute(attribute: String, value: AnyObject, context: NSManagedObjectContext = AERecord.defaultContext)` | delete all objects with given predicate

Finding first | Description
------------ | -------------
`class func first(sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> NSManagedObject?` | get first object
`class func firstWithPredicate(predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> NSManagedObject?` | get first object with predicate
`class func firstWithAttribute(attribute: String, value: AnyObject, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> NSManagedObject?` | get first object with given attribute name and value
`class func firstOrderedByAttribute(name: String, ascending: Bool = true, context: NSManagedObjectContext = AERecord.defaultContext) -> NSManagedObject?` | get first object ordered by given attribute name

Finding all | Description
------------ | -------------
`class func all(sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> [NSManagedObject]?` | get all objects
`class func allWithPredicate(predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> [NSManagedObject]?` | get all objects with predicate
`class func allWithAttribute(attribute: String, value: AnyObject, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> [NSManagedObject]?` | get all objects with given attribute name and value

Count | Description
------------ | -------------
`class func count(context: NSManagedObjectContext = AERecord.defaultContext) -> Int` | count all objects
`class func countWithPredicate(predicate: NSPredicate? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> Int` | count all objects with predicate
`class func countWithAttribute(attribute: String, value: AnyObject, context: NSManagedObjectContext = AERecord.defaultContext) -> Int` | count all objects with given attribute name and value

Distinct | Description
------------ | -------------
`class func distinctValuesForAttribute(attribute: String, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> [AnyObject]?` | get array of all distinct values for given attribute name
`class func distinctRecordsForAttributes(attributes: [String], predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> [Dictionary<String, AnyObject>]?` | get dictionary with name and values of all distinct records for multiple given attributes

Auto increment | Description
------------ | -------------
`class func autoIncrementedIntegerAttribute(attribute: String, context: NSManagedObjectContext = AERecord.defaultContext) -> Int` | get next ID for given attribute of Integer type

Turn object into fault | Description
------------ | -------------
`func refresh(mergeChanges: Bool = true, context: NSManagedObjectContext = AERecord.defaultContext)` | turn instance of managed object into fault

Batch updating | Description
------------ | -------------
`class func batchUpdate(predicate: NSPredicate? = nil, properties: [NSObject : AnyObject]? = nil, resultType: NSBatchUpdateRequestResultType = .StatusOnlyResultType, context: NSManagedObjectContext = AERecord.defaultContext) -> NSBatchUpdateResult?` | update data directly in persistent store with `NSBatchUpdateRequest` and return `NSBatchUpdateResult`
`class func objectsCountForBatchUpdate(predicate: NSPredicate? = nil, properties: [NSObject : AnyObject]? = nil, context: NSManagedObjectContext = AERecord.defaultContext) -> Int` | update data directly in persistent store with `NSBatchUpdateRequest` and return count of updated objects
`class func batchUpdateAndRefreshObjects(predicate: NSPredicate? = nil, properties: [NSObject : AnyObject]? = nil, context: NSManagedObjectContext = AERecord.defaultContext)` | update data directly in persistent store with `NSBatchUpdateRequest` and turn updated objects into faults (by using `refreshObjects`) after that
`class func refreshObjects(objectIDS: [NSManagedObjectID], mergeChanges: Bool, context: NSManagedObjectContext = AERecord.defaultContext)` | turn objects into faults (refresh in context) for given array of `NSManagedObjectID`


### CoreDataTableViewController
`class CoreDataTableViewController`

Property | Description
------------ | -------------
`var fetchedResultsController: NSFetchedResultsController?` | you must set this property
`var suspendAutomaticTrackingOfChangesInManagedObjectContext: Bool` | may be used when moving rows, explained more in comments in code

Fetching | Description
------------ | -------------
`func performFetch()` | you never have to call this directly, explained more in comments in code


### CoreDataCollectionViewController
`class CoreDataCollectionViewController`

Property | Description
------------ | -------------
`var fetchedResultsController: NSFetchedResultsController?` | you must set this property
`var suspendAutomaticTrackingOfChangesInManagedObjectContext: Bool` | may be used when moving cells, explained more in comments in code

Fetching | Description
------------ | -------------
`func performFetch()` | you never have to call this directly, explained more in comments in code


## Requirements
- Xcode 6.1+
- iOS 7.0+
- AERecord doesn't require any additional libraries for it to work.


## Installation
Just drag AERecord.swift into your project and start using it.


## License
AERecord is released under the MIT license. See [LICENSE](LICENSE) for details.
