//
//  Subscription.swift
//  
//
//  Created by Macro Ramius on 3/30/21.
//

import Fluent
import Vapor

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

final class Subscription: Model {
    static let schema = "subscription"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "user_id")
    var userId: String
    
    @Field(key: "provider")
    var provider: String
    
    @Field(key: "identifier")
    var identifier: String
    
    @Field(key: "start_date")
    var startDate: Date
    
    @Field(key: "end_date")
    var endDate: Date
    
    @Field(key: "level")
    var level: String
    
    init() {}
    
    init(id: UUID? = nil, userId: String, provider: String, identifier: String, startDate: Date, endDate: Date, level: String) {
        self.id = id
        self.userId = userId
        self.provider = provider
        self.identifier = identifier
        self.startDate = startDate
        self.endDate = endDate
        self.level = level
    }
}
