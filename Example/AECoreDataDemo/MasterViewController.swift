//
//  MasterViewController.swift
//  AECoreDataDemo
//
//  Created by Marko Tadic on 11/3/14.
//  Copyright (c) 2014 ae. All rights reserved.
//

import AERecord
import AECoreDataUI

class MasterViewController: CoreDataTableViewController, UISplitViewControllerDelegate {
    
    private var collapseDetailViewController = true

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        splitViewController?.delegate = self
        
        // setup row height
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension

        // setup buttons
        self.navigationItem.leftBarButtonItem = self.editButtonItem()
        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(MasterViewController.insertNewObject(_:)))
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
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }

    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        if let frc = fetchedResultsController {
            if let event = frc.objectAtIndexPath(indexPath) as? Event {
                // set data
                cell.textLabel?.text = event.timeStamp.description
                cell.accessoryType = event.selected ? .Checkmark : .None
                
                // set highlight color
                let highlightColorView = UIView()
                highlightColorView.backgroundColor = yellow
                cell.selectedBackgroundView = highlightColorView
                cell.textLabel?.highlightedTextColor = UIColor.darkGrayColor()
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
            if let event = fetchedResultsController?.objectAtIndexPath(indexPath) as? Event {
                event.deleteFromContext()
                AERecord.saveContext()
            }
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // update value
        if let frc = fetchedResultsController {
            if let event = frc.objectAtIndexPath(indexPath) as? Event {
                // deselect previous / select current
                if let previous: Event = Event.firstWithAttribute("selected", value: true) {
                    previous.selected = false
                }
                event.selected = true
                AERecord.saveContextAndWait()
            }
        }
    }
    
    // MARK: - UISplitViewControllerDelegate
    
    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController: UIViewController, ontoPrimaryViewController primaryViewController: UIViewController) -> Bool {
        return collapseDetailViewController
    }

}
