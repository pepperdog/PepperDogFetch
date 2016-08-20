//
//  PepperDogFetchTests.swift
//  PepperDogFetchTests
//
//  Created by Kenny Leung on 4/2/16.
//  Copyright © 2016 Kenny Leung. All rights reserved.
//

import XCTest
import PepperDogFetch
import hexdreamsCocoa
import XCGLogger
@testable import PepperDogFetch

class PepperDogFetchTests: XCTestCase {
    
    override func setUp() {
        super.setUp()

        PepperDogFetch.log.setup(.Debug, showThreadName: true, showLogLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: nil, fileLogLevel: nil)
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
            PostgreSQLConnectionDictionary.Host.rawValue:         "192.168.170.102",
            PostgreSQLConnectionDictionary.Port.rawValue:         "6543",
            PostgreSQLConnectionDictionary.DatabaseName.rawValue: "comics",
            PostgreSQLConnectionDictionary.User.rawValue:         "comics",
            PostgreSQLConnectionDictionary.Password.rawValue:     "comics"
            ])
        let results = try database.execute(sql: "select * from gcd_issue", bindings: nil)

        for i in results {
            print("\(i)")
        }
    }

}
