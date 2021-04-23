//
//  Config.swift
//  
//
//  Created by Macro Ramius on 4/19/21.
//

import Foundation
import Vapor

public struct Config: Codable {
    
    struct DBConfig: Codable {
        var host: String
        var port: Int?
        var name: String
        var username: String
        var password: String
    }
    
    var homeserver: URL
    var databaseServer: DBConfig?
    var databaseFile: String?
}
