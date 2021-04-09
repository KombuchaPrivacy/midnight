//
//  UiaaSessionData.swift
//  Based on Vapor's SessionData
//
//  Created by Macro Ramius on 4/9/21.
//

import Foundation
import Vapor

public struct UiaaSessionData {
    public var state: UiaaSessionState
    
    private var dict: [String:String]
    public var snapshot: [String:String] { self.dict }
    
    /*
    public init() {
        self.state = nil
        self.dict = [:]
    }
    */
    
    public init(initialData data: [String:String], initialState: UiaaSessionState) {
        self.dict = data
        self.state = initialState
    }
    
    public subscript(_ key: String) -> String? {
        get { return self.dict[key] }
        set(newValue) { self.dict[key] = newValue }
    }
    
}
