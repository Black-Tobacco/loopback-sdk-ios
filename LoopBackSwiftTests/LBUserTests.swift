//
//  LBUserTests.swift
//  HWPF
//
//  Created by Sylvain Ageneau on 4/30/15.
//  Copyright (c) 2015 Black Tobacco. All rights reserved.
//

import XCTest
import LoopBackSwift

class CustomerRepository : LBUserRepository {
    override class func repository() -> LBUserRepository {
        let repo = CustomerRepository(className: "customers", modelClass: LBUser.self)
        return repo
    }
}

class LBUserTests: XCTestCase {
    let DEFAULTS_CURRENT_USER_ID_KEY = "LBUserRepositoryCurrentUserId"
    let USER_EMAIL_DOMAIN = "@test.com"
    let USER_PASSWORD = "testpassword"
    
    var repository:LBUserRepository!
    static var lastId:NSNumber = 0
    
    override func setUp() {
        super.setUp()
        
        // forcibly clear the stored user id
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.removeObjectForKey(DEFAULTS_CURRENT_USER_ID_KEY)
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let adapter:LBRESTAdapter = LBRESTAdapter(URL: NSURL(string: "http://localhost:3000")!)
        repository = adapter.repositoryWithClass(CustomerRepository.self) as! LBUserRepository
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCreateSaveRemove() {
        let expectation = self.expectationWithDescription("testCreateSaveRemove")
        let uid = NSDate.timeIntervalSinceReferenceDate()
        let userEmail = "\(uid)\(USER_EMAIL_DOMAIN)"
        let customer = repository.createUser(email: userEmail, password:USER_PASSWORD)
        XCTAssertNil(customer.id, "User id should be nil before save")
        customer.save( { () -> () in
            XCTAssertNotNil(customer.id, "User id should not be nil after save")
            self.repository.userByLogin(email:userEmail, password:self.USER_PASSWORD, success: {
                (user) -> () in
                user.destroy({ () -> () in
                    expectation.fulfill()
                    }, failure: { (error) -> () in
                    XCTFail(error.description)
                    expectation.fulfill()
                })
                
            }, failure: {
                ( error: NSError! ) -> () in
                XCTFail(error.description)
                expectation.fulfill()
            })
        }, failure: {
            (error:NSError!) -> () in
            XCTFail(error.description)
            expectation.fulfill()
        })
        
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }
}
