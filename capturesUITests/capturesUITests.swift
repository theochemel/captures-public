//
//  capturesUITests.swift
//  CapturesUITests
//
//  Created by Theo Chemel on 12/28/18.
//  Copyright © 2018 Theo Chemel. All rights reserved.
//

import XCTest

class CapturesUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {

        continueAfterFailure = false
        
        app = XCUIApplication()
    
        app.launchArguments.append("--uitesting")
    
        app.launch()
    }

    func testSigningIn() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let gamerTagTestField = app.textFields["Gamertag"]
        gamerTagTestField.tap()
        gamerTagTestField.typeText("")
        
        let signInButton = app.buttons["Sign In"]
        signInButton.tap()
        
        let loadScreenIndicator = app.images["Loading"]
        
        let exists = NSPredicate(format: "exists == 1")
        expectation(for: exists, evaluatedWith: loadScreenIndicator, handler: nil)
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testDownloadingVideo() {
        
        let gamerTagTestField = app.textFields["Gamertag"]
        gamerTagTestField.tap()
        gamerTagTestField.typeText("")
        
        let signInButton = app.buttons["Sign In"]
        signInButton.tap()
        
        let loadScreenIndicator = app.images["Loading"]
        
        let loadScreenIndicatorExistsPredicate = NSPredicate(format: "exists == 1")
        expectation(for: loadScreenIndicatorExistsPredicate, evaluatedWith: loadScreenIndicator, handler: nil)
        
        waitForExpectations(timeout: 20.0, handler: nil)
        
        let table = XCUIApplication().tables.firstMatch
        let tableExistsPredicate = NSPredicate(format: "exists == 1")
        expectation(for: tableExistsPredicate, evaluatedWith: table, handler: nil)
        
        waitForExpectations(timeout: 20.0, handler: nil)
        
        app.tables.cells.containing(.staticText, identifier:"Game Clip").buttons["Share"].tap()
        
        let editorExistsPredicate = NSPredicate(format: "exists == 1")
        let editor = app.otherElements["Clip Editor"]
        expectation(for: editorExistsPredicate, evaluatedWith: editor, handler: nil)
        
        waitForExpectations(timeout: 60.0, handler: nil)
        
        app/*@START_MENU_TOKEN@*/.buttons["Share"]/*[[".otherElements[\"Clip Editor\"].buttons[\"Share\"]",".buttons[\"Share\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
    }
}
