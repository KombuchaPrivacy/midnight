//
//  UiaaResponseData.swift
//  
//
//  Created by Macro Ramius on 3/31/21.
//

import Fluent
import Vapor

public struct UiaaAuthFlow: Content {
    var stages: [String]
}

typealias UiaaStateParams = [String: [String:String]]?

public struct UiaaSessionState: Content {
    var errcode: String?
    var error: String?
    var flows: [UiaaAuthFlow]
    var params: [String: [String:String]]?
    var completed: [String]?
    var session: String
}

public struct UiaaSessionStateBare: Content {
    var session: String
}
