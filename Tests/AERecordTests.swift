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
        
        let model = AERecord.modelFromBundle(for: AERecordTests.self)
        do {
            try AERecord.loadCoreDataStack(managedObjectModel: model, storeType: NSInMemoryStoreType)
        }
        catch {
            print(error)
        }
        
        /* add dummy data */
        
        // species
        let dogs = Species.createWithAttributes(["name" : "dog" as AnyObject])
        let cats = Species.createWithAttributes(["name" : "cat" as AnyObject])
        
        // breeds
        let siberian = Breed.createWithAttributes(["name" : "Siberian" as AnyObject, "species" : cats])
        let domestic = Breed.createWithAttributes(["name" : "Domestic" as AnyObject, "species" : cats])
        let bullTerrier = Breed.createWithAttributes(["name" : "Bull Terrier" as AnyObject, "species" : dogs])
        let goldenRetriever = Breed.createWithAttributes(["name" : "Golden Retriever" as AnyObject, "species" : dogs])
        let miniatureSchnauzer = Breed.createWithAttributes(["name" : "Miniature Schnauzer" as AnyObject, "species" : dogs])
        
        // animals
        let _ = Animal.createWithAttributes(["name" : "Tinna" as AnyObject, "color" : "lightgray" as AnyObject, "breed" : siberian])
        let _ = Animal.createWithAttributes(["name" : "Rose" as AnyObject, "color" : "darkgray" as AnyObject, "breed" : domestic])
        let _ = Animal.createWithAttributes(["name" : "Caesar" as AnyObject, "color" : "yellow" as AnyObject, "breed" : domestic])
        let _ = Animal.createWithAttributes(["name" : "Villy" as AnyObject, "color" : "white" as AnyObject, "breed" : bullTerrier])
        let _ = Animal.createWithAttributes(["name" : "Spot" as AnyObject, "color" : "white" as AnyObject, "breed" : bullTerrier])
        let _ = Animal.createWithAttributes(["name" : "Betty" as AnyObject, "color" : "yellow" as AnyObject, "breed" : goldenRetriever])
        let _ = Animal.createWithAttributes(["name" : "Kika" as AnyObject, "color" : "black" as AnyObject, "breed" : miniatureSchnauzer])
    }
    
    override func tearDown() {
        // TODO: improve destroy logic for NSInMemoryStoreType
        // AERecord.destroyCoreDataStack()
        
        super.tearDown()
    }
    
    // MARK: - AERecord
    
    func testDefaultContext() {
        let qualityOfServiceClass = DispatchQoS.QoSClass.background
        let backgroundQueue = DispatchQueue.global(qos: qualityOfServiceClass)
        backgroundQueue.async(execute: {
            let context = AERecord.Context.default
            XCTAssertEqual(context.concurrencyType, NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType, "Should be able to return background context as default context when called from the background queue.")
            
            DispatchQueue.main.async(execute: { () -> Void in
                let context = AERecord.Context.default
                XCTAssertEqual(context.concurrencyType, NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType, "Should be able to return main context as default context when called from the main queue.")
            })
        })
    }
    
    func testMainContext() {
        let context = AERecord.Context.main
        XCTAssertEqual(context.concurrencyType, NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType, "Should be able to create main context with .MainQueueConcurrencyType")
    }
    
    func testBackgroundContext() {
        let context = AERecord.Context.background
        XCTAssertEqual(context.concurrencyType, NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType, "Should be able to create background context with .PrivateQueueConcurrencyType")
    }
    
    func testPersistentStoreCoordinator() {
        let coordinator = AERecord.storeCoordinator
        XCTAssertNotNil(coordinator, "Should be able to create persistent store coordinator.")
    }
    
    func testStoreURLForName() {
        let storeURL = AERecord.storeURL(forName: "test")
        let directoryURL = FileManager.default.urls(for: defaultSearchPath, in: .userDomainMask).last!
        let expectedStoreURL = directoryURL.appendingPathComponent("test.sqlite")
        XCTAssertEqual(storeURL, expectedStoreURL, "")
    }
    
    var defaultSearchPath: FileManager.SearchPathDirectory {
        #if os(tvOS)
            return .CachesDirectory
        #else
            return .documentDirectory
        #endif
    }
    
    func testModelFromBundle() {
        let model = AERecord.modelFromBundle(for: AERecordTests.self)
        let entityNames = Array(model.entitiesByName.keys).sorted()
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
        let tinna = AERecord.execute(fetchRequest: request).first as? Animal
        XCTAssertEqual(tinna!.name, "Tinna", "Should be able to execute given fetch request.")
    }
    
    func testSaveContext() {
        let hasChanges = AERecord.Context.default.hasChanges
        XCTAssertEqual(hasChanges, true, "Should have changes before saving.")
        
        AERecord.save()
        
        let hasChangesAfterSaving = AERecord.Context.default.hasChanges
        XCTAssertEqual(hasChangesAfterSaving, true, "Should still have changes after saving context without waiting.")
        
        let expectation = self.expectation(description: "Context Saving")
        let dispatchTime: DispatchTime = DispatchTime.now() + Double(Int64(1.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: {
            expectation.fulfill()
        })
        
        self.waitForExpectations(timeout: 1.0, handler: { (error) -> Void in
            let hasChangesAfterWaiting = AERecord.Context.default.hasChanges
            XCTAssertEqual(hasChangesAfterWaiting, false, "Should not have changes after waiting a bit, because context is now saved.")
        })
    }
    
    func testSaveContextAndWait() {
        let hasChanges = AERecord.Context.default.hasChanges
        XCTAssertEqual(hasChanges, true, "Should have changes before saving.")
        
        AERecord.saveAndWait()
        
        let hasChangesAfterSaving = AERecord.Context.default.hasChanges
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
        let animalAttributesCount = Animal.entityDescription?.attributesByName.count
        XCTAssertEqual(animalAttributesCount, 3, "Should be able to get NSEntityDescription of the entity.")
    }
    
    func testCreateFetchRequest() {
        let request = Animal.createFetchRequest()
        XCTAssertEqual(request.entityName!, "Animal", "Should be able to create fetch request for entity.")
    }
    
    func testCreatePredicateForAttributes() {
        let attributes = ["name" : "Tinna", "color" : "lightgray"]
        let predicate = Animal.createPredicateForAttributes(attributes)
        XCTAssertTrue(predicate.predicateFormat.contains("name == \"Tinna\""), "Created predicate should contain condition for 'name'.")
        XCTAssertTrue(predicate.predicateFormat.contains(" AND "), "Created predicate should contain AND.")
        XCTAssertTrue(predicate.predicateFormat.contains("color == \"lightgray\""), "Created predicate should contain condition for 'color'.")
    }
    
    // MARK: Create
    
    func testCreate() {
        let animal = Animal.create()
        XCTAssertEqual(animal.self, animal, "Should be able to create instance of entity.")
    }
    
    func testCreateWithAttributes() {
        let attributes = ["name" : "Tinna", "color" : "lightgray"]
        let tinna = Animal.createWithAttributes(attributes as [String : AnyObject])
        XCTAssertEqual(tinna.color, "lightgray", "Should be able to create instance of entity with attributes.")
    }
    
    // MARK: Find First or Create
    
    func testFirstOrCreateWithAttribute() {
        let snoopy = Animal.firstOrCreateWithAttribute("name", value: "Snoopy" as AnyObject)
        XCTAssertEqual(snoopy.name, "Snoopy", "Should be able to create record if it doesn't already exist.")
        
        let tinna = Animal.firstOrCreateWithAttribute("name", value: "Tinna" as AnyObject)
        XCTAssertEqual(tinna.color, "lightgray", "Should be able to return the first record with given attribute.")
    }
    
    func testFirstOrCreateWithAttributeGeneric() {
        let snoopy: Animal = Animal.firstOrCreateWithAttribute("name", value: "Snoopy" as AnyObject)
        XCTAssertEqual(snoopy.name, "Snoopy", "Should be able to create record if it doesn't already exist.")
        
        let tinna: Animal = Animal.firstOrCreateWithAttribute("name", value: "Tinna" as AnyObject)
        XCTAssertEqual(tinna.color, "lightgray", "Should be able to return the first record with given attribute.")
    }
    
    func testFirstOrCreateWithAttributes() {
        let snoopyAttributes = ["name" : "Snoopy", "color" : "white"]
        let snoopy = Animal.firstOrCreateWithAttributes(snoopyAttributes as [String : AnyObject])
        XCTAssertEqual(snoopy.color, "white", "Should be able to create record if it doesn't already exist.")
        
        let tinnaAttributes = ["name" : "Tinna", "color" : "lightgray"]
        let tinna = Animal.firstOrCreateWithAttributes(tinnaAttributes as [String : AnyObject])
        XCTAssertEqual(tinna.color, "lightgray", "Should be able to return the first record with given attributes.")
    }
    
    func testFirstOrCreateWithAttributesGeneric() {
        let snoopyAttributes = ["name" : "Snoopy", "color" : "white"]
        let snoopy: Animal = Animal.firstOrCreateWithAttributes(snoopyAttributes as [String : AnyObject])
        XCTAssertEqual(snoopy.color, "white", "Should be able to create record if it doesn't already exist.")
        
        let tinnaAttributes = ["name" : "Tinna", "color" : "lightgray"]
        let tinna: Animal = Animal.firstOrCreateWithAttributes(tinnaAttributes as [String : AnyObject])
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
        let kika = Animal.firstWithAttribute("color", value: "black" as AnyObject)
        XCTAssertEqual(kika?.name, "Kika", "Should be able to return the first record for given attribute.")
    }
    
    func testFirstWithAttributeGeneric() {
        let kika: Animal = Animal.firstWithAttribute("color", value: "black" as AnyObject)!
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
        let whiteAnimals = Animal.allWithAttribute("color", value: "white" as AnyObject)
        XCTAssertEqual(whiteAnimals!.count, 2, "Should be able to return all records for given attribute.")
    }
    
    func testAllWithAttributeGeneric() {
        let whiteAnimals: [Animal] = Animal.allWithAttribute("color", value: "white" as AnyObject)!
        XCTAssertEqual(whiteAnimals.count, 2, "Should be able to return all records for given attribute.")
    }
    
    func testAllWithAttributes() {
        let whiteAttributes = ["name" : "Villy", "color" : "white"]
        
        let villy = Animal.allWithAttributes(whiteAttributes) as! [Animal]
        XCTAssertEqual(villy.count, 1, "Should be able to return all records for given attributes.")
        XCTAssertEqual(villy.first!.name, "Villy", "Should be able to return all records for given attributes.")
        
        let whiteAnimals = Animal.allWithAttributes(whiteAttributes, predicateType: .or)
        XCTAssertEqual(whiteAnimals!.count, 2, "Should be able to return all records for given attributes and OR predicate type.")
    }
    
    func testAllWithAttributesGeneric() {
        let whiteAttributes = ["name" : "Villy", "color" : "white"]
        
        let villy: [Animal] = Animal.allWithAttributes(whiteAttributes)!
        XCTAssertEqual(villy.count, 1, "Should be able to return all records for given attributes.")
        XCTAssertEqual(villy.first!.name, "Villy", "Should be able to return all records for given attributes.")
        
        let whiteAnimals: [Animal] = Animal.allWithAttributes(whiteAttributes, predicateType: .or)!
        XCTAssertEqual(whiteAnimals.count, 2, "Should be able to return all records for given attributes and OR predicate type.")
    }
    
    // MARK: Delete
    
    func testDelete() {
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        let firstAnimal = Animal.first(sortDescriptors: [sortDescriptor])
        XCTAssertEqual(firstAnimal?.name, "Betty", "Should be able to return the first record sorted by given sort descriptor.")
        
        firstAnimal?.deleteFromContext()
        let betty = Animal.firstWithAttribute("name", value: "Betty" as AnyObject)
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
        let betty = Animal.firstWithAttribute("name", value: "Betty" as AnyObject)
        
        XCTAssertEqual(animals?.count, 5, "Should be able to delete all records for given predicate.")
        XCTAssertNil(betty, "Should be able to delete all records for given predicate.")
    }
    
    func deleteAllWithAttribute() {
        Animal.deleteAllWithAttribute("color", value: "white" as AnyObject)
        
        let animals = Animal.all()
        let villy = Animal.firstWithAttribute("name", value: "Villy" as AnyObject)
        
        XCTAssertEqual(animals?.count, 5, "Should be able to delete all records for given attribute.")
        XCTAssertNil(villy, "Should be able to delete all records for given attribute.")
    }
    
    func testDeleteAllWithAttributes() {
        let attributes = ["color" : "white", "name" : "Caesar"]
        Animal.deleteAllWithAttributes(attributes, predicateType: .or)
        
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
        let yellowCount = Animal.countWithAttribute("color", value: "yellow" as AnyObject)
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









