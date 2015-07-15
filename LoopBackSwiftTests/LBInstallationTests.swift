//
//  LBInstallationTests.swift
//  LoopBack
//
//  Created by Sylvain Ageneau on 7/14/15.
//  Copyright (c) 2015 StrongLoop. All rights reserved.
//

import XCTest
import LoopBackSwift

class LBInstallationTests : XCTestCase {
    var repository:LBInstallationRepository!
    var testToken:NSData!
    static var lastId:String? = nil
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let adapter:LBRESTAdapter = LBRESTAdapter(URL: NSURL(string: "http://localhost:3000")!)
        repository = adapter.repositoryWithClass(LBInstallationRepository.self) as! LBInstallationRepository
        let data:[UInt8] = [
            0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f,
            0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f,
            0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f,
            0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f]
        self.testToken = NSData(bytes: data, length: data.count)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSingletonRepository() {
        let r1:LBInstallationRepository = LBInstallationRepository.repository()
        let r2:LBInstallationRepository = LBInstallationRepository.repository()
        
        XCTAssertEqual(r1, r2, "LBInstallationRepository.repository is a singleton")
    }
    
    func testTokenOK() {
        let token = LBInstallation.deviceToken(data: self.testToken)
        XCTAssertTrue(token == "0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f", "Invalid token")
    }
    
    func testRegister() {
        let expectation = self.expectationWithDescription("testRegister")
        LBInstallation.registerDevice(adapter: self.repository.adapter as! LBRESTAdapter,
            deviceToken: self.testToken,
            registrationId: LBInstallationTests.lastId,
            appId: "testapp",
            appVersion: "1.0",
            userId: "user1",
            badge: 1,
            subscriptions: [],
            success: { (model) -> () in
                println("Completed with \(model.id)")
                LBInstallationTests.lastId = (model.id as? NSNumber)?.stringValue
                println("converted: \(LBInstallationTests.lastId)")
                XCTAssertNotNil(model.id, "Invalid id")
                expectation.fulfill()
            },
            failure: { (error:NSError!) -> () in
                XCTFail(error.description)
                expectation.fulfill()
        })
        
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func testFind() {
        let expectation = self.expectationWithDescription("testFind")
        self.repository.findById(LBInstallationTests.lastId!,
            success: { (model) -> () in
                XCTAssertNotNil(model, "No model found with ID 1")
                XCTAssert(model is LBInstallation, "Invalid class.")
                expectation.fulfill() },
            failure: { (error) -> () in
                XCTFail(error.description)
                expectation.fulfill()
        })
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func testAll() {
        let expectation = self.expectationWithDescription("testAll")
        self.repository.findAll(
            { (models) -> () in
                XCTAssertNotNil(models, "No models returned.")
                XCTAssertTrue(models.count >= 1, "Invalid # of models returned: \(models.count)")
                expectation.fulfill() },
            failure: { (error) -> () in
                XCTFail(error.description)
                expectation.fulfill()
        })
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func testReRegister() {
        let expectation = self.expectationWithDescription("testReRegister")
        LBInstallation.registerDevice(adapter: self.repository.adapter as! LBRESTAdapter,
            deviceToken: self.testToken,
            registrationId: LBInstallationTests.lastId,
            appId: "testapp",
            appVersion: "1.0",
            userId: "user2",
            badge: 1,
            subscriptions: [],
            success: { (model) -> () in
                let id1 = (model.id as? NSNumber)?.stringValue
                let id2 = LBInstallationTests.lastId
                LBInstallationTests.lastId = id1
                XCTAssertTrue(id1 == id2, "The ids should be the same \(id1) and \(id2)")
                XCTAssertNotNil(model.id, "Invalid id")
                expectation.fulfill()
            },
            failure: { (error:NSError!) -> () in
                XCTFail(error.description)
                expectation.fulfill()
        })
        
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func testRemove() {
        let expectation = self.expectationWithDescription("testRemove")
        self.repository.findById(LBInstallationTests.lastId!,
            success: { (model) -> () in
                model.destroy({
                        expectation.fulfill()
                    },
                    failure: { (error) -> () in
                        XCTFail(error.description)
                        expectation.fulfill()
                })},
            failure: { (error) -> () in
                XCTFail(error.description)
                expectation.fulfill()
        })
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }
}