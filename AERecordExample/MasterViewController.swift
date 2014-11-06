//
//  MasterViewController.swift
//  AERecordExample
//
//  Created by Marko Tadic on 11/3/14.
//  Copyright (c) 2014 ae. All rights reserved.
//

import UIKit
import CoreData

class MasterViewController: CoreDataTableViewController {

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // setup buttons
        self.navigationItem.leftBarButtonItem = self.editButtonItem()
        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
        self.navigationItem.rightBarButtonItem = addButton
        
        // setup fetchedResultsController property
        refreshFetchedResultsController()
    }
    
    // MARK: - CoreData

    func insertNewObject(sender: AnyObject) {
        // create object
        Event.createWithAttributes(["timeStamp" : NSDate()])
        AERecord.saveContextAndWait()
    }
    
    func refreshFetchedResultsController() {
        let sortDescriptors = [NSSortDescriptor(key: "timeStamp", ascending: true)]
        let request = Event.createFetchRequest(sortDescriptors: sortDescriptors)
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: AERecord.defaultContext, sectionNameKeyPath: nil, cacheName: nil)
    }

    // MARK: - Table View

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }

    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        if let frc = fetchedResultsController {
            if let object = frc.objectAtIndexPath(indexPath) as? Event {
                cell.textLabel.text = object.timeStamp.description
            }
        }
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // delete object
            if let object = fetchedResultsController?.objectAtIndexPath(indexPath) as? NSManagedObject {
                object.delete()
                AERecord.saveContext()
            }
        }
    }

}

