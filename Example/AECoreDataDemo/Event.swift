//
//  Event.swift
//  AECoreDataDemo
//
//  Created by Marko Tadic on 11/4/14.
//  Copyright (c) 2014 ae. All rights reserved.
//

import Foundation
import CoreData

class Event: NSManagedObject {

    @NSManaged var timeStamp: NSDate
    @NSManaged var selected: Bool

}
