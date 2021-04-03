//
//  UiaaResponseData.swift
//  
//
//  Created by Macro Ramius on 3/31/21.
//

import Fluent
import Vapor

struct MatrixAuthFlow: Content {
    var stages: [String]
}

struct UiaaResponseData: Content {
    var errcode: String?
    var error: String?
    var flows: [MatrixAuthFlow]
    var params: [String: [String:String]]?
    var completed: [String]?
    var session: String
}

public struct UiaaResponseSessionOnly: Content {
    var session: String
}
