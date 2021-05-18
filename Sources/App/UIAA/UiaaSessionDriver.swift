//
//  UiaaSessionDriver.swift
//  Based on Vapor's MemorySessions
//
//  Created by Charles Wright on 4/1/21.
//

import Foundation
import Vapor

public struct UiaaSessionDriver {
    private var store: Store
    
    // Is this only here to provide mutability??
    public final class Store {
        public var dict: ConcurrentDictionary<SessionID,UiaaSessionData>
        public init(_ n: Int = 32) {
            self.dict = .init(n)
        }
    }
    
    public init(numShards n: Int = 32) {
        self.store = .init(n)
    }
    
    public func createSession(
        _ data: UiaaSessionData,
        for request: Request
    ) -> EventLoopFuture<SessionID> {
        let id = data.state.session
        let sessionID = SessionID(string: id)
        print("DRIVER\tCreating session for id \(id)")

        self.store.dict[sessionID] = data
        return request.eventLoop.makeSucceededFuture(sessionID)
    }
    
    public func readSession(_ sessionID: SessionID, for request: Request) -> EventLoopFuture<UiaaSessionData?> {
        print("DRIVER\tLooking up UIAA session \(sessionID.string)")
        let data = self.store.dict[sessionID]
        if data == nil {
            print("DRIVER\tWTF, we suck")
        }
        return request.eventLoop.makeSucceededFuture(data)
    }
    
    public func updateSession(_ sessionID: SessionID, to data: UiaaSessionData, for request: Request) -> EventLoopFuture<SessionID> {
        self.store.dict[sessionID] = data
        return request.eventLoop.makeSucceededFuture(sessionID)
    }
    
    public func deleteSession(_ sessionID: SessionID, for request: Request) -> EventLoopFuture<Void> {
        self.store.dict[sessionID] = nil
        return request.eventLoop.makeSucceededFuture(())
    }
    
    
}
