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
        navigationItem.leftBarButtonItem = editButtonItem
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject(_:)))
        self.navigationItem.rightBarButtonItem = addButton
        
        // setup fetchedResultsController property
        refreshFetchedResultsController()
    }
    
    // MARK: - CoreData

    func insertNewObject(_ sender: AnyObject) {
        let id = Event.autoIncrementedInteger(for: "id")
        Event.create(with: ["id": id, "timeStamp" : NSDate()])
        AERecord.saveAndWait()
    }
    
    func refreshFetchedResultsController() {
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        let request = Event.createFetchRequest(sortDescriptors: sortDescriptors)
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request,
                                                              managedObjectContext: AERecord.Context.default,
                                                              sectionNameKeyPath: nil, cacheName: nil)
    }

    // MARK: - Table View
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }

    func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        if let frc = fetchedResultsController {
            if let event = frc.object(at: indexPath) as? Event {
                // set data
                cell.textLabel?.text = "\(event.id) | \(event.timeStamp.description)"
                cell.accessoryType = event.selected ? .checkmark : .none
                
                // set highlight color
                let highlightColorView = UIView()
                highlightColorView.backgroundColor = yellow
                cell.selectedBackgroundView = highlightColorView
                cell.textLabel?.highlightedTextColor = UIColor.darkGray
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle,
                            forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            // delete object
            if let event = fetchedResultsController?.object(at: indexPath) as? Event {
                event.delete()
                AERecord.save()
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let frc = fetchedResultsController {
            if let event = frc.object(at: indexPath) as? Event {
                // deselect previous / select current
                if let previous: Event = Event.first(with: "selected", value: true) {
                    previous.selected = false
                }
                event.selected = true
                AERecord.saveAndWait()
            }
        }
    }
    
    // MARK: - UISplitViewControllerDelegate
    
    func splitViewController(splitViewController: UISplitViewController,
                             collapseSecondaryViewController secondaryViewController: UIViewController,
                             ontoPrimaryViewController primaryViewController: UIViewController) -> Bool {
        
        return collapseDetailViewController
    }

}
