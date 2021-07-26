//
//  AppStoreNotificationController.swift
//  
//
//  Created by Charles Wright on 7/26/21.
//

import Foundation
import Vapor
import Fluent

struct AppStoreNotificationController {
    var app: Application
    var homeserver: URL

    typealias NotificationHandler = (Request, AppStoreServerNotification) -> EventLoopFuture<Void>

    func getHandler(for notification: AppStoreServerNotification) -> NotificationHandler {
        switch notification.notificationType {
        case .cancel:
            return self.handleCancel
        case .consumptionRequest:
            return self.handleConsumptionRequest
        case .didChangeRenewalPref:
            return self.handleDidChangeRenewalPref
        case .didChangeRenewalStatus:
            return self.handleDidChangeRenewalStatus
        case .didFailToRenew:
            return self.handleDidFailToRenew
        case .didRecover:
            return self.handleDidRecover
        case .didRenew:
            return self.handleDidFailToRenew
        case .initialBuy:
            return self.handleInitialBuy
        case .interactiveRenewal:
            return self.handleInteractiveRenewal
        case .priceIncreaseConsent:
            return self.handlePriceIncreaseConsent
        case .refund:
            return self.handleRefund
        case .revoke:
            return self.handleRevoke
        }
    }

    func handleNotification(for req: Request)
    -> EventLoopFuture<Void>
    {
        guard let notification = try? req.content.decode(AppStoreServerNotification.self) else {
            // FIXME Change this to .badRequest once we're confident that our parsing logic is correct
            return req.eventLoop.makeFailedFuture(Abort(.internalServerError, reason: "Failed to parse request"))
        }

        let handler: NotificationHandler = self.getHandler(for: notification)
        return handler(req, notification)

    }



    func handleCancel(for req: Request, with notification: AppStoreServerNotification)
    -> EventLoopFuture<Void>
    {
        /*
         CANCEL
         Indicates that Apple Support canceled the auto-renewable subscription and the customer received a refund as of the timestamp in cancellation_date_ms.
         */
        return req.eventLoop.makeFailedFuture(Abort(.notImplemented))
    }

    func handleConsumptionRequest(for req: Request, with notification: AppStoreServerNotification)
    -> EventLoopFuture<Void>
    {
        /*
         CONSUMPTION_REQUEST
         Indicates that the customer initiated a refund request for a consumable in-app purchase, and the App Store is requesting that you provide consumption data. For more information, see Send Consumption Information.
         */
        return req.eventLoop.makeFailedFuture(Abort(.notImplemented))
    }

    func handleDidChangeRenewalPref(for req: Request, with notification: AppStoreServerNotification)
    -> EventLoopFuture<Void>
    {
        /*
         DID_CHANGE_RENEWAL_PREF
         Indicates that the customer made a change in their subscription plan that takes effect at the next renewal. The currently active plan isn’t affected.
         */
        return req.eventLoop.makeFailedFuture(Abort(.notImplemented))
    }

    func handleDidChangeRenewalStatus(for req: Request, with notification: AppStoreServerNotification)
    -> EventLoopFuture<Void>
    {
        /*
         DID_CHANGE_RENEWAL_STATUS
         Indicates a change in the subscription renewal status. In the JSON response, check auto_renew_status_change_date_ms to know the date and time of the last status update. Check auto_renew_status to know the current renewal status.
         */
        return req.eventLoop.makeFailedFuture(Abort(.notImplemented))
    }

    func handleDidFailToRenew(for req: Request, with notification: AppStoreServerNotification)
    -> EventLoopFuture<Void>
    {
        /*
         DID_FAIL_TO_RENEW
         Indicates a subscription that failed to renew due to a billing issue. Check is_in_billing_retry_period to know the current retry status of the subscription. Check grace_period_expires_date to know the new service expiration date if the subscription is in a billing grace period.
         */
        return req.eventLoop.makeFailedFuture(Abort(.notImplemented))
    }

    func handleDidRecover(for req: Request, with notification: AppStoreServerNotification)
    -> EventLoopFuture<Void>
    {
        /*
         DID_RECOVER
         Indicates a successful automatic renewal of an expired subscription that failed to renew in the past. Check expires_date to determine the next renewal date and time.
         */
        return req.eventLoop.makeFailedFuture(Abort(.notImplemented))
    }

    func handleDidRenew(for req: Request, with notification: AppStoreServerNotification)
    -> EventLoopFuture<Void>
    {
        /*
         DID_RENEW
         Indicates that a customer’s subscription has successfully auto-renewed for a new transaction period.
         */
        return req.eventLoop.makeFailedFuture(Abort(.notImplemented))
    }

    func handleInitialBuy(for req: Request, with notification: AppStoreServerNotification)
    -> EventLoopFuture<Void>
    {
        /*
         INITIAL_BUY
         Occurs at the user’s initial purchase of the subscription. Store latest_receipt on your server as a token to verify the user’s subscription status at any time by validating it with the App Store.
         */
        return req.eventLoop.makeFailedFuture(Abort(.notImplemented))
    }

    func handleInteractiveRenewal(for req: Request, with notification: AppStoreServerNotification)
    -> EventLoopFuture<Void>
    {
        /*
         INTERACTIVE_RENEWAL
         Indicates the customer renewed a subscription interactively, either by using your app’s interface, or on the App Store in the account’s Subscriptions settings. Make service available immediately.
         */
        return req.eventLoop.makeFailedFuture(Abort(.notImplemented))
    }

    func handlePriceIncreaseConsent(for req: Request, with notification: AppStoreServerNotification)
    -> EventLoopFuture<Void>
    {
        /*
         PRICE_INCREASE_CONSENT
         Indicates that App Store has started asking the customer to consent to your app’s subscription price increase. In the unified_receipt.Pending_renewal_info object, the price_consent_status value is 0, indicating that App Store is asking for the customer’s consent, and hasn’t received it. The subscription won’t auto-renew unless the user agrees to the new price. When the customer agrees to the price increase, the system sets price_consent_status to 1. Check the receipt using verifyReceipt to view the updated price-consent status.
         */
        return req.eventLoop.makeFailedFuture(Abort(.notImplemented))
    }

    func handleRefund(for req: Request, with notification: AppStoreServerNotification)
    -> EventLoopFuture<Void>
    {
        /*
         REFUND
         Indicates that the App Store successfully refunded a transaction for a consumable in-app purchase, a non-consumable in-app purchase, or a non-renewing subscription. The cancellation_date_ms contains the timestamp of the refunded transaction. The original_transaction_id and product_id identify the original transaction and product. The cancellation_reason contains the reason.
         */
        return req.eventLoop.makeFailedFuture(Abort(.notImplemented))
    }

    func handleRevoke(for req: Request, with notification: AppStoreServerNotification)
    -> EventLoopFuture<Void>
    {
        /*
         REVOKE
         Indicates that an in-app purchase the user was entitled to through Family Sharing is no longer available through sharing. StoreKit sends this notification when a purchaser disabled Family Sharing for a product, the purchaser (or family member) left the family group, or the purchaser asked for and received a refund. Your app will also receive a paymentQueue(_:didRevokeEntitlementsForProductIdentifiers:) call. For more information about Family Sharing, see Supporting Family Sharing in Your App.
         */
        return req.eventLoop.makeFailedFuture(Abort(.notImplemented))
    }
}
