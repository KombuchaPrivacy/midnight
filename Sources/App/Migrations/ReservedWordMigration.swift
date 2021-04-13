//
//  File.swift
//  
//
//  Created by Macro Ramius on 4/12/21.
//

import Foundation
import Vapor
import Fluent

struct ReservedWordMigration: Migration {
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("reservedwords")
            .id()
            .field("word", .string, .required)
            .field("created_at", .datetime)
            .field("created_by", .string)
            .field("notes", .string)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("reservedwords").delete()
    }
}
