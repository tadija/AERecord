//
//  AppDelegate.swift
//  AERecordExample
//
//  Created by Marko Tadic on 11/3/14.
//  Copyright (c) 2014 ae. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        do {
            // setup CoreData stack with default options
            try AERecord.loadCoreDataStack()
        } catch {
            print(error)
        }
        
        return true
    }

}