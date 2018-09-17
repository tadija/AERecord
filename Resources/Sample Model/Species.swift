/**
 *  https://github.com/tadija/AERecord
 *  Copyright (c) Marko Tadić 2014-2018
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import CoreData

class Species: NSManagedObject {

    @NSManaged var name: String
    @NSManaged var breeds: NSSet

}
