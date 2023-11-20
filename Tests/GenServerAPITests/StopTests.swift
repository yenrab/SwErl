//
//  File.swift
//  
//
//  Created by SwErl on 10/30/23.
//
import XCTest
import Foundation

@testable import SwErl




final class Stop : XCTestCase {
    override func setUp() {
        resetRegistryAndPIDCounter()
        try! GenServer.startLink("server", SimpleCastServer.self, 10)
    }
    
    override func tearDown() {
        resetRegistryAndPIDCounter()
    }
    
    //end the process with an empty associated dispatch queue
    func testEmptyQueue() {
        GenServer.stop("server", "shutdown")
        Thread.sleep(forTimeInterval: 1)
        XCTAssert(Registrar.instance.OTPActorsLinkedToPid.isEmpty , "server ref not removed from pid:type dictionary")
        XCTAssert(Registrar.instance.processesLinkedToName.isEmpty, "server ref not removed from name:pid dictionary")
    }
}

final class FilledQueueStop: XCTestCase {
    //NOTE test case only valid when start_link and cast tests succeed.
    //expectations:
    // - Dispatch Queued tasks do not run
    // - any calls (queue.sync()) recieve a noProc error
    //end the process with items still remaining on the dispatch queue
    
    let noRun = XCTestExpectation(
        description: "Inverted expectation: fails if code added to queue after stop ran.")
    override func setUp() {
        resetRegistryAndPIDCounter()
        noRun.isInverted = true
        try! GenServer.startLink("queue server", expectationServer.self, noRun)
    }
    override func tearDown() {
        resetRegistryAndPIDCounter()
    }
    
    func testOccupiedQueueCasts() {
        // make sure each cast takes place in order
        let Q = DispatchQueue(label: "temp q to ensure things are added in order")
        
        Q.sync { try! GenServer.cast("queue server", "delay") }
        Q.sync { GenServer.stop("queue server", "shutdown") }
//        Thread.sleep(forTimeInterval: 0.1)
        Q.sync { try! GenServer.cast("queue server", "fulfill") }//error not expected here
        wait(for: [noRun], timeout: 4) //inverted expectation
    }
//    func testOccupiedQueueCalls() {
//
//    }
}

final class AlreadyRegistered: XCTestCase {
    override func setUpWithError() throws {
        resetRegistryAndPIDCounter()
        try GenServer.startLink("already registered", SimpleCastServer.self, nil)
    }
    
    override func tearDown() {
        resetRegistryAndPIDCounter()
    }
    
    func testAlreadyRegistered() {
        XCTAssertThrowsError(
            try GenServer.startLink("already registered", SimpleCastServer.self, nil),
            "attempt to register already registered gen server did not error"){ (error) in
                XCTAssertEqual(error as! SwErlError, SwErlError.processAlreadyLinked,
                               "incorrect error type")
            }
    }
}
