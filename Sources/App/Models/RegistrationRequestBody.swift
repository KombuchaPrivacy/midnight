//
//  RegistrationRequestBody.swift
//  
//
//  Created by Macro Ramius on 4/12/21.
//

import Foundation
import Vapor

public struct RegistrationRequestBody: Content {
    var auth: UiaaAuthData?
    var username: String
    var password: String
    var deviceId: String?
    var initialDeviceDisplayName: String?
    var inhibitLogin: Bool?
}
