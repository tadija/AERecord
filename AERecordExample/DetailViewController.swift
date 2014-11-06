//
//  DetailViewController.swift
//  AERecordExample
//
//  Created by Marko Tadic on 11/3/14.
//  Copyright (c) 2014 ae. All rights reserved.
//

import UIKit
import CoreData

class DetailViewController: CoreDataCollectionViewController {
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup buttons
        let optionsButton = UIBarButtonItem(title: "Options", style: .Plain, target: self, action: "showOptions:")
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
            for i in 1...5 {
                Event.createWithAttributes(["timeStamp" : NSDate()])
            }
            AERecord.saveContextAndWait()
        }
        
        let deleteAllAction = UIAlertAction(title: "Delete All", style: .Destructive) { (action) -> Void in
            // delete all objects
            Event.deleteAll()
            AERecord.saveContextAndWait()
        }
        
        let updateAllAction = UIAlertAction(title: "Update All", style: .Default) { (action) -> Void in
            // update all objects
            if let events = Event.all() as? [Event] {
                for e in events {
                    e.timeStamp = NSDate()
                }
                AERecord.saveContextAndWait()
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
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as CustomCollectionViewCell
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: CustomCollectionViewCell, atIndexPath indexPath: NSIndexPath) {
        if let frc = fetchedResultsController {
            if let object = frc.objectAtIndexPath(indexPath) as? Event {
                cell.backgroundColor = UIColor(red: 0.918, green: 0.969, blue: 0.984, alpha: 1)
                cell.textLabel.text = object.timeStamp.description
            }
        }
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? CustomCollectionViewCell {
            // update value
            if let frc = fetchedResultsController {
                if let object = frc.objectAtIndexPath(indexPath) as? Event {
                    cell.backgroundColor = UIColor(red: 0.969, green: 0.984, blue: 0.745, alpha: 1)
                    object.timeStamp = NSDate()
                    AERecord.saveContextAndWait()
                }
            }
        }
    }

}

