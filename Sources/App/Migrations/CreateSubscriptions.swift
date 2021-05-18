//
//  SubscriptionMigration.swift
//  
//
//  Created by Charles Wright on 4/13/21.
//

import Foundation
import Vapor
import Fluent

struct CreateSubscriptions: Migration {
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("subscriptions")
            .id()
            .field("user_id", .string)
            .field("provider", .string)
            .field("identifier", .string)
            .field("start_date", .date)
            .field("end_date", .date)
            .field("level", .string)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("subscriptions").delete()
    }
}
