//
// AERecordTests.swift
//
// Copyright (c) 2014-2016 Marko Tadić <tadija@me.com> http://tadija.net
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import XCTest
import CoreData
import AERecord

class AERecordTests: XCTestCase {
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        
        /* create Core Data stack */
        
        let model = AERecord.modelFromBundle(forClass: AERecordTests.self)
        do {
            try AERecord.loadCoreDataStack(managedObjectModel: model, storeType: NSInMemoryStoreType)
        }
        catch {
            print(error)
        }
        
        /* add dummy data */
        
        // species
        let dogs = Species.createWithAttributes(["name" : "dog"])
        let cats = Species.createWithAttributes(["name" : "cat"])
        
        // breeds
        let siberian = Breed.createWithAttributes(["name" : "Siberian", "species" : cats])
        let domestic = Breed.createWithAttributes(["name" : "Domestic", "species" : cats])
        let bullTerrier = Breed.createWithAttributes(["name" : "Bull Terrier", "species" : dogs])
        let goldenRetriever = Breed.createWithAttributes(["name" : "Golden Retriever", "species" : dogs])
        let miniatureSchnauzer = Breed.createWithAttributes(["name" : "Miniature Schnauzer", "species" : dogs])
        
        // animals
        Animal.createWithAttributes(["name" : "Tinna", "color" : "lightgray", "breed" : siberian])
        Animal.createWithAttributes(["name" : "Rose", "color" : "darkgray", "breed" : domestic])
        Animal.createWithAttributes(["name" : "Caesar", "color" : "yellow", "breed" : domestic])
        Animal.createWithAttributes(["name" : "Villy", "color" : "white", "breed" : bullTerrier])
        Animal.createWithAttributes(["name" : "Spot", "color" : "white", "breed" : bullTerrier])
        Animal.createWithAttributes(["name" : "Betty", "color" : "yellow", "breed" : goldenRetriever])
        Animal.createWithAttributes(["name" : "Kika", "color" : "black", "breed" : miniatureSchnauzer])
    }
    
    override func tearDown() {
        // TODO: improve destroy logic for NSInMemoryStoreType
        // AERecord.destroyCoreDataStack()
        
        super.tearDown()
    }
    
    // MARK: - AERecord
    
    func testDefaultContext() {
        let qualityOfServiceClass = QOS_CLASS_BACKGROUND
        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        dispatch_async(backgroundQueue, {
            let context = AERecord.defaultContext
            XCTAssertEqual(context.concurrencyType, NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType, "Should be able to return background context as default context when called from the background queue.")
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                let context = AERecord.defaultContext
                XCTAssertEqual(context.concurrencyType, NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType, "Should be able to return main context as default context when called from the main queue.")
            })
        })
    }
    
    func testMainContext() {
        let context = AERecord.mainContext
        XCTAssertEqual(context.concurrencyType, NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType, "Should be able to create main context with .MainQueueConcurrencyType")
    }
    
    func testBackgroundContext() {
        let context = AERecord.backgroundContext
        XCTAssertEqual(context.concurrencyType, NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType, "Should be able to create background context with .PrivateQueueConcurrencyType")
    }
    
    func testPersistentStoreCoordinator() {
        let coordinator = AERecord.persistentStoreCoordinator
        XCTAssertNotNil(coordinator, "Should be able to create persistent store coordinator.")
    }
    
    func testStoreURLForName() {
        let storeURL = AERecord.storeURLForName("test")
        let directoryURL = NSFileManager.defaultManager().URLsForDirectory(defaultSearchPath, inDomains: .UserDomainMask).last!
        let expectedStoreURL = directoryURL.URLByAppendingPathComponent("test.sqlite")
        XCTAssertEqual(storeURL, expectedStoreURL, "")
    }
    
    var defaultSearchPath: NSSearchPathDirectory {
        #if os(tvOS)
            return .CachesDirectory
        #else
            return .DocumentDirectory
        #endif
    }
    
    func testModelFromBundle() {
        let model = AERecord.modelFromBundle(forClass: AERecordTests.self)
        let entityNames = Array(model.entitiesByName.keys).sort()
        let expectedEntityNames = ["Animal", "Breed", "Species"]
        XCTAssertEqual(entityNames, expectedEntityNames, "Should be able to load merged model from bundle for given class.")
    }
    
    func testLoadCoreDataStack() {
        // already tested in setUp
    }
    
    func testDestroyCoreDataStack() {
        // already tested in tearDown
    }
    
    func testTruncateAllData() {
        AERecord.truncateAllData()
        let count = Animal.count() + Species.count() + Breed.count()
        XCTAssertEqual(count, 0, "Should be able to truncate all data.")
    }
    
    func testExecuteFetchRequest() {
        let predicate = Animal.createPredicateForAttributes(["color" : "lightgray"])
        let request = Animal.createFetchRequest(predicate: predicate)
        let tinna = AERecord.executeFetchRequest(request).first as? Animal
        XCTAssertEqual(tinna!.name, "Tinna", "Should be able to execute given fetch request.")
    }
    
    func testSaveContext() {
        let hasChanges = AERecord.defaultContext.hasChanges
        XCTAssertEqual(hasChanges, true, "Should have changes before saving.")
        
        AERecord.saveContext()
        
        let hasChangesAfterSaving = AERecord.defaultContext.hasChanges
        XCTAssertEqual(hasChangesAfterSaving, true, "Should still have changes after saving context without waiting.")
        
        let expectation = expectationWithDescription("Context Saving")
        let dispatchTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(1.0 * Double(NSEC_PER_SEC)))
        dispatch_after(dispatchTime, dispatch_get_main_queue(), {
            expectation.fulfill()
        })
        
        self.waitForExpectationsWithTimeout(1.0, handler: { (error) -> Void in
            let hasChangesAfterWaiting = AERecord.defaultContext.hasChanges
            XCTAssertEqual(hasChangesAfterWaiting, false, "Should not have changes after waiting a bit, because context is now saved.")
        })
    }
    
    func testSaveContextAndWait() {
        let hasChanges = AERecord.defaultContext.hasChanges
        XCTAssertEqual(hasChanges, true, "Should have changes before saving.")
        
        AERecord.saveContextAndWait()
        
        let hasChangesAfterSaving = AERecord.defaultContext.hasChanges
        XCTAssertEqual(hasChangesAfterSaving, false, "Should not have changes after saving context with waiting.")
    }
    
    func testRefreshObjects() {
        // not sure how to test this in NSInMemoryStoreType
    }
    
    func testRefreshAllRegisteredObjects() {
        // not sure how to test this in NSInMemoryStoreType
    }
    
    // MARK: - NSManagedObject Extension
    
    // MARK: General
    
    func testEntityName() {
        XCTAssertEqual(Animal.entityName, "Animal", "Should be able to get name of the entity.")
    }
    
    func testEntity() {
        let animalAttributesCount = Animal.entity?.attributesByName.count
        XCTAssertEqual(animalAttributesCount!, 3, "Should be able to get NSEntityDescription of the entity.")
    }
    
    func testCreateFetchRequest() {
        let request = Animal.createFetchRequest()
        XCTAssertEqual(request.entityName!, "Animal", "Should be able to create fetch request for entity.")
    }
    
    func testCreatePredicateForAttributes() {
        let attributes = ["name" : "Tinna", "color" : "lightgray"]
        let predicate = Animal.createPredicateForAttributes(attributes)
        XCTAssertTrue(predicate.predicateFormat.containsString("name == \"Tinna\""), "Created predicate should contain condition for 'name'.")
        XCTAssertTrue(predicate.predicateFormat.containsString(" AND "), "Created predicate should contain AND.")
        XCTAssertTrue(predicate.predicateFormat.containsString("color == \"lightgray\""), "Created predicate should contain condition for 'color'.")
    }
    
    // MARK: Create
    
    func testCreate() {
        let animal = Animal.create()
        XCTAssertEqual(animal.self, animal, "Should be able to create instance of entity.")
    }
    
    func testCreateWithAttributes() {
        let attributes = ["name" : "Tinna", "color" : "lightgray"]
        let tinna = Animal.createWithAttributes(attributes)
        XCTAssertEqual(tinna.color, "lightgray", "Should be able to create instance of entity with attributes.")
    }
    
    // MARK: Find First or Create
    
    func testFirstOrCreateWithAttribute() {
        let snoopy = Animal.firstOrCreateWithAttribute("name", value: "Snoopy")
        XCTAssertEqual(snoopy.name, "Snoopy", "Should be able to create record if it doesn't already exist.")
        
        let tinna = Animal.firstOrCreateWithAttribute("name", value: "Tinna")
        XCTAssertEqual(tinna.color, "lightgray", "Should be able to return the first record with given attribute.")
    }
    
    func testFirstOrCreateWithAttributeGeneric() {
        let snoopy: Animal = Animal.firstOrCreateWithAttribute("name", value: "Snoopy")
        XCTAssertEqual(snoopy.name, "Snoopy", "Should be able to create record if it doesn't already exist.")
        
        let tinna: Animal = Animal.firstOrCreateWithAttribute("name", value: "Tinna")
        XCTAssertEqual(tinna.color, "lightgray", "Should be able to return the first record with given attribute.")
    }
    
    func testFirstOrCreateWithAttributes() {
        let snoopyAttributes = ["name" : "Snoopy", "color" : "white"]
        let snoopy = Animal.firstOrCreateWithAttributes(snoopyAttributes)
        XCTAssertEqual(snoopy.color, "white", "Should be able to create record if it doesn't already exist.")
        
        let tinnaAttributes = ["name" : "Tinna", "color" : "lightgray"]
        let tinna = Animal.firstOrCreateWithAttributes(tinnaAttributes)
        XCTAssertEqual(tinna.color, "lightgray", "Should be able to return the first record with given attributes.")
    }
    
    func testFirstOrCreateWithAttributesGeneric() {
        let snoopyAttributes = ["name" : "Snoopy", "color" : "white"]
        let snoopy: Animal = Animal.firstOrCreateWithAttributes(snoopyAttributes)
        XCTAssertEqual(snoopy.color, "white", "Should be able to create record if it doesn't already exist.")
        
        let tinnaAttributes = ["name" : "Tinna", "color" : "lightgray"]
        let tinna: Animal = Animal.firstOrCreateWithAttributes(tinnaAttributes)
        XCTAssertEqual(tinna.color, "lightgray", "Should be able to return the first record with given attributes.")
    }
    
    // MARK: Find First
    
    func testFirst() {
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        let firstAnimal = Animal.first(sortDescriptors: [sortDescriptor])
        XCTAssertEqual(firstAnimal?.name, "Betty", "Should be able to return the first record sorted by given sort descriptor.")
    }
    
    func testFirstGeneric() {
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        let firstAnimal = Animal.first(sortDescriptors: [sortDescriptor])
        XCTAssertEqual(firstAnimal?.name, "Betty", "Should be able to return the first record sorted by given sort descriptor.")
    }
    
    func testFirstWithPredicate() {
        let predicate = NSPredicate(format: "color == %@", "lightgray")
        let tinna = Animal.firstWithPredicate(predicate)
        XCTAssertEqual(tinna?.name, "Tinna", "Should be able to return the first record for given predicate.")
    }
    
    func testFirstWithPredicateGeneric() {
        let predicate = NSPredicate(format: "color == %@", "lightgray")
        let tinna: Animal = Animal.firstWithPredicate(predicate)!
        XCTAssertEqual(tinna.name, "Tinna", "Should be able to return the first record for given predicate.")
    }
    
    func testFirstWithAttribute() {
        let kika = Animal.firstWithAttribute("color", value: "black")
        XCTAssertEqual(kika?.name, "Kika", "Should be able to return the first record for given attribute.")
    }
    
    func testFirstWithAttributeGeneric() {
        let kika: Animal = Animal.firstWithAttribute("color", value: "black")!
        XCTAssertEqual(kika.name, "Kika", "Should be able to return the first record for given attribute.")
    }
    
    func testFirstOrderedByAttribute() {
        let kika = Animal.firstOrderedByAttribute("color", ascending: true)
        XCTAssertEqual(kika?.name, "Kika", "Should be able to return the first record ordered by given attribute.")
    }
    
    func testFirstOrderedByAttributeGeneric() {
        let kika: Animal = Animal.firstOrderedByAttribute("color", ascending: true)!
        XCTAssertEqual(kika.name, "Kika", "Should be able to return the first record ordered by given attribute.")
    }
    
    func testFirstWithAttributes() {
        let tinnaAttributes = ["name" : "Tinna", "color" : "lightgray"]
        let tinna = Animal.firstWithAttributes(tinnaAttributes)
        XCTAssertEqual(tinna?.color, "lightgray", "Should be able to return the first record with given attributes.")
    }
    
    func testFirstWithAttributesGeneric() {
        let tinnaAttributes = ["name" : "Tinna", "color" : "lightgray"]
        let tinna: Animal = Animal.firstWithAttributes(tinnaAttributes)!
        XCTAssertEqual(tinna.color, "lightgray", "Should be able to return the first record with given attributes.")
    }
    
    // MARK: Find All
    
    func testAll() {
        let animals = Animal.all()
        XCTAssertEqual(animals!.count, 7, "Should be able to return all records of entity.")
    }
    
    func testAllGeneric() {
        let animals: [Animal] = Animal.all()!
        XCTAssertEqual(animals.count, 7, "Should be able to return all records of entity.")
    }
    
    func testAllWithPredicate() {
        let predicate = NSPredicate(format: "color == %@", "yellow")
        let yellowAnimals = Animal.allWithPredicate(predicate)
        XCTAssertEqual(yellowAnimals!.count, 2, "Should be able to return all records for given predicate.")
    }
    
    func testAllWithPredicateGeneric() {
        let predicate = NSPredicate(format: "color == %@", "yellow")
        let yellowAnimals: [Animal] = Animal.allWithPredicate(predicate)!
        XCTAssertEqual(yellowAnimals.count, 2, "Should be able to return all records for given predicate.")
    }
    
    func testAllWithAttribute() {
        let whiteAnimals = Animal.allWithAttribute("color", value: "white")
        XCTAssertEqual(whiteAnimals!.count, 2, "Should be able to return all records for given attribute.")
    }
    
    func testAllWithAttributeGeneric() {
        let whiteAnimals: [Animal] = Animal.allWithAttribute("color", value: "white")!
        XCTAssertEqual(whiteAnimals.count, 2, "Should be able to return all records for given attribute.")
    }
    
    func testAllWithAttributes() {
        let whiteAttributes = ["name" : "Villy", "color" : "white"]
        
        let villy = Animal.allWithAttributes(whiteAttributes) as! [Animal]
        XCTAssertEqual(villy.count, 1, "Should be able to return all records for given attributes.")
        XCTAssertEqual(villy.first!.name, "Villy", "Should be able to return all records for given attributes.")
        
        let whiteAnimals = Animal.allWithAttributes(whiteAttributes, predicateType: .OrPredicateType)
        XCTAssertEqual(whiteAnimals!.count, 2, "Should be able to return all records for given attributes and OR predicate type.")
    }
    
    func testAllWithAttributesGeneric() {
        let whiteAttributes = ["name" : "Villy", "color" : "white"]
        
        let villy: [Animal] = Animal.allWithAttributes(whiteAttributes)!
        XCTAssertEqual(villy.count, 1, "Should be able to return all records for given attributes.")
        XCTAssertEqual(villy.first!.name, "Villy", "Should be able to return all records for given attributes.")
        
        let whiteAnimals: [Animal] = Animal.allWithAttributes(whiteAttributes, predicateType: .OrPredicateType)!
        XCTAssertEqual(whiteAnimals.count, 2, "Should be able to return all records for given attributes and OR predicate type.")
    }
    
    // MARK: Delete
    
    func testDelete() {
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        let firstAnimal = Animal.first(sortDescriptors: [sortDescriptor])
        XCTAssertEqual(firstAnimal?.name, "Betty", "Should be able to return the first record sorted by given sort descriptor.")
        
        firstAnimal?.deleteFromContext()
        let betty = Animal.firstWithAttribute("name", value: "Betty")
        XCTAssertNil(betty, "Should be able to delete record.")
    }
    
    func testDeleteAll() {
        Animal.deleteAll()
        let animals = Animal.all()
        XCTAssertNil(animals, "Should be able to delete all records.")
    }
    
    func deleteAllWithPredicate() {
        let predicate = NSPredicate(format: "color == %@", "yellow")
        Animal.deleteAllWithPredicate(predicate)
        
        let animals = Animal.all()
        let betty = Animal.firstWithAttribute("name", value: "Betty")
        
        XCTAssertEqual(animals?.count, 5, "Should be able to delete all records for given predicate.")
        XCTAssertNil(betty, "Should be able to delete all records for given predicate.")
    }
    
    func deleteAllWithAttribute() {
        Animal.deleteAllWithAttribute("color", value: "white")
        
        let animals = Animal.all()
        let villy = Animal.firstWithAttribute("name", value: "Villy")
        
        XCTAssertEqual(animals?.count, 5, "Should be able to delete all records for given attribute.")
        XCTAssertNil(villy, "Should be able to delete all records for given attribute.")
    }
    
    func testDeleteAllWithAttributes() {
        let attributes = ["color" : "white", "name" : "Caesar"]
        Animal.deleteAllWithAttributes(attributes, predicateType: .OrPredicateType)
        
        let animals = Animal.all()
        XCTAssertEqual(animals!.count, 4, "Should be able to delete all records for given attributes.")
    }
    
    // MARK: Count
    
    func testCount() {
        let animalsCount = Animal.count()
        XCTAssertEqual(animalsCount, 7, "Should be able to count all records.")
    }
    
    func testCountWithPredicate() {
        let predicate = NSPredicate(format: "color == %@", "white")
        let whiteCount = Animal.countWithPredicate(predicate)
        XCTAssertEqual(whiteCount, 2, "Should be able to count all records for given predicate.")
    }
    
    func testCountWithAttribute() {
        let yellowCount = Animal.countWithAttribute("color", value: "yellow")
        XCTAssertEqual(yellowCount, 2, "Should be able to count all records for given attribute.")
    }
    
    func testCountWithAttributes() {
        let attributes = ["breed.species.name" : "cat"]
        let catsCount = Animal.countWithAttributes(attributes)
        XCTAssertEqual(catsCount, 3, "Should be able to count all records for given attributes.")
    }
    
    // MARK: Distinct
    
    func testDistinctValuesForAttribute() {
        // not supported by NSInMemoryStoreType
        // SEE: http://stackoverflow.com/questions/20950897/fetching-distinct-values-of-nsinmemorystoretype-returns-duplicates-nssqlitestor
    }
    
    func testDistinctRecordsForAttributes() {
        // not supported by NSInMemoryStoreType
        // SEE: http://stackoverflow.com/questions/20950897/fetching-distinct-values-of-nsinmemorystoretype-returns-duplicates-nssqlitestor
    }
    
    // MARK: Auto Increment
    
    func testAutoIncrementedIntegerAttribute() {
        for animal in Animal.all() as! [Animal] {
            animal.customID = Animal.autoIncrementedIntegerAttribute("customID")
        }
        let newCustomID = Animal.autoIncrementedIntegerAttribute("customID")
        XCTAssertEqual(newCustomID, 8, "Should be able to return next integer value for given attribute.")
    }
    
    // MARK: Turn Object Into Fault
    
    func testRefresh() {
        // not sure how to test this in NSInMemoryStoreType
    }
    
    // MARK: Batch Update
    
    func testBatchUpdate() {
        // not supported by NSInMemoryStoreType
        // SEE: NSBatchUpdateRequest.h
    }
    
    func testObjectsCountForBatchUpdate() {
        // not supported by NSInMemoryStoreType
        // SEE: NSBatchUpdateRequest.h
    }
    
    func testBatchUpdateAndRefreshObjects() {
        // not supported by NSInMemoryStoreType
        // SEE: NSBatchUpdateRequest.h
    }
    
}









