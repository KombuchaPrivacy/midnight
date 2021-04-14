//
//  CreateRegistrationData.swift
//  
//
//  Created by Macro Ramius on 4/14/21.
//

import Foundation
import Vapor
import Fluent

struct CreateRegistrationData: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        
        // Create the "signuptokens" so we can selectively enable people to sign up
        database.schema("signuptokens")
            .id()
            .field("token", .string)
            .field("slots", .uint)
            .field("access_level", .string)
            .field("access_duration", .uint)
            .field("created_by", .string)
            .field("created_at", .datetime)
            .field("expires_at", .datetime)
            .create()
            .flatMap {
                // Create the table of pending subscriptions, so we can reserve a spot before handing off the registration request to the real homeserver
                database.schema("pending")
                    .id()
                    .field("token", .string)
                    .field("session_id", .string)
                    .field("created_at", .datetime)
                    .field("expires_at", .datetime)
                    .create()
            }
            .flatMap {
        
                // Create the "badwords" table for all the forbidden strings
                database.schema("badwords")
                    .id()
                    .field("word", .string, .required)
                    .field("created_at", .datetime)
                    .field("created_by", .string)
                    .field("notes", .string)
                    .create()
            }
            .flatMap {
                // Create the "reservedwords" table for all the names that are not available for regular users
                database.schema("reservedwords")
                    .id()
                    .field("word", .string, .required)
                    .field("created_at", .datetime)
                    .field("created_by", .string)
                    .field("notes", .string)
                    .create()
            }
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        
        database.schema("signuptokens").delete()
            .flatMap {
                database.schema("pending").delete()
            }
            .flatMap {
                database.schema("badwords").delete()
            }
            .flatMap {
                database.schema("reservedwords").delete()
            }
    }
}
