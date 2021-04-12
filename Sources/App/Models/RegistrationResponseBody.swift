//
//  RegistrationResponseBody.swift
//  
//
//  Created by Macro Ramius on 4/12/21.
//

import Foundation
import Vapor

public struct RegistrationResponseBody: Content {
    var userId: String
    var accessToken: String?
    var deviceId: String?
}
