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
        typealias Value = Session
    }
    
    public var uiaaSession: Session {
        get {
            if let existing = self.storage[UiaaKey.self] {
                return existing
            } else {
                let new = Session()
                self.storage[UiaaKey.self] = new
                return new
            }
        }
        set(new) {
            self.storage[UiaaKey.self] = new
        }
    }
    
    public var hasUiaaSession: Bool {
        nil == self.storage[UiaaKey.self]
    }
}
