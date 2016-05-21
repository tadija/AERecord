//
//  Breed.swift
//  AERecord
//
//  Created by Marko Tadic on 7/1/15.
//  Copyright (c) 2015 ae. All rights reserved.
//

import Foundation
import CoreData

class Breed: NSManagedObject {

    @NSManaged var name: String
    @NSManaged var animals: NSSet
    @NSManaged var species: Species

}
