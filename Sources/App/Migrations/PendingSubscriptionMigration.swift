//
//  PendingSubscriptionMigration.swift
//  
//
//  Created by Macro Ramius on 4/13/21.
//

import Foundation
import Vapor
import Fluent

/*
struct PendingSubscriptionMigration: Migration {
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("pending")
            .id()
            .field("token", .string)
            .field("session_id", .string)
            .field("created_at", .datetime)
            .field("expires_at", .datetime)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("pending").delete()
    }
}
*/
