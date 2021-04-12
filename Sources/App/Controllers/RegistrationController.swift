//
//  RegistrationController.swift
//  
//
//  Created by Macro Ramius on 4/1/21.
//

import Foundation
import Vapor
import Fluent

let LOGIN_STAGE_SIGNUP_TOKEN = "social.kombucha.login.signup_token"

struct RegistrationController {
    var app: Application
    
    var homeserver: String
    var homeserver_scheme: URI.Scheme = .https
    var homeserver_port: Int
    var apiVersions: [String]
    
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
            return req.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "Invalid token"))
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
                }
                // Check whether the token is expired
                // If there's no expiration date, then the token is always valid for now
                guard signupToken.expiresAt ?? Date(timeIntervalSinceNow: 1000) < now else {
                    return req.eventLoop.makeFailedFuture(Abort(.forbidden, reason: "Token is expired"))
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
                        }
                        return req.eventLoop.makeSucceededFuture(available)
                    }
                
            }
    }
    
    func createPendingSubscription(for req: Request, given numSlots: Int) //throws
    -> EventLoopFuture<Void>
    {
        guard let token = req.session.data["token"],
              let sessionId = req.session.id?.string else {
            return req.eventLoop.makeFailedFuture(Abort(.internalServerError, reason: "Error looking up session data"))
        }
        
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
                                return req.eventLoop.makeSucceededVoidFuture()
                            } else {
                                // There are now too many pending registrations for our token
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
    
    func handleSignupTokenRequest(req: Request, token: String)
    -> EventLoopFuture<Response>
    {
        return validateSignupToken(token, forRequest: req)
            .flatMap { numSlots in
                // The token is valid
                // Save it in the request's session
                guard let session = req.uiaaSession else {
                    return req.eventLoop.makeFailedFuture(Abort(.internalServerError, reason: "Couldn't find authentication session"))
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
                    
                    // Copy the list of params (if any)
                    let params = state.params
                    
                    let responseData = UiaaSessionState(flows: flows,
                                                        params: params,
                                                        completed: completed,
                                                        session: sessionId)
                    
                    // FIXME If this was the last stage, then we should
                    // return 200 OK here
                    var status: HTTPStatus = .unauthorized
                    for flow in flows {
                        if flow.isSatisfiedBy(completed: completed) {
                            status = .ok
                            break
                        }
                    }
                    
                    return responseData.encodeResponse(status: status, for: req)
                }
            }
    }
    
    func handleUiaaRequest(req: Request, with data: UiaaRequestData) //throws
    -> EventLoopFuture<Response>
    {
        // Is this UIAA stage one of ours?
        // - If so, handle it.
        // - If not, pass the request along to the homeserver.
        //   Maybe it knows what to do with this one.
        switch data.auth.type {
        case LOGIN_STAGE_SIGNUP_TOKEN:
            guard let token = data.auth.token else {
                return req.eventLoop.makeFailedFuture(Abort(HTTPStatus.badRequest, reason: "No token provided"))
            }
            return handleSignupTokenRequest(req: req, token: token)
        default:
            return proxyRequestToHomeserver(req: req).flatMap { hsResponse in
                return handleUiaaResponse(res: hsResponse, for: req)
            }
        }
    }
    
    func proxyResponseToClientUnmodified(res: ClientResponse, for req: Request)
    -> EventLoopFuture<Response>
    {
        print("\t\(#function): Client response status = \(res.status)")
        let response: Response
        if let body = res.body {
            print("\t\(#function): Got a response with content")
            // FIXME This is where we need to insert our own UIAA stages
            // in the response before it goes back to the client
            response = Response(status: res.status, body: .init(buffer: body))
        } else {
            print("\t\(#function): Got empty response")
            response = Response(status: res.status)
        }
        return req.eventLoop.makeSucceededFuture(response)
    }
    
    func handleUiaaResponse(res: ClientResponse, for req: Request)
    -> EventLoopFuture<Response>
    {
        print("AURIC\tHandling UIAA Response")
        
        // The only response that we need to work with is a 401
        // Everything else we return unmodified
        guard res.status == HTTPStatus.unauthorized else {
            print("AURIC\tUIAA response is not 401; Returning unmodified")
            // FIXME Make sure that 401's are all we need to touch
            //       Could there be 403's where we need to re-write the flows?
            return proxyResponseToClientUnmodified(res: res, for: req)
        }
        
        guard let hsResponseData = try? res.content.decode(UiaaSessionState.self) else {
            return req.eventLoop.makeFailedFuture(Abort(.internalServerError, reason: "Couldn't parse Matrix data"))
        }
        
        var ourResponseData = hsResponseData
        ourResponseData.flows = []
        for var flow in hsResponseData.flows {
            if flow.stages == ["m.login.dummy"] {
                flow.stages = [LOGIN_STAGE_SIGNUP_TOKEN]
            } else if !flow.stages.contains(LOGIN_STAGE_SIGNUP_TOKEN) {
                print("Inserting signup_token in auth flows")
                flow.stages.insert(LOGIN_STAGE_SIGNUP_TOKEN, at: 0)
                print("Stages = ", flow.stages)
            }
            print("Flow = ", flow)
            ourResponseData.flows.append(flow)
        }
        print("\t\(#function): Returning response data = \(ourResponseData)")
        
        return ourResponseData.encodeResponse(status: .unauthorized, for: req)
    }
    
    func validateUsername(username: String)
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
        if localPart.count > 255 - "@kombucha.social".count {
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
    
    func validateAgainstBadlist(_ string: String, db: Database)
    -> EventLoopFuture<Bool> {
        let lower = string.lowercased()

        // FIXME Cache this
        return BadWord.query(on: db)
            .field(\.$word)
            .all()
            .map { (badwords) -> Bool in
                
                for badword in badwords {
                    if lower.contains(badword.word) {
                        return false
                    }
                    let leetspeak = badword.word
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
        
                // If we didn't match any of the bad words, it's probably OK
                return true
            }
    }
    
    // Improved approach.  Two core functions:
    // * handleRegisterRequest - Looks at the request and decides what to do with it
    //   - Handle it ourselves
    //   - Proxy it to the homeserver unchanged
    //   - Proxy it to the homeserver with some modifications
    // * handleRegisterResponse - Handle the response from the homeserver
    //   - hmmm..  Not sure we really need a generic version of the response handler
    //   - Different kinds of responses require different handlers
    func handleRegisterRequest(req: Request) throws
    -> EventLoopFuture<Response>
    {
        // First: Make sure this is a valid request
        guard let apiVersion = req.parameters.get("version"),
            apiVersions.contains(apiVersion) else {
            return req.eventLoop.makeFailedFuture(Abort(HTTPStatus.badRequest, reason: "Invalid API version in request"))
        }
        
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
        // The others seem genuinely useful though.
        // So, attempt to decode the registration request, and check for invalid and/or reserved usernames
        guard let registrationRequestData = try? req.content.decode(RegistrationRequestBody.self) else {
            return req.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "Couldn't parse registration request"))
        }
        
        // Check for M_INVALID_USERNAME
        guard validateUsername(username: registrationRequestData.username) else {
            let err = ResponseErrorContent(errcode: "M_INVALID_USERNAME", error: "The desired user ID is not a valid user name.")
            return err.encodeResponse(status: .badRequest, for: req)
        }
        
        // Check for M_EXCLUSIVE
        // We're going to use this for all kinds of reserved things
        
        
        
        // What is this request?
        // 1. Before UIAA -- No 'auth' parameter, no UIAA session
        //   + Action: Pass it along to the homeserver
        //     We should expect the start of a UIAA session as the response
        guard req.hasUiaaSession else {
            print("AURIC\t1. No UIAA session in request.  Proxying...")
            return proxyRequestToHomeserver(req: req).flatMap { hsResponse in
                print("AURIC\t2. Got proxy response -- Status = \(hsResponse.status)")
                return handleUiaaResponse(res: hsResponse, for: req)
            }
        }
        
        // What is this request?
        // 2. Some UIAA stage
        //   + Action: Is it for one of the stages that we handle?
        //     - If so, handle the request and return our response without involving the homeserver
        //     - If not, remove any mention of our stages and pass the request along to the homeserver
        //     On the response, add back in the stages that we handle
        if let requestData = try? req.content.decode(UiaaRequestData.self) {
            return handleUiaaRequest(req: req, with: requestData)
        }
        
        
        // What is this request?
        // 3. After UIAA -- This is the actual registration request data
        //   + Action: Enforce any username and password policies beyond those of the homeserver
        //     - If one or both fails, send our own response back to the client
        //     - If the requested username/password are good, pass them along to the homeserver
        //       On the response, clean up any temporary data that we created (like pending subscriptions)
        //       and add the new user to our table of current subscriptions
        // FIXME TODO
        
        return req.eventLoop.makeFailedFuture(Abort(HTTPStatus.notImplemented, reason: "FIXME We don't handle actual registration data yet"))
    }

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
    
    func proxyRequestToHomeserver(req: Request) //throws
    -> EventLoopFuture<ClientResponse>
    {
        // Proxy the request to the "real" homeserver to handle it
        let homeserverURI = URI(scheme: homeserver_scheme,
                                host: homeserver,
                                //port: homeserver_port,
                                path: req.url.path)
        print("AURIC\tProxying request to homeserver at \(homeserverURI)")

        return req.client.post(homeserverURI,
                               headers: req.headers) { hsRequest in
            // Patch up the headers to point to the homeserver instead of us
            // This may not be necessary in deployment, when we're all behind the nginx proxy anyway, but it certainly helps during development where Auric is running on the local machine
            hsRequest.headers.remove(name: "Host")
            hsRequest.headers.add(name: "Host", value: homeserver)

            // Copy the request body that we received into
            // our new request that we're sending to the HS
            hsRequest.body = req.body.data
        }
    }
    
    // Initial attempt -- just throwing things together as I figure them out
    func _old_handleRegister(req: Request) throws
    -> EventLoopFuture<Response>
    {
        guard let apiVersion = req.parameters.get("version"),
            apiVersions.contains(apiVersion) else {
            throw Abort(HTTPStatus.badRequest)
        }

        
        print("AURIC\tPOST /register\n\tData = \(req.body.string ?? "(no body)")")
        
        // Is this request for us to handle?
        // Or should we proxy it on to the real homeserver?
        //
        // Try to decode the request body as a UIAA request JSON
        //   - If it succeeds, look for type: social.kombucha.signup_token
        //   - If the decoding fails, or the type doesn't match,
        //     then just fall through and proxy the request
        // Otherwise this request is not for us.
        //   - Just pass it along to the homeserver.
        do {
            let reqContent = try req.content.decode(UiaaRequestData.self)
            // If we're still here, then we should have a valid UIAA session
            guard let sessionId = req.session.id?.string else {
                return req.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "No session ID in request"))
            }
            if let token = reqContent.auth.token,
               reqContent.auth.type == "social.kombucha.signup_token" {
                // Hey cool, we got a token.
                // Our job is to authenticate it as valid,
                // and then return the proper response
                return validateSignupToken(token, forRequest: req)
                    .flatMap { numSlots in
                        // The token is valid
                        // Save it in the request's session
                        req.session.data["token"] = token
                        
                        // Next we need to tell the client that their token auth was successful
                        
                        // FIXME Ah crud, there's a race condition here
                        // How do we make sure that 1000 people can't all
                        // register at the same time using the same token?
                        // (Do we really care??)
                        // If we care, then we need to find a way to gate this *before* we return success here
                        // What if we added a new kind of "pending" registration state?
                        // Then we preemptively add the anonymous user to our subscriptions table in a pending state, with a very short expiration time.  Like 10 or 15 minutes.
                        // We can use their session ID to identify them in the pending entry in the table.
                        // So now, when we validate a token, we have to check:
                        // 1. Is it already full of registered users?
                        // 2. If it's not already full, are there enough currently pending registrations to fill it up?
                        // 3. If there is still room for one more pending registration, add this user to the pending list
                        // (We should do 2 and 3 as a transaction)
                        // ...
                        // Then when the user finishes validating their email, SMS number, etc, and finally registers, then we can do another transaction to remove them from the pending table and add them to the subscription table
                        
                        return createPendingSubscription(for: req, given: numSlots).map {
                            // Whew!
                            // Now that we have our pending slot in the database, we can go ahead with the registration process
                            // For now that means telling the client that their token-based auth was successful
                            // ARGH - So what do we do if we've finished, and there are no other remaining auth stages?
                            // FIXME Look this up in the Matrix API docs...
                            var response = Response(status: .unauthorized)
                            //return req.eventLoop.makeSucceededFuture(response)
                            return response
                        }
                    }
            }
        } catch {
            // Guess we failed to decode as a UIAA request...
            // This one must not be for us.  We'll handle it below.
        }
        
        // Proxy the request to the "real" homeserver to handle it
        let homeserverURI = URI(scheme: .http,
                                host: homeserver,
                                port: homeserver_port,
                                path: req.url.path)

        return req.client.post(homeserverURI,
                               headers: req.headers) { hsRequest in
            hsRequest.body = req.body.data
        }.flatMap { hsResponse in
            
            if let body = hsResponse.body {
                let string = body.getString(at: 0, length: body.readableBytes)
                print("AURIC\tGot response with body = \(string ?? "(none)")")
            }
            
            do {
                let hsResponseData = try hsResponse.content.decode(UiaaSessionState.self)
                var responseData = hsResponseData

                responseData.flows = []
                for var flow in hsResponseData.flows {
                    if flow.stages == ["m.login.dummy"] {
                        flow.stages = ["social.kombucha.signup_token"]
                    } else if !flow.stages.contains("social.kombucha.signup_token") {
                        print("Inserting signup_token in auth flows")
                        flow.stages.insert("social.kombucha.signup_token", at: 0)
                        print("Stages = ", flow.stages)
                    }
                    print("Flow = ", flow)
                    responseData.flows.append(flow)
                }
                print("Response data = ", responseData)
                //return responseData
            
                return responseData.encodeResponse(status: .unauthorized, for: req)
                //let response = Response(status: .ok, body: .init(string: "Hello world"))
                //return response
            } catch {
                return req.eventLoop.makeFailedFuture(Abort(.internalServerError))
            }
        }
    }
}
