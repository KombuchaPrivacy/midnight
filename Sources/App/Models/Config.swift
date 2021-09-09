//
//  Config.swift
//  
//
//  Created by Charles Wright on 4/19/21.
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

    struct AppStoreConfig: Codable {
        var sharedSecret: String
        var bundleId: String
        var productIds: [String]
    }
    
    var homeserver: URL
    var databaseServer: DBConfig?
    var databaseFile: String?

    var appStore: AppStoreConfig?
}
