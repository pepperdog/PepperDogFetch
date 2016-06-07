//
//  PepperDogFetchTests.swift
//  PepperDogFetchTests
//
//  Created by Kenny Leung on 4/2/16.
//  Copyright © 2016 Kenny Leung. All rights reserved.
//

import XCTest
@testable import PepperDogFetch

class PepperDogFetchTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func testFetchComics() throws {
        let database = PostgreSQLDatabase(connectionDictionary:[
            .Host:"192.168.70.107",
            .Port: "5432",
            .DatabaseName: "comics",
            .User: "comics",
            .Password: "comics"
            ])
        let results = try database.execute(sql: "select * from gcd_issue", bindings: nil)

        for i in results {
        }
    }
    
}
