//
//  ReceiptValidationRequestBody.swift
//  
//
//  Created by Charles Wright on 9/6/21.
//

import Foundation
import Vapor

struct ReceiptValidationRequestBody: Content {
    var receiptData: String
    var password: String
    var excludeOldTransactions: Bool

    enum CodingKeys: String, CodingKey {
        case receiptData = "receipt-data"
        case password = "password"
        case excludeOldTransactions = "exclude-old-transactions"
    }
}
