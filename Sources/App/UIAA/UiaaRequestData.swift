//
//  File.swift
//  
//
//  Created by Macro Ramius on 3/31/21.
//

import Foundation
import Vapor

public struct UiaaAuthData: Content {
    // NOTE: This structure might contain many other things that we don't know about
    // However, that's really not our problem here, as long as we can pass those along unmodified to the homeserver
    var type: String
    var session: String?
    var token: String? //
}


public struct UiaaRequestData: Content {
    var auth: UiaaAuthData
}
