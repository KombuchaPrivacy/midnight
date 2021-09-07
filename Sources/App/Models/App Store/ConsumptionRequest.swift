//
//  ConsumptionRequest.swift
//  
//
//  Created by Charles Wright on 7/28/21.
//

import Foundation
import Vapor
import Fluent

struct ConsumptionRequest: Content {

    enum AccountTenure: Int, Codable {
        case undeclared = 0
        case _0to3days = 1
        case _3to10days = 2
        case _10to30days = 3
        case _30to90days = 4
        case _90to180days = 5
        case _180to365days = 6
        case over365days = 7
    }
    var accountTenure: AccountTenure

    var appAccountToken: UUID

    enum ConsumptionStatus: Int, Codable {
        case undeclared = 0
        case notConsumed = 1
        case partiallyConsumed = 2
        case fullyConsumed = 3
    }
    var consumptionStatus: ConsumptionStatus

    var customerConsented: Bool

    enum DeliveryStatus: Int, Codable {
        case workingProperly = 0
        case qualityIssue = 1
        case wrongItem = 2
        case serverOutage = 3
        case currencyChange = 4
        case otherProblem = 5
    }
    var deliveryStatus: DeliveryStatus

    enum LifetimeDollarAmount: Int, Codable {
        case undeclared = 0
        case zeroUSD = 1
        case under50 = 2
        case under100 = 3
        case under500 = 4
        case under1000 = 5
        case under2000 = 6
        case over2000 = 7
    }
    var lifetimeDollarsPurchased: LifetimeDollarAmount
    var lifetimeDollarsRefunded: LifetimeDollarAmount

    enum Platform: Int, Codable {
        case undeclared = 0
        case apple = 1
        case nonApple = 2
    }
    var platform: Platform

    enum PlayTime: Int, Codable {
        case undeclared = 0
        case _0to5minutes = 1
        case _5to60minutes = 2
        case _1to6hours = 3
        case _6to24hours = 4
        case _1to4days = 5
        case _4to16days = 6
        case over16days = 7
    }
    var playTime: PlayTime

    var sampleContentProvided: Bool

    enum UserStatus: Int, Codable {
        case undeclared = 0
        case active = 1
        case suspended = 2
        case terminated = 3
        case limited = 4
    }
    var userStatus: UserStatus

}
