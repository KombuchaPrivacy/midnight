//
//  File.swift
//  Based on Vapor's Session.swift
//
//  Created by Charles Wright on 4/9/21.
//

import Foundation
import Vapor

public final class UiaaSession {
    public var id: SessionID?
    
    public var data: UiaaSessionData
    
    var isValid: Bool
        
    public init(id: SessionID? = nil, data: UiaaSessionData) {
        self.id = id
        self.data = data
        self.isValid = true
    }
}
