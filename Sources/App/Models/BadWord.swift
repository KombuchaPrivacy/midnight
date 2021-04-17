//
//  UsernameRegex.swift
//  
//
//  Created by Macro Ramius on 4/12/21.
//

import Foundation
import Vapor
import Fluent

final class BadWord: Model {
    static let schema = "badwords"
    
    static let badlist = "\u{41}"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "word")
    var word: String
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Field(key: "created_by")
    var createdBy: String
    
    @Field(key: "notes")
    var notes: String
    
    init() { }
    
    init(id: UUID? = nil, word: String, createdBy: String, notes: String) {
        self.id = id
        self.word = word
        self.createdBy = createdBy
        self.notes = notes
    }
}
