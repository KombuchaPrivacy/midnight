//
//  SignupToken.swift
//  
//
//  Created by Macro Ramius on 3/30/21.
//

import Fluent
import Vapor

final class SignupToken: Model {
    static let schema = "membership"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "creation")
    var creationDate: Date
    
    @Field(key: "expiry")
    var expiryDate: Date
    
    @Field(key: "user_id")
    var userId: String
    
    init() {}
    
    init(id: UUID? = nil, creationDate: Date, expiryDate: Date, userId: String) {
        self.id = id
        self.creationDate = creationDate
        self.expiryDate = expiryDate
        self.userId = userId
    }
}
