//
// AECoreDataUI.swift
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
import UIKit

//  MARK: - CoreData driven UITableViewController

/**
    Swift version of class originaly created for **Stanford CS193p Winter 2013**.

    This class mostly just copies the code from `NSFetchedResultsController` documentation page
    into a subclass of `UITableViewController`.

    Just subclass this and set the `fetchedResultsController` property.
    The only `UITableViewDataSource` method you'll **HAVE** to implement is `tableView:cellForRowAtIndexPath:`.
    And you can use the `NSFetchedResultsController` method `objectAtIndexPath:` to do it.

    Remember that once you create an `NSFetchedResultsController`, you **CANNOT** modify its properties.
    If you want new fetch parameters (predicate, sorting, etc.),
    create a **NEW** `NSFetchedResultsController` and set this class's `fetchedResultsController` property again.
*/
public class CoreDataTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    /// The controller *(this class fetches nothing if this is not set)*.
    public var fetchedResultsController: NSFetchedResultsController? {
        didSet {
            if let frc = fetchedResultsController {
                if frc != oldValue {
                    frc.delegate = self
                    do {
                        try performFetch()
                    } catch {
                        print(error)
                    }
                }
            } else {
                tableView.reloadData()
            }
        }
    }
    
    /**
        Causes the `fetchedResultsController` to refetch the data.
        You almost certainly never need to call this.
        The `NSFetchedResultsController` class observes the context
        (so if the objects in the context change, you do not need to call `performFetch`
        since the `NSFetchedResultsController` will notice and update the table automatically).
        This will also automatically be called if you change the `fetchedResultsController` property.
    */
    public func performFetch() throws {
        if let frc = fetchedResultsController {
            defer {
                tableView.reloadData()
            }
            do {
                try frc.performFetch()
            } catch {
                throw error
            }
        }
    }
    
    private var _suspendAutomaticTrackingOfChangesInManagedObjectContext: Bool = false
    /**
        Turn this on before making any changes in the managed object context that
        are a one-for-one result of the user manipulating rows directly in the table view.
        Such changes cause the context to report them (after a brief delay),
        and normally our `fetchedResultsController` would then try to update the table,
        but that is unnecessary because the changes were made in the table already (by the user)
        so the `fetchedResultsController` has nothing to do and needs to ignore those reports.
        Turn this back off after the user has finished the change.
        Note that the effect of setting this to NO actually gets delayed slightly
        so as to ignore previously-posted, but not-yet-processed context-changed notifications,
        therefore it is fine to set this to YES at the beginning of, e.g., `tableView:moveRowAtIndexPath:toIndexPath:`,
        and then set it back to NO at the end of your implementation of that method.
        It is not necessary (in fact, not desirable) to set this during row deletion or insertion
        (but definitely for row moves).
    */
    public var suspendAutomaticTrackingOfChangesInManagedObjectContext: Bool {
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
    
    /**
        Notifies the receiver that the fetched results controller is about to start processing of one or more changes due to an add, remove, move, or update.
        
        :param: controller The fetched results controller that sent the message.
    */
    public func controllerWillChangeContent(controller: NSFetchedResultsController) {
        if !suspendAutomaticTrackingOfChangesInManagedObjectContext {
            tableView.beginUpdates()
            beganUpdates = true
        }
    }
    
    /**
        Notifies the receiver of the addition or removal of a section.
        
        :param: controller The fetched results controller that sent the message.
        :param: sectionInfo The section that changed.
        :param: sectionIndex The index of the changed section.
        :param: type The type of change (insert or delete).
    */
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
    
    /**
        Notifies the receiver that a fetched object has been changed due to an add, remove, move, or update.
        
        :param: controller The fetched results controller that sent the message.
        :param: anObject The object in controller’s fetched results that changed.
        :param: indexPath The index path of the changed object (this value is nil for insertions).
        :param: type The type of change.
        :param: newIndexPath The destination path for the object for insertions or moves (this value is nil for a deletion).
    */
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
                // TODO: fix bug when moving rows in iOS 8.3 and 8.4 - Xcode 7.0 (7A220)
                // SEE: http://stackoverflow.com/questions/31383760/ios-9-attempt-to-delete-and-reload-the-same-index-path
                tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
                tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            }
        }
    }
    
    /**
        Notifies the receiver that the fetched results controller has completed processing of one or more changes due to an add, remove, move, or update.
        
        :param: controller The fetched results controller that sent the message.
    */
    public func controllerDidChangeContent(controller: NSFetchedResultsController) {
        if beganUpdates {
            tableView.endUpdates()
        }
    }
    
    // MARK: UITableViewDataSource
    
    /**
        Asks the data source to return the number of sections in the table view.
        
        :param: tableView An object representing the table view requesting this information.
        
        :returns: The number of sections in tableView.
    */
    public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        let superNumberOfSections = super.numberOfSectionsInTableView(tableView)
        return fetchedResultsController?.sections?.count ?? superNumberOfSections
    }
    
    /**
        Tells the data source to return the number of rows in a given section of a table view. (required)
        
        :param: tableView The table-view object requesting this information.
        :param: section An index number identifying a section in tableView.
        
        :returns: The number of rows in section.
    */
    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let superNumberOfRows = super.tableView(tableView, numberOfRowsInSection: section)
        return (fetchedResultsController?.sections?[section])?.numberOfObjects ?? superNumberOfRows
    }
    
    /**
        Asks the data source for the title of the header of the specified section of the table view.
        
        :param: tableView An object representing the table view requesting this information.
        :param: section An index number identifying a section in tableView.
        
        :returns: A string to use as the title of the section header.
    */
    public override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let superTitleForHeader = super.tableView(tableView, titleForHeaderInSection: section)
        return (fetchedResultsController?.sections?[section])?.name ?? superTitleForHeader
    }
    
    /**
        Asks the data source to return the index of the section having the given title and section title index.
        
        :param: tableView An object representing the table view requesting this information.
        :param: title The title as displayed in the section index of tableView.
        :param: index An index number identifying a section title in the array returned by sectionIndexTitlesForTableView:.
        
        :returns: An index number identifying a section.
    */
    public override func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        return fetchedResultsController?.sectionForSectionIndexTitle(title, atIndex: index) ?? 0
    }
    
    /**
        Asks the data source to return the titles for the sections for a table view.
        
        :param: tableView An object representing the table view requesting this information.
        
        :returns: An array of strings that serve as the title of sections in the table view and appear in the index list on the right side of the table view.
    */
    public override func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        return fetchedResultsController?.sectionIndexTitles
    }
    
}

//  MARK: - CoreData driven UICollectionViewController

/**
    Same concept as `CoreDataTableViewController`, but modified for use with `UICollectionViewController`.

    This class mostly just copies the code from `NSFetchedResultsController` documentation page
    into a subclass of `UICollectionViewController`.

    Just subclass this and set the `fetchedResultsController`.
    The only `UICollectionViewDataSource` method you'll **HAVE** to implement is `collectionView:cellForItemAtIndexPath:`.
    And you can use the `NSFetchedResultsController` method `objectAtIndexPath:` to do it.

    Remember that once you create an `NSFetchedResultsController`, you **CANNOT** modify its properties.
    If you want new fetch parameters (predicate, sorting, etc.),
    create a **NEW** `NSFetchedResultsController` and set this class's `fetchedResultsController` property again.
*/
public class CoreDataCollectionViewController: UICollectionViewController, NSFetchedResultsControllerDelegate {
    
    /// The controller *(this class fetches nothing if this is not set)*.
    public var fetchedResultsController: NSFetchedResultsController? {
        didSet {
            if let frc = fetchedResultsController {
                if frc != oldValue {
                    frc.delegate = self
                    do {
                        try performFetch()
                    } catch {
                        print(error)
                    }
                }
            } else {
                collectionView?.reloadData()
            }
        }
    }
    
    /**
        Causes the `fetchedResultsController` to refetch the data.
        You almost certainly never need to call this.
        The `NSFetchedResultsController` class observes the context
        (so if the objects in the context change, you do not need to call `performFetch`
        since the `NSFetchedResultsController` will notice and update the collection view automatically).
        This will also automatically be called if you change the `fetchedResultsController` property.
    */
    public func performFetch() throws {
        if let frc = fetchedResultsController {
            defer {
                collectionView?.reloadData()
            }
            do {
                try frc.performFetch()
            } catch {
                throw error
            }
        }
    }
    
    private var _suspendAutomaticTrackingOfChangesInManagedObjectContext: Bool = false
    /**
        Turn this on before making any changes in the managed object context that
        are a one-for-one result of the user manipulating cells directly in the collection view.
        Such changes cause the context to report them (after a brief delay),
        and normally our `fetchedResultsController` would then try to update the collection view,
        but that is unnecessary because the changes were made in the collection view already (by the user)
        so the `fetchedResultsController` has nothing to do and needs to ignore those reports.
        Turn this back off after the user has finished the change.
        Note that the effect of setting this to NO actually gets delayed slightly
        so as to ignore previously-posted, but not-yet-processed context-changed notifications,
        therefore it is fine to set this to YES at the beginning of, e.g., `collectionView:moveItemAtIndexPath:toIndexPath:`,
        and then set it back to NO at the end of your implementation of that method.
        It is not necessary (in fact, not desirable) to set this during row deletion or insertion
        (but definitely for cell moves).
    */
    public var suspendAutomaticTrackingOfChangesInManagedObjectContext: Bool {
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
    private var objectReloads = Set<NSIndexPath>()
    
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
            for _ in 0 ..< moveOperations {
                self.collectionView?.moveItemAtIndexPath(self.objectMoves[index], toIndexPath: self.objectMoves[index + 1])
                index = index + 2
            }
            self.objectMoves.removeAll(keepCapacity: true)
        }
    }
    
    // MARK: NSFetchedResultsControllerDelegate
    
    /**
        Notifies the receiver of the addition or removal of a section.
        
        :param: controller The fetched results controller that sent the message.
        :param: sectionInfo The section that changed.
        :param: sectionIndex The index of the changed section.
        :param: type The type of change (insert or delete).
    */
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
    
    /**
        Notifies the receiver that a fetched object has been changed due to an add, remove, move, or update.
        
        :param: controller The fetched results controller that sent the message.
        :param: anObject The object in controller’s fetched results that changed.
        :param: indexPath The index path of the changed object (this value is nil for insertions).
        :param: type The type of change.
        :param: newIndexPath The destination path for the object for insertions or moves (this value is nil for a deletion).
    */
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
            objectReloads.insert(indexPath!)
            objectReloads.insert(newIndexPath!)
        }
    }
    
    /**
        Notifies the receiver that the fetched results controller has completed processing of one or more changes due to an add, remove, move, or update.
        
        :param: controller The fetched results controller that sent the message.
    */
    public func controllerDidChangeContent(controller: NSFetchedResultsController) {
        if !suspendAutomaticTrackingOfChangesInManagedObjectContext {
            // do batch updates on collection view
            collectionView?.performBatchUpdates({ () -> Void in
                self.updateSectionsAndObjects()
                }, completion: { (finished) -> Void in
                    // reload moved items when finished
                    if self.objectReloads.count > 0 {
                        self.collectionView?.reloadItemsAtIndexPaths(Array(self.objectReloads))
                        self.objectReloads.removeAll()
                    }
            })
        }
    }
    
    // MARK: UICollectionViewDataSource
    
    /**
        Asks the data source for the number of sections in the collection view.
        
        :param: collectionView An object representing the collection view requesting this information.
        
        :returns: The number of sections in collectionView.
    */
    override public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return fetchedResultsController?.sections?.count ?? 1
    }
    
    /**
        Asks the data source for the number of items in the specified section. (required)
        
        :param: collectionView An object representing the collection view requesting this information.
        :param: section An index number identifying a section in collectionView.
        
        :returns: The number of rows in section.
    */
    override public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let superNumberOfItems = super.collectionView(collectionView, numberOfItemsInSection: section)
        return (fetchedResultsController?.sections?[section])?.numberOfObjects ?? superNumberOfItems
    }
    
}
