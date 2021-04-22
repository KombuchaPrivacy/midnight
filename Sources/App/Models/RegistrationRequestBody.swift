//
//  RegistrationRequestBody.swift
//  
//
//  Created by Macro Ramius on 4/12/21.
//

import Foundation
import Vapor

public struct RegistrationUiaaAuthData: UiaaAuthData {
    var session: String
    var type: String
    var token: String?
}

public struct RegistrationRequestBody: UiaaRequestData {
    var auth: RegistrationUiaaAuthData // FIXME Make this configurable in the future
    var username: String?
    var password: String?
    var deviceId: String?
    var initialDeviceDisplayName: String?
    var inhibitLogin: Bool?
}

