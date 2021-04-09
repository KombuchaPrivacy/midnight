//
//  SignupToken.swift
//  
//
//  Created by Macro Ramius on 3/30/21.
//

import Fluent
import Vapor

final class SignupToken: Model {
    static let schema = "signuptokens"
    
    @ID(key: .id)
    var id: UUID?
    
    // The actual token itself
    @Field(key: "token")
    var token: String
    
    // How many users can subscribe with this token?
    @Field(key: "slots")
    var slots: UInt
    
    // What rights does this token confer?
    // * How long does the subscription last? (in days)
    // * What level of access does it give?
    //   - I guess these are like roles.
    //   - Rather than spell out every possible permission or limit here,
    //     we should have another table somewhere that describes them.
    @Field(key: "access_level")
    var accessLevel: String
    @Field(key: "access_duration")
    var accessDuration: UInt
    
    // Other data to help us analyze the social graph, detect fraud etc
    @Field(key: "created_by")
    var createdBy: String
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    // This is the expiration of the token itself, not the accounts
    // that might be created using it.
    // We need this as a way to prevent token usage from getting out of hand
    // So for example we can give out a token with a huge number of slots,
    // but make it time limited to e.g. 24 hours.
    @Field(key: "expires_at")
    var expiresAt: Date?
    
    init() {}
    
    init(id: UUID? = nil, for userId: String, slots: UInt, accessLevel: String, accessDuration: UInt, expiresAt: Date? = nil) {
        self.id = id
        //self.token = String(format: "%016llx", UInt64.random())
        self.token = String(format: "%04x-%04x-%04x-%04x",
                            UInt16.random(),
                            UInt16.random(),
                            UInt16.random(),
                            UInt16.random())
        self.slots = slots
        self.accessLevel = accessLevel
        self.accessDuration = accessDuration
        self.createdBy = userId
        self.expiresAt = expiresAt
    }
}
