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

        PepperDogFetch.log.setup(level: .debug, showLogIdentifier: false, showFunctionName: true, showThreadName: false, showLevel: true, showFileNames: true, showLineNumbers: true, showDate: false, writeToFile: nil, fileLevel: nil)
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
            // PostgreSQLConnectionDictionary.Host.rawValue:         "192.168.170.119",
            PostgreSQLConnectionDictionary.Host.rawValue:         "localhost",
            // PostgreSQLConnectionDictionary.Port.rawValue:         "6543",
            PostgreSQLConnectionDictionary.Port.rawValue:         "5432",
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
