//
//  Application+UiaaSessions.swift
//  Based on Vapor's Application+Sessions
//
//  Created by Charles Wright on 4/1/21.
//

import Foundation
import Vapor

extension Application {
    public var uiaaSessions: UiaaSessions {
        .init(application: self)
    }
    
    public struct UiaaSessions {
        // UIAA sessions are ephemeral -- We don't need long term storage
        public typealias Store = ConcurrentDictionary<SessionID,UiaaSessionData>
        //var data: Store
        let application: Application
        
        // For the Vapor Application's storage interface
        struct Key: StorageKey {
            typealias Value = Store
        }
        
        public var middleware: UiaaMiddleware {
            .init(driver: .init())
        }
        
        public var store: Store {
            guard let store = self.application.storage[Key.self] else {
                fatalError("UiaaSessions not configured. Configure with app.uiaaSessions.initialize()")
            }
            return store
        }
        
        func initialize() {
            self.application.storage[Key.self] = .init()
        }
    }
}
