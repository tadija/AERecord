//
//  AERecordTests.swift
//  AERecordTests
//
//  Created by Marko Tadic on 11/3/14.
//  Copyright (c) 2014 ae. All rights reserved.
//

import UIKit
import XCTest
import CoreData

class AERecordTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        /* load CoreData stack */
        
        let bundle = NSBundle(forClass: AERecordTests.self)
        let modelURL = bundle.URLForResource("AERecordTestModel", withExtension: "momd")
        let model = NSManagedObjectModel(contentsOfURL: modelURL!)
        let storeURL = AERecord.storeURLForName("AERecordTest")
        AERecord.loadCoreDataStack(managedObjectModel: model!, storeURL: storeURL)
        
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
        let tinna = Animal.createWithAttributes(["name" : "Tinna", "color" : "lightgray", "breed" : siberian])
        let rose = Animal.createWithAttributes(["name" : "Rose", "color" : "darkgray", "breed" : domestic])
        let caesar = Animal.createWithAttributes(["name" : "Caesar", "color" : "yellow", "breed" : domestic])
        let villy = Animal.createWithAttributes(["name" : "Villy", "color" : "white", "breed" : bullTerrier])
        let spot = Animal.createWithAttributes(["name" : "Spot", "color" : "white", "breed" : bullTerrier])
        let betty = Animal.createWithAttributes(["name" : "Betty", "color" : "yellow", "breed" : goldenRetriever])
        let kika = Animal.createWithAttributes(["name" : "Kika", "color" : "black", "breed" : miniatureSchnauzer])
    }
    
    override func tearDown() {
        AERecord.destroyCoreDataStack()
        
        super.tearDown()
    }
    
    func testEntityName() {
        XCTAssertEqual(Animal.entityName, "Animal", "Should be able to get name of the entity.")
    }
    
    func testEntity() {
        let animalAttributesCount = Animal.entity?.attributesByName.count
        XCTAssertEqual(animalAttributesCount!, 2, "Should be able to get NSEntityDescription of the entity.")
    }
    
    func testCreateFetchRequest() {
        let request = Animal.createFetchRequest()
        XCTAssertEqual(request.entityName!, "Animal", "Should be able to create fetch request for entity.")
    }
    
    func testCompoundPredicateForAttributes() {
        let attributes = ["name" : "Tinna", "color" : "lightgray"]
        let predicate = Animal.compoundPredicateForAttributes(attributes, type: .AndPredicateType)
        XCTAssertEqual(predicate.predicateFormat, "color == \"lightgray\" AND name == \"Tinna\"", "Should be able to create compound predicate.")
    }
    
    func testCreate() {
        let animal = Animal.create()
        XCTAssertEqual(animal.self, animal, "Should be able to create instance of entity.")
    }
    
    func testCreateWithAttributes() {
        let attributes = ["name" : "Tinna", "color" : "lightgray"]
        let tinna = Animal.createWithAttributes(attributes)
        XCTAssertEqual(tinna.color, "lightgray", "Should be able to create instance of entity with attributes.")
    }
    
    func testFirstOrCreateWithAttribute() {
        let snoopy = Animal.firstOrCreateWithAttribute("name", value: "Snoopy") as! Animal
        XCTAssertEqual(snoopy.name, "Snoopy", "Should be able to create record if it doesn't already exist.")
        
        let tinna = Animal.firstOrCreateWithAttribute("name", value: "Tinna") as! Animal
        XCTAssertEqual(tinna.color, "lightgray", "Should be able to return the first record with given attribute.")
    }
    
    func testFirstOrCreateWithAttributes() {
        let snoopyAttributes = ["name" : "Snoopy", "color" : "white"]
        let snoopy = Animal.firstOrCreateWithAttributes(snoopyAttributes) as! Animal
        XCTAssertEqual(snoopy.color, "white", "Should be able to create record if it doesn't already exist.")
        
        let tinnaAttributes = ["name" : "Tinna", "color" : "lightgray"]
        let tinna = Animal.firstOrCreateWithAttributes(tinnaAttributes) as! Animal
        XCTAssertEqual(tinna.color, "lightgray", "Should be able to return the first record with given attributes.")
    }
    
}









