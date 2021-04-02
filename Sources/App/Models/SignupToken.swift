//
//  SignupToken.swift
//  
//
//  Created by Macro Ramius on 3/30/21.
//

import Fluent
import Vapor

struct TokenString: Equatable {
    let string: String
    
    init() {
        self.string = String(format: "%016x", UInt64.random())
    }
}

final class SignupToken: Model {
    static let schema = "signuptokens"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "token")
    var token: String
    
    @Field(key: "max_signups")
    var maxSignups: UInt
    
    @Field(key: "created_by")
    var createdBy: String
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Field(key: "expires_at")
    var expiresAt: Date?
    
    init() {}
    
    init(id: UUID? = nil, numUses: UInt, for userId: String, expiresAt: Date? = nil) {
        self.id = id
        self.token = String(format: "%016x", UInt64.random())
        self.maxSignups = numUses
        self.createdBy = userId
        self.expiresAt = expiresAt
    }
}
