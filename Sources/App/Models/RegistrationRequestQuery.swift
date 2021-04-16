//
//  File.swift
//  
//
//  Created by Macro Ramius on 4/16/21.
//

import Foundation
import Vapor

public struct RegistrationRequestQuery: Content {
    enum AccountType: String, Codable {
        case guest
        case user
    }
    var kind: AccountType?
}
