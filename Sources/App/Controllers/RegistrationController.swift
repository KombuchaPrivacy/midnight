//
//  RegistrationController.swift
//  
//
//  Created by Charles Wright on 4/1/21.
//

import Foundation
import Vapor
import Fluent

let LOGIN_STAGE_SIGNUP_TOKEN = "social.kombucha.login.signup_token"
let LOGIN_STAGE_APPLE_SUBSCRIPTION = "social.kombucha.login.subscription.apple"
let BUNDLE_ID_CIRCLES = "social.kombucha.circles"

let SUBSCRIPTION_OFFERINGS = ["social.kombucha.circles.standard01month", "social.kombucha.circles.standard12month"]

struct RegistrationController {
    var app: Application
    var homeserver: URL
    var apiVersions: [String]
    
    // MARK: Pending subscriptions
    func createPendingSubscription(for req: Request, given numSlots: Int) //throws
    -> EventLoopFuture<Void>
    {
        guard let session = req.uiaaSession else {
            return req.eventLoop.makeFailedFuture(Abort(.internalServerError, reason: "Error looking up session data"))
        }
        guard let token = session.data["token"],
              let sessionId = session.id?.string else {
            return req.eventLoop.makeFailedFuture(Abort(.internalServerError, reason: "Error looking up session data"))
        }
        
        req.logger.debug("PENDING\tCreating a pending subscription")
        return req.db.transaction { database in
            // Add our current user to the list of pending registrations for our token
            let in30minutes = Date(timeIntervalSinceNow: 30 * 60)
            let pending = PendingSubscription(token: token, session: sessionId, expiration: in30minutes)
            return pending.create(on: database)
                .flatMap {
                    let now = Date(timeIntervalSinceNow: 0.0)
                    return PendingSubscription.query(on: database)
                        .filter(\.$token == token)
                        .filter(\.$expiresAt > now)
                        .count()
                        .flatMap { count in
                            if count <= numSlots {
                                req.logger.debug("PENDING\tSuccess!  There are still available slots.")
                                return req.eventLoop.makeSucceededVoidFuture()
                            } else {
                                // There are now too many pending registrations for our token
                                req.logger.debug("PENDING\tFailure.  No remaining slots.  :(")
                                // Fail the transaction, and maybe if there was a race and multiple clients failed, then one of us can try again later and succeed in the future
                                return req.eventLoop.makeFailedFuture(Abort(.unauthorized, reason: "No slots available for the given token"))
                            }
                        }
                }
        }
    }
    
    func deletePendingSubscription(for req: Request) throws
    -> EventLoopFuture<Void>
    {
        guard let token = req.session.data["token"],
              let sessionId = req.session.id?.string else {
            return req.eventLoop.makeFailedFuture(Abort(.internalServerError, reason: "Error looking up session data"))
        }
        
        return PendingSubscription.query(on: req.db)
            .filter(\.$token == token)
            .filter(\.$sessionId == sessionId)
            .delete()
    }
    
    // MARK: Signup Tokens
    // Check the validity of the supplied token
    // Return the number of available registration slots for it
    func validateSignupToken(_ userToken: String, forRequest req: Request)
    -> EventLoopFuture<Int>
    {
        // Ok we got a token
        // 1. Is it valid?
        //   1.1. Are we even offering token auth right now?
        //   1.2. Is this a currently valid token that we have issued?
        // 2. Can we use it to register this user?
        //   2.1. Is the number of users registered with this token less than the maximum that the token allows?
        
        // The fact that we're here means that the site is running token auth
        // Right?
        
        // Very basic token validity checks
        let token = userToken
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard SignupToken.validateFormat(token: token) else {
            // FIXME We're going to have to create our own Abort/Error type
            // that includes Matrix-style JSON data in the response... argh.
            return req.eventLoop.makeFailedFuture(Abort(.forbidden, reason: "Invalid token"))
        }
        
        // Once we've got a token that's of the proper form,
        // Check to see if it's really one of ours
        let now = Date.init(timeIntervalSinceNow: 0.0)
        return SignupToken.query(on: req.db)
            .filter(\.$token == token)
            //.filter(\.$expiresAt < now)
            .sort(\.$createdAt)
            .first()
            .flatMap { maybeValidToken in
                guard let signupToken = maybeValidToken else {
                    return req.eventLoop.makeFailedFuture(Abort(.forbidden, reason: "No such token"))
                    //let err = ResponseErrorContent(errcode: "TOKEN_DOESNT_EXIST", error: "No such token")
                    //return err.encodeResponse(status: .forbidden, for: req)
                }
                req.logger.debug("TOKEN\tFound a token: \(signupToken.token) -- Expires at \(signupToken.expiresAt)")
                // Check whether the token is expired
                // If there's no expiration date, then the token is always valid for now
                guard signupToken.expiresAt ?? Date(timeIntervalSinceNow: 1000) > now else {
                    return req.eventLoop.makeFailedFuture(Abort(.forbidden, reason: "Token is expired"))
                    //let err = ResponseErrorContent(errcode: "TOKEN_EXPIRED", error: "Token is expired")
                    //return err.encodeResponse(status: .forbidden, for: req)
                }
                
                // So far so good.  We have a valid token.
                // Is it already full?  Or is there still at least one slot available?
                return Subscription.query(on: req.db)
                    .filter(\.$provider == "token")
                    .filter(\.$identifier == signupToken.token)
                    .count()
                    .flatMap { count in
                        // How many slots are still available?
                        let available = Int(signupToken.slots) - count
                        guard available > 0 else {
                            return req.eventLoop.makeFailedFuture(Abort(.forbidden, reason: "No more signups allowed with this token"))
                            //let err = ResponseErrorContent(errcode: "TOKEN_EXHAUSTED", error: "No more signups allowed with this token")
                            //return err.encodeResponse(status: .forbidden, for: req)
                        }
                        return req.eventLoop.makeSucceededFuture(available)
                    }
                
            }
    }
    
    func handleSignupTokenRequest(req: Request, token: String)
    -> EventLoopFuture<Response>
    {
        return validateSignupToken(token, forRequest: req)
            .flatMap { numSlots in
                // The token is valid
                // Save it in the request's session
                guard let session = req.uiaaSession else {
                    //return req.eventLoop.makeFailedFuture(Abort(.internalServerError, reason: "Couldn't find authentication session"))
                    let err = ResponseErrorContent(errcode: "M_INVALID_SESSION", error: "No valid session")
                    return err.encodeResponse(status: .internalServerError, for: req)
                }
                
                var state = session.data.state
                
                // Save the token with our session so we can find it later
                // We will need it at the end, when it's time to create the
                // subscription record in the database
                session.data["token"] = token
                
                // Create a pending "reservation" so the client will be able
                // to subscribe with this token
                return createPendingSubscription(for: req, given: numSlots).flatMap {

                    // Now that we have our pending slot in the database, we can go ahead with the registration process
                    // For now that means telling the client that their token-based auth was successful
                    
                    let flows = state.flows
                    let sessionId = state.session
                    
                    // Append this stage to the list of completed stages
                    var completed: [String] = state.completed ?? []
                    completed.append(LOGIN_STAGE_SIGNUP_TOKEN)
                    state.completed = completed
                    // Whoops, we also need to save this into our session state struct
                    session.data.state.completed = completed
                    /*
                    req.logger.debug("MIDNIGHT\tCompleted = \(completed)")
                    req.logger.debug("MIDNIGHT\tFlows =")
                    for flow in flows {
                        req.logger.debug("MIDNIGHT\t\t\(flow.stages)")
                    }
                    */
                    
                    // Are we done?
                    for flow in flows {
                        if flow.isSatisfiedBy(completed: completed) {
                            req.logger.debug("MIDNIGHT\tUIAA Auth is satisfied with auth flow: [\(flow.stages)]")
                            // We're done with the UIAA auth
                            // Matrix spec says we should service the request now
                            return proxyRequestToHomeserver(req: req).flatMap { hsResponse in
                                req.logger.debug("MIDNIGHT\tGot HS response for /register")
                                req.logger.debug("\t\tStatus = \(hsResponse.status)")
                                if hsResponse.status == .forbidden {
                                    if let err = try? hsResponse.content.decode(ResponseErrorContent.self) {
                                        req.logger.debug("\t\tError code: \(err.errcode)")
                                        req.logger.debug("\t\tError: \(err.error)")
                                    }
                                }
                                return proxyResponseToClientUnmodified(res: hsResponse, for: req)
                            }
                        }
                    }
                    // If we're still here, then we're not done
                    req.logger.debug("MIDNIGHT\tMaking progress through UIAA auth.  Sending 401 to proceed.")
                    // Send another 401 so the client can continue the UIAA process
                    
                    // Copy the list of params (if any)
                    let params = state.params
                    let responseData = UiaaSessionState(flows: flows,
                                                        params: params,
                                                        completed: completed,
                                                        session: sessionId)
                    let status: HTTPStatus = .unauthorized
                    return responseData.encodeResponse(status: status, for: req)
                }
            }
    }

    func handleAppleSubscriptionRequest(req: Request, receipt: String)
    -> EventLoopFuture<Response>
    {
        // Send a request to Apple to validate the receipt
        //   - First try the production App Store URL https://buy.itunes.apple.com/verifyReceipt
        //   - If we can't validate with the production App Store, try the sandbox environment https://sandbox.itunes.apple.com/verifyReceipt

        let appStoreClient = AppStore.Client(vaporClient: req.client, secret: "foo")

	return appStoreClient.validateReceipt(receipt, excludeOldTransactions: false).flatMap { (appStoreResponse) -> EventLoopFuture<Response> in
            req.logger.debug("APPLE\tGot response from the App Store")
            let receipt = appStoreResponse.receipt
            guard let latestReceipt = appStoreResponse.latestReceiptInfo else {
                return req.eventLoop.makeFailedFuture(Abort(.internalServerError, reason: "Failed to get latest receipt"))
            }
            req.logger.debug("APPLE\tGot receipt and latest receipt")
            
            guard receipt.bundleId == BUNDLE_ID_CIRCLES else {
                return req.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "Incorrect bundle ID"))
            }

            // Now let's look at the in-app purchases
            // Did the user purchase a subscription?
            for purchase in latestReceipt.inApp {
                let productId = purchase.productId
                let originalTransactionId = purchase.originalTransactionId
                req.logger.debug("APPLE\tFound in-app purchase for product [\(productId)] with original transaction ID [\(originalTransactionId)]")
                guard let expirationDate = purchase.subscriptionExpirationDate else {
                    req.logger.debug("APPLE\tProduct [\(productId)] has no expiration date")
                    continue
                }
                req.logger.debug("APPLE\tProduct [\(productId)] will expire on \(expirationDate)")

                // Is this purchase the one that the user needed?
                if SUBSCRIPTION_OFFERINGS.contains(productId) {
                    req.logger.debug("APPLE\tCreating a new account with subscription product [\(productId)]")
                    //   * Does the product ID match one of our current subscription offerings?
                    //     * If so, is there at least one available slot remaining for this purchase?  Or has the user already created all available accounts with this one?
                    //       * If there are slots remaining, claim one of them
                    //         * Once we've claimed a spot, tell the user to proceed with the UIAA (return HTTP 401)

                    // This is just here so that the function will compile
                    return req.eventLoop.makeFailedFuture(Abort(.notImplemented, reason: "Not implemented yet"))
                }
            }

            // If we checked through the whole list, and we still didn't find a valid subscription,
            // then the user must have bought something else.  Reject the request.
            return req.eventLoop.makeFailedFuture(Abort(.forbidden, reason: "Failed to find a valid subscription"))
        }

        // Then (from https://developer.apple.com/documentation/storekit/original_api_for_in-app_purchase/validating_receipts_with_the_app_store)
        /*
        Parse the Response
        The App Store's response payload is a JSON object that contains the keys and values detailed in responseBody.

        The in_app array contains the non-consumable, non-renewing subscription, and auto-renewable subscription items previously purchased by the user. Check the values in the response for these in-app purchase types to verify transactions as needed.

        For auto-renewable subscription items, parse the response to get information about the currently active subscription period. When you validate the receipt for a subscription, latest_receipt contains the latest encoded receipt, which is the same as the value for receipt-data in the request, and latest_receipt_info contains all the transactions for the subscription, including the initial purchase and subsequent renewals but not including any restores.

        You can use these values to check whether an auto-renewable subscription has expired. Use these values along with the expiration_intent subscription field to get the reason for expiration.
        */

        // Ok so it looks like we need to look at:
        //   * latest_receipt
        //   * latest_receipt_info
        //   * latest_receipt_info -> initial purchase
        //   * expiration_intent (???)
    }
    
    // MARK: handle UIAA Request
    func handleUiaaRequest(req: Request, with data: RegistrationRequestBody) //throws
    -> EventLoopFuture<Response>
    {
        // Is this UIAA stage one of ours?
        // - If so, handle it.
        // - If not, pass the request along to the homeserver.
        //   Maybe it knows what to do with this one.
        switch data.auth.type {
        case LOGIN_STAGE_SIGNUP_TOKEN:
            req.logger.debug("TOKEN\tFound a token request")
            guard let token = data.auth.token else {
                //return req.eventLoop.makeFailedFuture(Abort(HTTPStatus.badRequest, reason: "No token provided"))
                let err = ResponseErrorContent(errcode: "TOKEN_MISSING", error: "No token provided")
                return err.encodeResponse(status: .badRequest, for: req)
            }
            return handleSignupTokenRequest(req: req, token: token)
        case LOGIN_STAGE_APPLE_SUBSCRIPTION:
            req.logger.debug("APPLE\tFound an Apple subscription request")
            guard let receipt = data.auth.appleReceipt else {
                let err = ResponseErrorContent(errcode: "RECEIPT_MISSING", error: "No App Store receipt provided")
                return err.encodeResponse(status: .badRequest, for: req)
            }
            return handleAppleSubscriptionRequest(req: req, receipt: receipt)
        default:
            req.logger.debug("MIDNIGHT\tWe don't handle requests of type \(data.auth.type)")
            guard let session = req.uiaaSession,
                  let completed = session.data.state.completed,
                  completed.contains(LOGIN_STAGE_SIGNUP_TOKEN) else {
                req.logger.info("MIDNIGHT\tClient attempted \(data.auth.type) before completing token auth")
                let err = ResponseErrorContent(errcode: "TOKEN_STAGE_INCOMPLETE", error: "Must complete token auth before attempting other stages")
                return err.encodeResponse(status: .forbidden, for: req)
            }
            return proxyRequestToHomeserver(req: req).flatMap { hsResponse in
                return handleUiaaResponse(res: hsResponse, for: req)
            }
        }
    }
    
    // MARK: proxyResponse..Unmodified
    func proxyResponseToClientUnmodified(res: ClientResponse, for req: Request)
    -> EventLoopFuture<Response>
    {
        //req.logger.debug("\t\(#function): Client response status = \(res.status)")
        return res.encodeResponse(for: req)
    }
    
    // MARK: handle UIAA Response
    func handleUiaaResponse(res: ClientResponse, for req: Request)
    -> EventLoopFuture<Response>
    {
        req.logger.debug("MIDNIGHT\tHandling UIAA Response")
        
        // The only response that we need to work with is a 401
        // Everything else we return unmodified
        guard res.status == HTTPStatus.unauthorized else {
            req.logger.debug("MIDNIGHT\tUIAA response is not 401; Returning unmodified")
            // FIXME Make sure that 401's are all we need to touch
            //       Could there be 403's where we need to re-write the flows?
            return proxyResponseToClientUnmodified(res: res, for: req)
        }
        
        guard let hsResponseData = try? res.content.decode(UiaaSessionState.self) else {
            //return req.eventLoop.makeFailedFuture(Abort(.internalServerError, reason: "Couldn't parse Matrix data"))
            let err = ResponseErrorContent(errcode: "M_WTF_JUST_HAPPENED", error: "Couldn't parse Matrix data from homeserver")
            return err.encodeResponse(for: req)
        }
        
        if let matrixError = try? res.content.decode(ResponseErrorContent.self) {
            req.logger.info("MIDNIGHT\tUIAA Response has an error: \(matrixError.errcode): \(matrixError.error)")
        }
        
        req.logger.debug("MIDNIGHT\tRe-writing UIAA flows from the homeserver")
        var ourResponseData = hsResponseData
        ourResponseData.flows = []
        for var flow in hsResponseData.flows {
            if !flow.stages.contains(LOGIN_STAGE_SIGNUP_TOKEN) {
                //req.logger.debug("MIDNIGHT\tInserting signup_token in auth flows")
                flow.stages.insert(LOGIN_STAGE_SIGNUP_TOKEN, at: 0)
                //req.logger.debug("MIDNIGHT\tStages = \(flow.stages)")
            }
            //req.logger.debug("MIDNIGHT\tNew flow = \(flow.stages)")
            ourResponseData.flows.append(flow)
            req.logger.debug("MIDNIGHT\tCompleted = \(ourResponseData.completed ?? [])")
        }
        //req.logger.debug("MIDNIGHT\t\(#function): Returning response data = \(ourResponseData)")
        
        ourResponseData.completed = req.uiaaSession?.data.state.completed
        
        return ourResponseData.encodeResponse(status: .unauthorized, for: req)
    }
    
    // MARK: Username validation
    func validateUsernameFormat(username: String)
    -> Bool {
        let ALLOWED_PUNCTUATION = "-.=_"
        
        func getLocalPart(username: String) -> Substring? {
            if username.contains(":") {
                let toks = username.lowercased().split(separator: ":")
                if toks.count != 2 {
                    return nil
                }
                let serverName = toks.last
                if serverName != "kombucha.social" {
                    return nil
                }
                let user = toks.first!
                if user.starts(with: "@") {
                    return user.dropFirst()
                }
                return user
            } else {
                // They're only asking for a bare username, no domain
                return username.suffix(from: username.startIndex)
            }
        }
        
        guard let localPart = getLocalPart(username: username) else {
            return false
        }

        
        // cvw: Not part of the Matrix spec, but IMO a slash is totally shady in
        //      something that will make up part of a URL path.
        //      Rather than chance it and hope that every stage in our chain of
        //      proxies (nginx etc) parses the Matrix endpoint URLs correctly,
        //      we're just going to disallow the slash from the start
        //      Heh.  If the guy from Guns N Roses, or Slashdot, wants an account,
        //      they can talk to us individually.
        if localPart.contains("/") {
            return false
        }
        // This one is from the Matrix spec
        if localPart.count > 255 - self.homeserver.host!.count {
            return false
        }
        // This one is from me, to keep our usernames looking (somewhat) sane and manageable:
        if localPart.count > 32 {
            return false
        }
        
        // FIXME What if we want to make short usernames a "premium" / paid feature?
        if localPart.count < 8 {
            return false
        }
        
        // We also want to check for some basic readability

        var numAlphas = UInt(0);
        var numNumerics = UInt(0);
        var numPuncts = UInt(0);
        
        for c in localPart {
            if !(c.isNumber || c.isLetter || ALLOWED_PUNCTUATION.contains(c)) {
                return false
            } else if c.isNumber {
                numNumerics += 1
            } else if c.isLetter {
                numAlphas += 1
            } else if c.isPunctuation {
                numPuncts += 1
            }
        }
        
        // No usernames like ..._--_... or 911
        // This also disallows raw phone numbers...  That's probably good.
        // Although somebody could still do 867-5309_Jenny or 1-800-GOT-JUNK etc.
        // I guess that's OK.
        if numAlphas < 2 {
            return false
        }
        
        // No using leading or trailing punctuation to impersonate someone else,
        // e.g. "_alice" to look like "alice" or "bob." to look like "bob"
        // Sorry "__=-=__CoolDude__=-=__" this might not be the place for you...
        if localPart.first!.isPunctuation || localPart.last!.isPunctuation {
            return false
        }
        
        // Whew.  If we made it all the way to here, then the username must be OK.
        return true
    }
    
    func validateAgainstBadlist(_ string: String, for req: Request)
    -> EventLoopFuture<Bool>
    {
        let lower = string.lowercased()
        let BADLIST_CHECK_LEETSPEAK: Bool = true
        
        // FIXME Cache this
        return BadWord.query(on: req.db)
            .field(\.$word)
            .all()
            .map { (badWords) -> Bool in
                
                for badWord in badWords {
                    if lower.contains(badWord.word) {
                        return false
                    }
                    if BADLIST_CHECK_LEETSPEAK {
                        let leetspeak = badWord.word
                            .replacingOccurrences(of: "4", with: "a")
                            .replacingOccurrences(of: "3", with: "e")
                            .replacingOccurrences(of: "1", with: "i")
                            .replacingOccurrences(of: "0", with: "o")
                            .replacingOccurrences(of: "5", with: "s")
                            .replacingOccurrences(of: "7", with: "t")
                            .replacingOccurrences(of: "9", with: "g")
                            if lower.contains(leetspeak) {
                                return false
                            }
                    }
                }
        
                // If we didn't match any of the bad words, it's probably OK
                return true
            }
    }
    
    func validateAgainstReservedWords(_ string: String, for req: Request)
    -> EventLoopFuture<Bool>
    {
        let lower = string.lowercased()
        
        // FIXME Cache this
        return ReservedWord.query(on: req.db)
            .field(\.$word)
            .all()
            .map { (reservedWords) -> Bool in
                for reservedWord in reservedWords {
                    if lower == reservedWord.word.lowercased() {
                        return false
                    }
                }
                return true
            }
    }
    
    // MARK: Handle Request w/o UIAA
    func handleRequestWithoutUiaa(req: Request)
    -> EventLoopFuture<Response>
    {
        req.logger.debug("MIDNIGHT\t0. No UIAA session.  Running \"preflight\" checks on the registration request")

        // The Matrix CS API mandates that we do some early sanity checks on the requested account data
        /*
          Status code 400:

          Part of the request was invalid. This may include one of the following error codes:

          M_USER_IN_USE : The desired user ID is already taken.
          M_INVALID_USERNAME : The desired user ID is not a valid user name.
          M_EXCLUSIVE : The desired user ID is in the exclusive namespace claimed by an application service.
          These errors may be returned at any stage of the registration process, including after authentication if the requested user ID was registered whilst the client was performing authentication.

          Homeservers MUST perform the relevant checks and return these codes before performing User-Interactive Authentication, although they may also return them after authentication is completed if, for example, the requested user ID was registered whilst the client was performing authentication.
        */
        
        // So how much of this do we want to follow?
        // Answering M_USER_IN_USE would let an adversary map out the set of registered usernames.
        //   * Maybe it's OK if we just rate limit it severely enough???
        //   * Actually on 2nd thought, F that.
        //     Make them at least show us a token first.
        //     I don't want to answer this for the whole wide world.
        //   * So we should check for M_USER_IN_USE *after* validating the token
        //     Note that this isn't totally outside of the Matrix spec -- It tells clients to expect that
        //     the username might go from available to taken while they're doing auth.
        // The others seem genuinely useful though.
        // So, here we attempt to decode the registration request, and check for invalid and/or reserved usernames
        
        // Decode the Matrix registration request
        guard let registrationRequestData = try? req.content.decode(RegistrationRequestBody.self) else {
            // Doesn't appear that we got any registration data.
            // Probably the client is just probing to see what UIAA flows we support.
            // Pass the request along to the homeserver
            req.logger.debug("MIDNIGHT\t1. No registration data.  Sending this one to the homeserver.")
            return proxyRequestToHomeserver(req: req).flatMap { hsResponse in
                req.logger.debug("MIDNIGHT\t2. Got proxy response -- Status = \(hsResponse.status)")
                return handleUiaaResponse(res: hsResponse, for: req)
            }
        }
        
        // Update 2021-04-22 Does this really make sense here?  No.
        // The client hasn't even provided a token yet, so we have no idea
        // whether they actuallly belong here, or if they're just wasting
        // our time / gathering intel on us.
        // PLUS, due to the weird way the UIAA auth works, we don't yet know
        // what username the client will provide when it's finally time to
        // handle the registration request.  Why are we bothering with this for now?
        // We *can* make this work, by saving the username and the result of our
        // checking in the UiaaSession state.  But why bother?
        /*
        // Check for M_INVALID_USERNAME
        let username = registrationRequestData.username
        let formatOk = validateUsernameFormat(username: username)
        if !formatOk {
            let err = ResponseErrorContent(errcode: "M_INVALID_USERNAME", error: "The desired user ID is not a valid user name.")
            return err.encodeResponse(status: .badRequest, for: req)
        } else {
            // Check for M_EXCLUSIVE
            // We're going to use this for all kinds of reserved things
            return validateAgainstReservedWords(username, for: req).flatMap { usernameNotReserved in
                let usernameIsReserved = !usernameNotReserved
                if usernameIsReserved {
                    // The username conflicts with a reserved name
                    let err = ResponseErrorContent(errcode: "M_EXCLUSIVE", error: "The desired user ID is in the exclusive namespace claimed by an application service.")
                    return err.encodeResponse(status: .badRequest, for: req)
                } else {
                    // One more check for invalid usernames -- the bad ones this time
                    // This one is more expensive, so we do it last
                    return validateAgainstBadlist(username, for: req).flatMap { usernameNotInBadlist in
                        let usernameIsInBadlist = !usernameNotInBadlist
                        if usernameIsInBadlist {
                            // Usernames with naughty words in them are not valid
                            let err = ResponseErrorContent(errcode: "M_INVALID_USERNAME", error: "The desired user ID is not a valid user name.")
                            return err.encodeResponse(status: .badRequest, for: req)
                        } else {
                            // Hooray, we have a username that isn't known to be bad
                            
                            // FIXME Add checks for bad password???
        */
                            // Let's get this party started
                            // Forward the request to the homeserver to start the UIAA session
                            req.logger.debug("MIDNIGHT\t3. No UIAA session in request, but it's a good, valid request.  Proxying it...")
                            return proxyRequestToHomeserver(req: req).flatMap { hsResponse in
                                req.logger.debug("MIDNIGHT\t4. Got proxy response -- Status = \(hsResponse.status)")
                                return handleUiaaResponse(res: hsResponse, for: req)
                            }
        /*
                        }
                    }
                }
            }
        }
        */
    }
    // ^^ Look at this freaking pyramid of doom we've got going here...
    
    // MARK: Main handleRegisterRequest
    func handleRegisterRequest(req: Request) throws
    -> EventLoopFuture<Response>
    {
        // First: Make sure this is a valid request
        guard let apiVersion = req.parameters.get("version"),
            apiVersions.contains(apiVersion) else {
            return req.eventLoop.makeFailedFuture(Abort(HTTPStatus.badRequest, reason: "Invalid API version in request"))
        }
        guard let query = try? req.query.decode(RegistrationRequestQuery.self) else {
            // FIXME What does Synapse do here?
            //let err = ResponseErrorContent(errcode: "M_SOMETHING_SOMETHING, error: "Invalid account type")
            return req.eventLoop.makeFailedFuture(Abort(HTTPStatus.badRequest, reason: "Invalid account type"))
        }
        guard query.kind != .guest else {
            // FIXME What does Synapse do here?
            //let err = ResponseErrorContent(errcode: "M_SOMETHING_SOMETHING, error: "Invalid account type")
            return req.eventLoop.makeFailedFuture(Abort(HTTPStatus.badRequest, reason: "The requested account type is not supported"))
        }
        
        /*
        if let stringBody = req.body.string {
            req.logger.debug("Got request with body [\(stringBody)]")
        }
        */
        
        // What is this request?
        // 1. Before UIAA -- No 'auth' parameter, no UIAA session
        //   + Action: Pass it along to the homeserver
        //     We should expect the start of a UIAA session as the response
        guard req.hasUiaaSession else {
            return handleRequestWithoutUiaa(req: req)
        }
        
        // What is this request?
        // 2. Some UIAA stage
        //   + Action: Is it for one of the stages that we handle?
        //     - If so, handle the request and return our response without involving the homeserver
        //     - If not, remove any mention of our stages and pass the request along to the homeserver
        //     On the response, add back in the stages that we handle
        if let requestData = try? req.content.decode(RegistrationRequestBody.self) {
            req.logger.debug("MIDNIGHT\tHandling registration request with active session")
            return handleUiaaRequest(req: req, with: requestData)
        }
        
        
        // What is this request?
        // 3. After UIAA -- This is the actual registration request data
        //    Edit: Nope, that's not how UIAA works.
        //    In reality, the final UIAA stage proceeds directly to handling
        //    the "real" request.  So we should never see a "bare" request
        //    here without a UIAA stage.
        
        //return req.eventLoop.makeFailedFuture(Abort(HTTPStatus.notImplemented, reason: "FIXME We don't handle actual registration data yet"))
        // Actually we shouldn't be here at all.
        // We should go directly from UIAA -> homeserver -> actual /register request processing after the final stage is complete
        // So if we're here, then something went wrong.
        if let requestBody = req.body.string {
            req.logger.info("Got a bad request that we couldn't parse: \(requestBody)")
        }
        let err = ResponseErrorContent(errcode: "M_BAD_REQUEST", error: "Couldn't parse /register request")
        return err.encodeResponse(status: .badRequest, for: req)
    }

    // MARK: Handle /register Response
    // Handle the actual response from the Homeserver on the /register endpoint
    // Mostly we just pass the response along unmodified to the client
    func handleRegisterResponse(hsResponse: ClientResponse, for req: Request) //throws
    -> EventLoopFuture<Response>
    {
        let response: Response
        if let body = hsResponse.body {
            // This is where we should check for a UIAA session that has ended
            // Did the request have a session, but the response did not?
            // Then the UIAA session has finished, and we should remove it.
            // FIXME TODO
            
            response = Response(status: hsResponse.status, body: .init(buffer: body))
        } else {
            response = Response(status: hsResponse.status)
        }
        return req.eventLoop.makeSucceededFuture(response)
    }
    
    // MARK: Proxy Req to Homeserver
    func proxyRequestToHomeserver(req: Request) //throws
    -> EventLoopFuture<ClientResponse>
    {
        // Proxy the request to the "real" homeserver to handle it
        let homeserverURI = URI(scheme: homeserver.scheme,
                                host: homeserver.host,
                                port: homeserver.port,
                                path: req.url.path)
        req.logger.debug("MIDNIGHT\tProxying request to homeserver at \(homeserverURI)")

        return req.client.post(homeserverURI,
                               headers: req.headers) { hsRequest in
            // Patch up the headers to point to the homeserver instead of us
            // This may not be necessary in some deployments, when we're all
            // behind the nginx proxy anyway, but it certainly helps during
            // development where Midnight is running on the local machine
            if let hsHost = homeserver.host {
                hsRequest.headers.remove(name: "Host")
                hsRequest.headers.add(name: "Host", value: hsHost)
            }

            // Copy the request body that we received into
            // our new request that we're sending to the HS
            
            // Check to see if we need to re-write the UIAA stage being attempted
            // This only happens when one of the stages that we handle is the last one in the flow
            // For everything else, just copy the client's request body into our proxy request
            guard let body = try? req.content.decode(RegistrationRequestBody.self),
                  body.auth.type == LOGIN_STAGE_SIGNUP_TOKEN else {
                hsRequest.body = req.body.data
                return
            }
            // If we're re-writing one of our stages, then we must be the only thing in the flow
            // In this case, we should replace ourself with m.login.dummy because there must not
            // have been any other requirements for UIAA auth here.
            let proxyAuthData = RegistrationUiaaAuthData(session: body.auth.session, type: "m.login.dummy", token: nil)
            let proxyRequestBody = RegistrationRequestBody(auth: proxyAuthData,
                                                           username: body.username,
                                                           password: body.password,
                                                           deviceId: body.deviceId,
                                                           initialDeviceDisplayName: body.initialDeviceDisplayName,
                                                           inhibitLogin: body.inhibitLogin)
            try hsRequest.content.encode(proxyRequestBody)
        }
    }
    
}
