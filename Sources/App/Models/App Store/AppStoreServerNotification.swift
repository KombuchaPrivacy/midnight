//
//  AppStoreServerNotification.swift
//  
//
//  Created by Charles Wright on 7/22/21.
//

import Foundation
import Vapor

// This class implements the JSON structure described in the Apple docs here:
// https://developer.apple.com/documentation/appstoreservernotifications/responsebody

struct AppStoreServerNotification: Content {

    // auto_renew_adam_id
    // string
    // An identifier that App Store Connect generates and the App Store uses to uniquely identify the auto-renewable subscription that the user’s subscription renews. Treat this value as a 64-bit integer.
    var autoRenewAdamId: String

    // auto_renew_product_id
    // string
    // The product identifier of the auto-renewable subscription that the user’s subscription renews.
    var autoRenewProductId: String

    // auto_renew_status
    // string
    // The current renewal status for an auto-renewable subscription product. Note that these values are different from those of the auto_renew_status in the receipt.
    // Possible values: true, false
    var autoRenewStatus: Bool

    // auto_renew_status_change_date
    // string
    // The time at which the user turned on or off the renewal status for an auto-renewable subscription, in a date-time format similar to the ISO 8601 standard.
    var autoRenewStatusChangeDate: Date?

    // auto_renew_status_change_date_ms
    // string
    // The time at which the user turned on or off the renewal status for an auto-renewable subscription, in UNIX epoch time format, in milliseconds. Use this time format to process dates.
    var autoRenewStatusChangeDateMs: Date

    // auto_renew_status_change_date_pst
    // string
    // The time at which the user turned on or off the renewal status for an auto-renewable subscription, in the Pacific time zone.
    var autoRenewStatusChangeDatePst: Date?

    // environment
    // string
    // The environment for which App Store generated the receipt.
    // Possible values: Sandbox, PROD
    enum Environment: String, Codable {
        case sandbox = "Sandbox"
        case prod = "PROD"
    }
    var environment: Environment

    // expiration_intent
    // integer
    // The reason a subscription expired. This field is only present for an expired auto-renewable subscription. See expiration_intent for more information.
    // https://developer.apple.com/documentation/appstorereceipts/expiration_intent
    enum ExpirationIntent: Int, Codable {
        case customerCanceled = 1
        case billingError = 2
        case priceIncrease = 3
        case notAvailable = 4
        case unknownError = 5
    }
    var expirationIntent: ExpirationIntent?

    // notification_type
    // notification_type
    // The subscription event that triggered the notification.
    // https://developer.apple.com/documentation/appstoreservernotifications/notification_type
    enum NotificationType: String, Codable {
        case cancel = "CANCEL"
        case consumptionRequest = "CONSUMPTION_REQUEST"
        case didChangeRenewalPref = "DID_CHANGE_RENEWAL_PREF"
        case didChangeRenewalStatus = "DID_CHANGE_RENEWAL_STATUS"
        case didFailToRenew = "DID_FAIL_TO_RENEW"
        case didRecover = "DID_RECOVER"
        case didRenew = "DID_RENEW"
        case initialBuy = "INITIAL_BUY"
        case interactiveRenewal = "INTERACTIVE_RENEWAL"
        case priceIncreaseConsent = "PRICE_INCREASE_CONSENT"
        case refund = "REFUND"
        case revoke = "REVOKE"
        // case RENEWAL (DEPRECATED)
    }
    var notificationType: NotificationType

    // password
    // string
    // The same value as the shared secret you submit in the password field of the requestBody when validating receipts.
    var password: String

    // unified_receipt
    // unified_receipt
    // An object that contains information about the most-recent, in-app purchase transactions for the app.
    // https://developer.apple.com/documentation/appstoreservernotifications/unified_receipt
    struct UnifiedReceipt: Codable {

        // environment
        // string
        // The environment for which App Store generated the receipt.
        // Possible values: Sandbox, Production
        // Argh WTF why isn't this the same as the Environment above???
        enum Environment: String, Codable {
            case sandbox = "Sandbox"
            case production = "Production"
        }
        var environment: Environment

        // latest_receipt
        // byte
        // The latest Base64-encoded app receipt.
        var latestReceipt: String

        // latest_receipt_info
        // [unified_receipt.Latest_receipt_info]
        // An array that contains the latest 100 in-app purchase transactions of the decoded value in latest_receipt. This array excludes transactions for consumable products your app has marked as finished. The contents of this array are identical to those in responseBody.Latest_receipt_info in the verifyReceipt endpoint response for receipt validation.
        // https://developer.apple.com/documentation/appstoreservernotifications/unified_receipt/latest_receipt_info
        struct LatestReceiptInfo: Codable {
            // cancellation_date
            // string
            // The time when Apple customer support canceled a transaction, in a date-time format similar to the ISO 8601. This field is only present for refunded transactions.
            var cancellationDate: Date?

            // cancellation_date_ms
            // string
            // The time when Apple customer support canceled a transaction, or the time when the user upgraded an auto-renewable subscription plan, in UNIX epoch time format, in milliseconds. This field is only present for refunded transactions. Use this time format for processing dates. For more information, see cancellation_date_ms.
            var cancellationDateMs: Date?

            // cancellation_date_pst
            // string
            // The time when Apple customer support canceled a transaction, in the Pacific Time zone. This field is only present for refunded transactions.
            var cancellationDatePst: Date?

            // cancellation_reason
            // string
            // The reason for a refunded transaction. When a customer cancels a transaction, the App Store gives them a refund and provides a value for this key. A value of “1” indicates that the customer canceled their transaction due to an actual or perceived issue within your app. A value of “0” indicates that the transaction was canceled for another reason; for example, if the customer made the purchase accidentally.
            // Possible values: 1, 0
            enum CancellationReason: String, Codable {
                case customerCanceled = "1"
                case other = "0"
            }
            var cancellationReason: CancellationReason?

            // expires_date
            // string
            // The time when a subscription expires or when it will renew, in UNIX epoch time format, in milliseconds. Use this time format for processing dates. Note that this field is called expires_date_ms in the receipt.
            var expiresDate: Date?

            // expires_date_ms
            // string
            // The time when a subscription expires or when it will renew, in UNIX epoch time format, in milliseconds. Use this time format for processing dates. For more information, see expires_date_ms.
            var expiresDateMs: Date?

            // expires_date_pst
            // string
            // The time when a subscription expires or when it will renew, in the Pacific Time zone.
            var expiresDatePst: Date?

            // in_app_ownership_type
            // string
            // A value that indicates whether the user is the purchaser of the product, or is a family member with access to the product through Family Sharing. See in_app_ownership_type for more information.
            // Possible values: FAMILY_SHARED, PURCHASED
            enum InAppOwnershipType: String, Codable {
                case familyShared = "FAMILY_SHARED"
                case purchased = "PURCHASED"
            }
            var inAppOwnershipType: InAppOwnershipType

            // is_in_intro_offer_period
            // string
            // An indicator of whether an auto-renewable subscription is in the introductory price period. For more information, see is_in_intro_offer_period.
            // Possible values: true, false
            var isInIntroOfferPeriod: Bool

            // is_trial_period
            // string
            // An indicator of whether a subscription is in the free trial period. For more information, see is_trial_period.
            // Possible values: true, false
            var isTrialPeriod: Bool

            // is_upgraded
            // string
            // An indicator that the system canceled a subscription because the user upgraded. This field is only present for upgrade transactions.
            //Value: true
            var isUpgraded: Bool?

            // offer_code_ref_name
            // string
            // The reference name of a subscription offer you configured in App Store Connect. This field is present when a customer redeemed a subscription offer code. For more information, see offer_code_ref_name.
            var offerCodeRefName: String?

            // original_purchase_date
            // string
            // The time of the original app purchase, in a date-time format similar to the ISO 8601 standard.
            var originalPurchaseDate: Date?

            // original_purchase_date_ms
            // string
            // The time of the original app purchase, in UNIX epoch time format, in milliseconds. Use this time format for processing dates. This value indicates the date of the subscription’s initial purchase. The original purchase date applies to all product types and remains the same in all transactions for the same product ID. This value corresponds to the original transaction’s transactionDate property in StoreKit.
            var originalPurchaseDateMs: Date

            // original_purchase_date_pst
            // string
            // The time of the original app purchase, in the Pacific time zone.
            var originalPurchaseDatePst: Date?

            // original_transaction_id
            // string
            // The transaction identifier of the original purchase. For more information, see original_transaction_id.
            var originalTransactionId: String

            // promotional_offer_id
            // string
            // The identifier of the subscription offer redeemed by the user. For more information, see promotional_offer_id.
            var promotionalOfferId: String?

            // product_id
            // string
            // The unique identifier of the product purchased. You provide this value when creating the product in App Store Connect, and it corresponds to the productIdentifier property of the SKPayment object stored in the transaction’s payment property.
            var productId: String

            // purchase_date
            // string
            // The time when the App Store charged the user’s account for a subscription purchase or renewal after a lapse, in a date-time format similar to the ISO 8601 standard.
            var purchaseDate: Date?

            // purchase_date_ms
            // string
            // The time when the App Store charged the user’s account for a subscription purchase or renewal after a lapse, in the UNIX epoch time format, in milliseconds. Use this time format for processing dates.
            var purchaseDateMs: Date

            // purchase_date_pst
            // string
            // The time when the App Store charged the user’s account for a subscription purchase or renewal after a lapse, in the Pacific time zone.
            var purchaseDatePst: Date?

            // quantity
            // string
            // The number of consumable products purchased. This value corresponds to the quantity property of the SKPayment object stored in the transaction’s payment property. The value is usually “1” unless modified with a mutable payment. The maximum value is “10”.
            var quantity: UInt

            // subscription_group_identifier
            // string
            // The identifier of the subscription group to which the subscription belongs. The value for this field is identical to the subscriptionGroupIdentifier property in SKProduct.
            var subscriptionGroupIdentifier: String

            // transaction_id
            // string
            // A unique identifier for a transaction such as a purchase, restore, or renewal. For more information, see transaction_id.
            var transactionId: String

            // web_order_line_item_id
            // string
            // A unique identifier for purchase events across devices, including subscription-renewal events. This value is the primary key to identify subscription purchases.
            var webOrderLineItemId: String
        }
        var latestReceiptInfo: [LatestReceiptInfo]

        // pending_renewal_info
        // [unified_receipt.Pending_renewal_info]
        // An array where each element contains the pending renewal information for each auto-renewable subscription identified in product_id. The contents of this array are identical to those in responseBody.Pending_renewal_info in the verifyReceipt endpoint response for receipt validation.
        // https://developer.apple.com/documentation/appstoreservernotifications/unified_receipt/pending_renewal_info
        struct PendingRenewalInfo: Codable {
            //auto_renew_product_id
            // string
            //The current renewal preference for the auto-renewable subscription. The value for this key corresponds to the productIdentifier property of the product that the customer’s subscription renews.
            var autoRenewProductId: String

            // auto_renew_status
            // string
            // The current renewal status for the auto-renewable subscription. For more information, see auto_renew_status.
            // Possible values: 1, 0
            // https://developer.apple.com/documentation/appstorereceipts/auto_renew_status
            enum AutoRenewStatus: String, Codable {
                case willRenew = "1"
                case willNotRenew = "0"
            }
            var autoRenewStatus: AutoRenewStatus

            // expiration_intent
            // string
            // The reason a subscription expired. This field is only present for a receipt that contains an expired, auto-renewable subscription. For more information, see expiration_intent.
            // Possible values: 1, 2, 3, 4, 5
            var expirationIntent: ExpirationIntent

            // grace_period_expires_date
            // string
            //The time at which the grace period for subscription renewals expires, in a date-time format similar to the ISO 8601.
            var gracePeriodExpiresDate: Date

            // grace_period_expires_date_ms
            // string
            // The time at which the grace period for subscription renewals expires, in UNIX epoch time format, in milliseconds. This key is only present for apps that have Billing Grace Period enabled and when the user experiences a billing error at the time of renewal. Use this time format for processing dates.
            var gracePeriodExpiresDateMs: Date

            // grace_period_expires_date_pst
            // string
            // The time at which the grace period for subscription renewals expires, in the Pacific Time zone.
            var gracePeriodExpiresDatePst: Date

            // is_in_billing_retry_period
            // string
            // A flag that indicates Apple is attempting to renew an expired subscription automatically. This field is only present if an auto-renewable subscription is in the billing retry state. For more information, see is_in_billing_retry_period.
            // Possible values: 1, 0
            // https://developer.apple.com/documentation/appstorereceipts/is_in_billing_retry_period
            enum IsInBillingRetryPeriod: String, Codable {
                case yes = "1"
                case no = "0"
            }
            var isInBillingRetryPeriod: IsInBillingRetryPeriod

            // offer_code_ref_name
            // string
            // The reference name of a subscription offer you configured in App Store Connect. This field is present when a customer redeemed a subscription offer code. For more information, see offer_code_ref_name.
            var offerCodeRefName: String

            // original_transaction_id
            // string
            // The transaction identifier of the original purchase.
            var originalTransactionId: String

            // price_consent_status
            // string
            // The price consent status for a subscription price increase. This field is present only if App Store notified the customer of the price increase. The default value is "0" and changes to "1" if the customer consents.
            // Possible values: 1, 0
            enum PriceConsentStatus: String, Codable {
                case yes = "1"
                case no = "0"
            }
            var priceConsentStatus: PriceConsentStatus

            // product_id
            // string
            // The unique identifier of the product purchased. You provide this value when creating the product in App Store Connect, and it corresponds to the productIdentifier property of the SKPayment object stored in the transaction’s payment property.
            var productId: String

            // promotional_offer_id
            // string
            // The identifier of the promotional offer for an auto-renewable subscription that the user redeemed. You provide this value in the Promotional Offer Identifier field when you create the promotional offer in App Store Connect. For more information, see promotional_offer_id.
            var promotionalOfferId: String
        }
        var pendingRenewalInfo: [PendingRenewalInfo]?

        // status
        // integer
        // The status code, where 0 indicates that the notification is valid.
        // Value: 0
        var status: Int
    }

    // bid
    // string
    // A string that contains the app bundle ID.
    var bid: String

    // bvrs
    // string
    // A string that contains the app bundle version.
    var bvrs: String

    // And all the latest_receipt stuff is deprecated as of March 2021
}
