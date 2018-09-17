/**
 *  https://github.com/tadija/AERecord
 *  Copyright (c) Marko Tadić 2014-2018
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import CoreData

class Animal: NSManagedObject {

    @NSManaged var customID: Int
    @NSManaged var name: String
    @NSManaged var color: String
    @NSManaged var breed: Breed

}
