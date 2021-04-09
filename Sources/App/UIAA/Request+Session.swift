//
//  Request+UiaaSession.swift
//  Based on Vapor's Request+Session
//
//  Created by Macro Ramius on 4/1/21.
//

import Foundation
import Vapor

extension Request {
            
    private struct UiaaKey: StorageKey {
        typealias Value = UiaaSession
    }
    
    public var uiaaSession: UiaaSession? {
        get {
            /* // The default Vapor SessionsMiddleware creates sessions by itself.
               // But we can't do that.  Only the homeserver can create a session.
               // So here we make our Session optional, and we can return nil if
               // there is no existing session for a request.
            if let existing = self.storage[UiaaKey.self] {
                return existing
            } else {
                let new = Session()
                self.storage[UiaaKey.self] = new
                return new
            }
            */
            self.storage[UiaaKey.self]
        }
        set(new) {
            self.storage[UiaaKey.self] = new
        }
    }
    
    public var hasUiaaSession: Bool {
        nil != self.storage[UiaaKey.self]
    }
}
