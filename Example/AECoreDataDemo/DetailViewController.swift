//
//  DetailViewController.swift
//  AECoreDataDemo
//
//  Created by Marko Tadic on 11/3/14.
//  Copyright (c) 2014 ae. All rights reserved.
//

import AERecord
import AECoreDataUI

let yellow = UIColor(red: 0.969, green: 0.984, blue: 0.745, alpha: 1)
let blue = UIColor(red: 0.918, green: 0.969, blue: 0.984, alpha: 1)

class DetailViewController: CoreDataCollectionViewController {
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // setup UISplitViewController displayMode button
        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem()
        navigationItem.leftItemsSupplementBackButton = true
        
        // setup options button
        let optionsButton = UIBarButtonItem(title: "Options", style: .Plain, target: self, action: #selector(DetailViewController.showOptions(_:)))
        self.navigationItem.rightBarButtonItem = optionsButton

        // setup fetchedResultsController property
        refreshFetchedResultsController()
    }
    
    // MARK: - CoreData
    
    func showOptions(sender: AnyObject) {

        let optionsAlert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        optionsAlert.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
        
        let addFewAction = UIAlertAction(title: "Add Few", style: .Default) { (action) -> Void in
            // create few objects
            for _ in 1...5 {
                Event.createWithAttributes(["timeStamp" : NSDate()])
            }
            AERecord.saveContextAndWait()
        }
        
        let deleteAllAction = UIAlertAction(title: "Delete All", style: .Destructive) { (action) -> Void in
            // delete all objects
            Event.deleteAll()
            AERecord.saveContextAndWait()
        }
        
        let updateAllAction = UIAlertAction(title: "Update All", style: .Default) { (action) in
            if NSProcessInfo.instancesRespondToSelector(#selector(NSProcessInfo.isOperatingSystemAtLeastVersion(_:))) {
                // >= iOS 8
                // batch update all objects (directly in persistent store) then refresh objects in context
                Event.batchUpdateAndRefreshObjects(properties: ["timeStamp" : NSDate()])
                // note that if using NSFetchedResultsController you have to call performFetch after batch updating
                do {
                    try self.performFetch()
                } catch {
                    print(error)
                }
            } else {
                // < iOS 8
                print("Batch updating is new in iOS 8.")
                // update all objects through context
                if let events = Event.all() as? [Event] {
                    for e in events {
                        e.timeStamp = NSDate()
                    }
                    AERecord.saveContextAndWait()
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        
        optionsAlert.addAction(addFewAction)
        optionsAlert.addAction(deleteAllAction)
        optionsAlert.addAction(updateAllAction)
        optionsAlert.addAction(cancelAction)
        
        presentViewController(optionsAlert, animated: true, completion: nil)
    }
    
    func refreshFetchedResultsController() {
        let sortDescriptors = [NSSortDescriptor(key: "timeStamp", ascending: true)]
        let request = Event.createFetchRequest(sortDescriptors: sortDescriptors)
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: AERecord.defaultContext, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    // MARK: - Collection View
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! CustomCollectionViewCell
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: CustomCollectionViewCell, atIndexPath indexPath: NSIndexPath) {
        if let frc = fetchedResultsController {
            if let event = frc.objectAtIndexPath(indexPath) as? Event {
                cell.backgroundColor = event.selected ? yellow : blue
                cell.textLabel.text = event.timeStamp.description
            }
        }
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? CustomCollectionViewCell {
            // update value
            if let frc = fetchedResultsController {
                if let event = frc.objectAtIndexPath(indexPath) as? Event {
                    cell.backgroundColor = yellow
                    // deselect previous
                    if let previous = Event.firstWithAttribute("selected", value: true) {
                        previous.selected = false
                        AERecord.saveContextAndWait()
                    }
                    // select current and refresh timestamp
                    event.selected = true
                    event.timeStamp = NSDate()
                    AERecord.saveContextAndWait()
                }
            }
        }
    }

}
