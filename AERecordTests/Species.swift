//
//  Species.swift
//  AERecord
//
//  Created by Marko Tadic on 7/1/15.
//  Copyright (c) 2015 ae. All rights reserved.
//

import Foundation
import CoreData

class Species: NSManagedObject {

    @NSManaged var name: String
    @NSManaged var breeds: NSSet

}
