//
//  LBModelSubclassingTests.swift
//  LoopBack
//
//  Created by Sylvain Ageneau on 5/1/15.
//  Copyright (c) 2015 StrongLoop. All rights reserved.
//

import XCTest
import LoopBackSwift

class Widget: LBModel {
    var name:String?
    var bars:NSNumber?
}


class WidgetRepository : LBModelRepository {
    override class func repository() -> LBModelRepository {
        return WidgetRepository(className: "widgets", modelClass: Widget.self)
    }
}


class LBModelSubclassingTests: XCTestCase {
    var repository:WidgetRepository!
    static var lastId:NSNumber = 0
    
    override func setUp() {
        super.setUp()
        
//        SLAFHTTPRequestOperationLogger.sharedLogger().startLogging()
//        SLAFHTTPRequestOperationLogger.sharedLogger().level = .AFLoggerLevelDebug
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let adapter:LBRESTAdapter = LBRESTAdapter(URL: NSURL(string: "http://localhost:3000")!)
        repository = adapter.repositoryWithClass(WidgetRepository.self) as! WidgetRepository
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCreate() {
        let model = repository.modelWithDictionary(["name":"Foobar", "bars": 1])
        XCTAssertEqual("Foobar", model["name"] as! String, "Invalid name.")
        XCTAssertEqual(1, model["bars"] as! NSNumber, "Invalid bars.");
        XCTAssertNil(model.id, "Invalid id");
        
        let expectation = self.expectationWithDescription("testCreate")
        model.save({
            () -> () in
            print("Completed with \(model.id)")
            LBModelTests.lastId = model.id as! NSNumber
            XCTAssertNotNil(model.id, "Invalid id")
            expectation.fulfill()
            }, failure: {
                (error:NSError!) -> () in
                XCTFail(error.description)
                expectation.fulfill()
        })
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    
    func testFind() {
        let expectation = self.expectationWithDescription("testFind")
        repository.findById(2,
            success: {
                (model:LBModel) -> () in
                XCTAssertNotNil(model, "No model found with ID 2")
                XCTAssert(model is Widget, "Invalid class.")
                XCTAssertEqual((model as! Widget).name!, "Bar", "Invalid name")
                XCTAssertEqual((model as! Widget).bars!, 1, "Invalid bars")
                expectation.fulfill()
            }) {
                (error:NSError!) -> () in
                XCTFail(error.description)
                expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testAll() {
        let expectation = self.expectationWithDescription("testAll")
        repository.findAll(
            {
                (models:[LBModel]) -> () in
                XCTAssertNotNil(models, "No models returned.")
                XCTAssert(models.count >= 2, "Invalid # of models returned\(models.count)")
                XCTAssert(models[0] is Widget, "Invalid class.")
                XCTAssertEqual((models[0] as! Widget).name!, "Foo", "Invalid name")
                XCTAssertEqual((models[0] as! Widget).bars!, 0, "Invalid bars")
                XCTAssertEqual((models[1] as! Widget).name!, "Bar", "Invalid name")
                XCTAssertEqual((models[1] as! Widget).bars!, 1, "Invalid bars")
                expectation.fulfill()
            }, failure: {
                (error:NSError!) -> () in
                XCTFail(error.description)
                expectation.fulfill()
        })
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testUpdate() {
        let expectation = self.expectationWithDescription("testUpdate")
        let verify = { ( model:LBModel ) -> () in
            XCTAssertNotNil(model, "No model found with ID 2")
            XCTAssert(model is Widget, "Invalid class.")
            XCTAssertEqual((model as! Widget).name!, "Barfoo", "Invalid name")
            XCTAssertEqual((model as! Widget).bars!, 1, "Invalid bars")
            
            (model as! Widget).name = "Bar";
            model.save({ () -> () in
                expectation.fulfill()
                }, failure: { (error) -> () in
                    XCTFail(error.description)
                    expectation.fulfill()
            })
        }
        
        let findAgain = { () -> () in
            self.repository.findById(2, success: verify, failure: { (error) -> () in
                XCTFail(error.description)
                expectation.fulfill()
            })
        }

        let update = { ( model:LBModel ) -> () in
            XCTAssertNotNil(model, "No model found with ID 2")
            (model as! Widget).name = "Barfoo";
            model.save(findAgain, failure: { (error) -> () in
                XCTFail(error.description)
                expectation.fulfill()
            })
        }
        
        self.repository.findById(2, success: update) { (error) -> () in
            XCTFail(error.description)
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testRemove() {
        let expectation = self.expectationWithDescription("testRemove")
        self.repository.findById(LBModelTests.lastId, success: { (model:LBModel) -> () in
            model.destroy({ () -> () in
                expectation.fulfill()
                }, failure: { (error) -> () in
                    XCTFail(error.description)
                    expectation.fulfill()
            })
            
            }) { (error) -> () in
                XCTFail(error.description)
                expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }
    
}
