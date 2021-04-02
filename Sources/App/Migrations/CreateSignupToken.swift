//
//  CreateSignupToken.swift
//  
//
//  Created by Macro Ramius on 4/2/21.
//

import Foundation
import Vapor
import Fluent

struct CreateSignupToken: Migration {
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("signuptokens")
            .id()
            .field("token", .string)
            .field("max_signups", .uint)
            .field("created_by", .string)
            .field("created_at", .datetime)
            .field("expires_at", .datetime)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("signuptokens").delete()
    }
}
