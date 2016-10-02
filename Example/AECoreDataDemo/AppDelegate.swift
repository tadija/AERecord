//
//  AppDelegate.swift
//  AECoreDataDemo
//
//  Created by Marko Tadic on 11/3/14.
//  Copyright (c) 2014 ae. All rights reserved.
//

import UIKit
import AERecord

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        
        do {
            try AERecord.loadCoreDataStack()
        } catch {
            debugPrint(error)
        }
        
        return true
    }

}
