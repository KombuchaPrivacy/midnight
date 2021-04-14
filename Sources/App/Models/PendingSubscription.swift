//
//  PendingSubscription.swift
//  
//
//  Created by Macro Ramius on 4/13/21.
//

import Foundation
import Vapor
import Fluent

final class PendingSubscription: Model {
    static let schema = "pending"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "token")
    var token: String
    
    @Field(key: "session_id")
    var sessionId: String
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Field(key: "expires_at")
    var expiresAt: Date
    
    init() {}
    
    init(id: UUID? = nil, token: String, session: String, expiration: Date) {
        self.id = id
        self.token = token
        self.sessionId = session
        self.expiresAt = expiration
    }
}
