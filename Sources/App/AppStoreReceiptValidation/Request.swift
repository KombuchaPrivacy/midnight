/*
 * From https://github.com/slashmo/swift-app-store-receipt-validation
 * Author: Moritz Lang
 * License: Apache 2.0
 */

import Vapor

extension AppStore {
    enum Environment: String, Codable {
        case sandbox = "Sandbox"
        case production = "Production"

        var url: String {
            switch self {
            case .sandbox:
                return "https://sandbox.itunes.apple.com/verifyReceipt"
            case .production:
                return "https://buy.itunes.apple.com/verifyReceipt"
            }
        }
    }
}

extension AppStore {
    public struct Request: Content {
        let receiptData: String
        let password: String?
        let excludeOldTransactions: Bool?

        enum CodingKeys: String, CodingKey {
            case receiptData = "receipt-data"
            case password
            case excludeOldTransactions = "exclude-old-transactions"
        }
    }
}

extension AppStore {
    struct Status: Codable {
        let status: Int
    }

    public struct Response: Content {
        let receipt: Receipt // json
        let latestReceipt: String?
        let latestReceiptInfo: Receipt? // json
//    let latestExpiredReceiptInfo: Any? // json
//    let pendingRenewalInfo: Any?
        let isRetryable: Bool?
        let environment: Environment

        enum CodingKeys: String, CodingKey {
            case receipt
            case latestReceipt = "latest_receipt"
            case latestReceiptInfo = "latest_receipt_info"
            case isRetryable = "is-retryable"
            case environment
        }
    }
}

