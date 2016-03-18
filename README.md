# General

**AERecord** is a [minion](http://tadija.net/public/minion.png) which consists of two pods:  
- [AERecord](https://cocoapods.org/pods/AERecord) - Super awesome Core Data wrapper in Swift (works on iOS, OSX, tvOS)  
- [AECoreDataUI](https://cocoapods.org/pods/AECoreDataUI) - Super awesome Core Data driven UI in Swift (for iOS only)  

## AERecord
**Super awesome Core Data wrapper in Swift (works on iOS, OSX, tvOS)**

>Why do we need yet another one Core Data wrapper? You tell me!  
Inspired by many different (spoiler alert) **magical** solutions, I wanted something which combines complexity and functionality just about right.
All that boilerplate code for setting up of Core Data stack, passing the right `NSManagedObjectContext` all accross the project and different threads, not to mention that boring `NSFetchRequest` boilerplates for any kind of creating or querying the data - should be less complicated now, with **AERecord**.


### Features
- Create default or custom Core Data stack **(or more stacks)** easily accessible from everywhere
- Have **[main and background contexts](http://floriankugler.com/2013/04/29/concurrent-core-data-stack-performance-shootout/)**, always **in sync**, but don't worry about it
- [CRUD](https://en.wikipedia.org/wiki/Create,_read,_update_and_delete) data in many ways with **one liners**
- **Batch update** directly in persistent store by using `NSBatchUpdateRequest`
- iCloud Support
- Covered with **unit tests**
- Covered with [docs](http://tadija.net/projects/AERecord/docs/)
- **Swift 2.2** ready

## AECoreDataUI
**Super awesome Core Data driven UI in Swift (for iOS)**

>Finally when it comes to connecting your data with the UI, the best approach is to use `NSFetchedResultsController`.
`CoreDataTableViewController` wrapper from [Stanford's CS193p](http://www.stanford.edu/class/cs193p/cgi-bin/drupal/downloads-2013-winter) is so great at it, that I've written it in Swift and made `CoreDataCollectionViewController` too in the same fashion.  


### Features
- Core Data driven **UITableViewController** (UI automatically reflects data in Core Data model)
- Core Data driven **UICollectionViewController** (UI automatically reflects data in Core Data model)
- Covered with [docs](http://tadija.net/projects/AERecord/docs/)


## Index

### About AERecordExample project
This project is made of default Master-Detail Application template with Core Data enabled,
but modified to show off some of the **AERecord** as well as **AECoreDataUI** features such as creating of Core Data stack,
using data driven tableView and collectionView, along with few simple querying.
I mean, just compare it with the default template and think about that.

- [AERecord features](#aerecord-features)
	- [Create Core Data stack](#create-core-data-stack)
	- [Context operations](#context-operations)
	- [Easy Queries](#easy-queries)
		- [General](#general)
		- [Create](#create)
		- [Find first](#find-first)
		- [Find all](#find-all)
		- [Delete](#delete)
		- [Count](#count)
		- [Distinct](#distinct)
		- [Auto increment](#auto-increment)
		- [Turn managed object into fault](#turn-managed-object-into-fault)
		- [Batch update](#batch-update)
- [AECoreDataUI features](#aecoredataui-features)
	- [Use Core Data with tableView](#use-core-data-with-tableview)
	- [Use Core Data with collectionView](#use-core-data-with-collectionview)
- [Requirements](#requirements)
- [Installation](#installation)
- [License](#license)


## AERecord features

### Create Core Data stack
Almost everything in `AERecord` is made with 'optional' parameters (which have default values if you don't specify anything).
So you can load (create if doesn't already exist) CoreData stack like this:

```swift
do {
    try AERecord.loadCoreDataStack()
} catch {
    print(error)
}
```

or like this:

```swift
let myModel: NSManagedObjectModel = AERecord.modelFromBundle(forClass: MyClass.self)
let myStoreType = NSInMemoryStoreType
let myConfiguration = ...
let myStoreURL = AERecord.storeURLForName("MyName")
let myOptions = [NSMigratePersistentStoresAutomaticallyOption : true]
do {
    try AERecord.loadCoreDataStack(managedObjectModel: myModel, storeType: myStoreType, configuration: myConfiguration, storeURL: myStoreURL, options: myOptions)
} catch {
    print(error)
}
```

or any combination of these.

If for any reason you want to completely remove your stack and start over (separate demo data stack for example) you can do it as simple as this:

```swift
do {
    AERecord.destroyCoreDataStack() // destroy deafult stack
} catch {
    print(error)
}

do {
    let demoStoreURL = AERecord.storeURLForName("Demo")
    AERecord.destroyCoreDataStack(storeURL: demoStoreURL) // destroy custom stack
} catch {
    print(error)
}
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

### Easy Queries
Easy querying helpers are created as `NSManagedObject` extension.  
All queries are called on `NSManagedObject` (or it's subclass), and `defaultContext` is used if you don't specify any (all examples below are using `defaultContext`).  
All finders have optional parameter for `NSSortDescriptor` which is not used in these examples.

#### General
If you need custom `NSFetchRequest`, you can use `createPredicateForAttributes` and `createFetchRequest`, tweak it as you wish and execute with `AERecord`.

```swift
// create request for any entity type
let attributes = ...
let predicate = NSManagedObject.createPredicateForAttributes(attributes)
let sortDescriptors = ...
let request = NSManagedObject.createFetchRequest(predicate: predicate, sortDescriptors: sortDescriptors)

// set some custom request properties
request.someProperty = someValue

// execute request and get array of entity objects
let managedObjects = AERecord.executeFetchRequest(request)
```

Of course, all of the often needed requests for creating, finding, counting or deleting entities are already there, so just keep reading.

#### Create
```swift
NSManagedObject.create() // create new object

let attributes = ...
NSManagedObject.createWithAttributes(attributes) // create new object and sets it's attributes

NSManagedObject.firstOrCreateWithAttribute("city", value: "Belgrade") // get existing object (or create new if it doesn't already exist) with given attribute

let attributes = ...
NSManagedObject.firstOrCreateWithAttributes(attributes) // get existing object (or create new if it doesn't already exist) with given attributes
```

#### Find first
```swift
NSManagedObject.first() // get first object

let predicate = ...
NSManagedObject.firstWithPredicate(predicate) // get first object with predicate

NSManagedObject.firstWithAttribute("bike", value: "KTM") // get first object with given attribute name and value

let attributes = ...
NSManagedObject.firstWithAttributes(attributes) // get first object with given attributes

NSManagedObject.firstOrderedByAttribute("speed", ascending: false) // get first object ordered by given attribute name
```

#### Find all
```swift
NSManagedObject.all() // get all objects

let predicate = ...
NSManagedObject.allWithPredicate(predicate) // get all objects with predicate

NSManagedObject.allWithAttribute("year", value: 1984) // get all objects with given attribute name and value

let attributes = ...
NSManagedObject.allWithAttributes(attributes) // get all objects with given attributes
```

#### Delete
```swift
let managedObject = ...
managedObject.delete() // delete object (call on instance)

NSManagedObject.deleteAll() // delete all objects

NSManagedObject.deleteAllWithAttribute("fat", value: true) // delete all objects with given attribute name and value

let attributes = ...
NSManagedObject.deleteAllWithAttributes(attributes) // delete all objects with given attributes

let predicate = ...
NSManagedObject.deleteAllWithPredicate(predicate) // delete all objects with given predicate
```

#### Count
```swift
NSManagedObject.count() // count all objects

let predicate = ...
NSManagedObject.countWithPredicate(predicate) // count all objects with predicate

NSManagedObject.countWithAttribute("selected", value: true) // count all objects with given attribute name and value

let attributes = ...
NSManagedObject.countWithAttributes(attributes) // count all objects with given attributes
```

#### Distinct
```swift
do {
    NSManagedObject.distinctValuesForAttribute("city") // get array of all distinct values for given attribute name
} catch {
    print(error)
}

do {
    let attributes = ["country", "city"]
    NSManagedObject.distinctRecordsForAttributes(attributes) // get dictionary with name and values of all distinct records for multiple given attributes
} catch {
    print(error)
}
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

#### Batch update
Batch updating is the 'new' feature from iOS 8. It's doing stuff directly in persistent store, so be carefull with this and read the docs first. Btw, `NSPredicate` is also optional parameter here.

```swift
NSManagedObject.batchUpdate(properties: ["timeStamp" : NSDate()]) // returns NSBatchUpdateResult?

NSManagedObject.objectsCountForBatchUpdate(properties: ["timeStamp" : NSDate()]) // returns count of updated objects

NSManagedObject.batchUpdateAndRefreshObjects(properties: ["timeStamp" : NSDate()]) // turns updated objects into faults after updating them in persistent store
```

## AECoreDataUI features

### Use Core Data with tableView
`CoreDataTableViewController` mostly just copies the code from `NSFetchedResultsController`
documentation page into a subclass of `UITableViewController`.

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


## Requirements
- Xcode 7.0+
- iOS 8.0+
- AERecord doesn't require any additional libraries for it to work.
- AERecord can be used for iOS, OSX and tvOS.
- AECoreDataUI is just for iOS.


## Installation

- Using [CocoaPods](http://cocoapods.org/):

  ```ruby
  use_frameworks!
  pod 'AERecord'
  pod 'AECoreDataUI'
  ```

- Manually:

  Just drag **AERecord.swift** and/or **AECoreDataUI.swift** into your project and start using it.


## License
AERecord is released under the MIT license. See [LICENSE](LICENSE) for details.
