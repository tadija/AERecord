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
        
        let bundle = NSBundle(forClass: AERecordTests.self)
        let modelURL = bundle.URLForResource("AERecordTestModel", withExtension: "momd")
        let model = NSManagedObjectModel(contentsOfURL: modelURL!)
        let storeURL = AERecord.storeURLForName("AERecordTest")
        AERecord.loadCoreDataStack(managedObjectModel: model!, storeURL: storeURL)
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
        // TODO:
    }
    
    func testCreate() {
        let animal = Animal.create()
//        XCTAssertEqual(animal.description, "", "")
    }
    
}
