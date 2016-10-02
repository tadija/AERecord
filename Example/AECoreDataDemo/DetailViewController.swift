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
        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        navigationItem.leftItemsSupplementBackButton = true
        
        // setup options button
        let optionsButton = UIBarButtonItem(title: "Options", style: .plain, target: self, action: #selector(showOptions(_:)))
        self.navigationItem.rightBarButtonItem = optionsButton

        // setup fetchedResultsController property
        refreshFetchedResultsController()
    }
    
    // MARK: - CoreData
    
    func showOptions(_ sender: AnyObject) {

        let optionsAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        optionsAlert.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
        
        let addFewAction = UIAlertAction(title: "Add Few", style: .default) { (action) -> Void in
            // create few objects
            for _ in 1...5 {
                Event.create(with: ["timeStamp" : NSDate()])
            }
            AERecord.saveAndWait()
        }
        
        let deleteAllAction = UIAlertAction(title: "Delete All", style: .destructive) { (action) -> Void in
            // delete all objects
            Event.deleteAll()
            AERecord.saveAndWait()
        }
        
        let updateAllAction = UIAlertAction(title: "Update All", style: .default) { (action) in
            if ProcessInfo.instancesRespond(to: #selector(ProcessInfo.isOperatingSystemAtLeast)) {
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
                    AERecord.saveAndWait()
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
            self.dismiss(animated: true, completion: nil)
        }
        
        optionsAlert.addAction(addFewAction)
        optionsAlert.addAction(deleteAllAction)
        optionsAlert.addAction(updateAllAction)
        optionsAlert.addAction(cancelAction)
        
        present(optionsAlert, animated: true, completion: nil)
    }
    
    func refreshFetchedResultsController() {
        let sortDescriptors = [NSSortDescriptor(key: "timeStamp", ascending: true)]
        let request = Event.createFetchRequest(sortDescriptors: sortDescriptors)
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request,
                                                              managedObjectContext: AERecord.Context.default,
                                                              sectionNameKeyPath: nil, cacheName: nil)
    }
    
    // MARK: - Collection View
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! CustomCollectionViewCell
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(_ cell: CustomCollectionViewCell, atIndexPath indexPath: IndexPath) {
        if let frc = fetchedResultsController {
            if let event = frc.object(at: indexPath) as? Event {
                cell.backgroundColor = event.selected ? yellow : blue
                cell.textLabel.text = event.timeStamp.description
            }
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? CustomCollectionViewCell {
            // update value
            if let frc = fetchedResultsController {
                if let event = frc.object(at: indexPath) as? Event {
                    cell.backgroundColor = yellow
                    // deselect previous
                    if let previous = Event.first(with: "selected", value: true) {
                        previous.selected = false
                        AERecord.saveAndWait()
                    }
                    // select current and refresh timestamp
                    event.selected = true
                    event.timeStamp = NSDate()
                    AERecord.saveAndWait()
                }
            }
        }
    }

}
