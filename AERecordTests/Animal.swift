//
//  Animal.swift
//  AERecord
//
//  Created by Marko Tadic on 7/1/15.
//  Copyright (c) 2015 ae. All rights reserved.
//

import Foundation
import CoreData

class Animal: NSManagedObject {

    @NSManaged var customID: Int
    @NSManaged var name: String
    @NSManaged var color: String
    @NSManaged var breed: Breed

}
