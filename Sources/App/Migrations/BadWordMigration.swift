//
//  UsernameRegexMigration.swift
//  
//
//  Created by Macro Ramius on 4/12/21.
//

import Foundation
import Vapor
import Fluent

/*
struct BadWordMigration: Migration {
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("badwords")
            .id()
            .field("word", .string, .required)
            .field("created_at", .datetime)
            .field("created_by", .string)
            .field("notes", .string)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("badwords").delete()
    }
}
*/
