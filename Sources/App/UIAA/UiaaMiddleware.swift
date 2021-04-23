//
//  UiaaMiddleware.swift
//  Vapor middleware for the Matrix User-Interactive Authentication API
//  Based in part on Vapor's SessionsMiddleware
//  Created by Macro Ramius on 3/31/21.
//

import Vapor

public final class UiaaMiddleware: Middleware {
    //public typealias Credentials = UiaaResponseSessionOnly
    
    public let driver: UiaaSessionDriver
    
    public init(driver: UiaaSessionDriver) {
        self.driver = driver
    }
    
    public func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        
        // Now we look for the session ID in the request
        if let uiaaReqData = try? request.content.decode(MinimalUiaaRequestData.self) {
            request.logger.debug("UIAA\tGot UIAA request data")
            let sessionId = uiaaReqData.auth.session
            let id = SessionID(string: sessionId)
            return self.driver.readSession(id, for: request).flatMap { data in
                guard let data = data else {
                    // First time we're seeing this one
                    // FIXME Shouldn't this be an error?  The first time we see a new session ID, it should be coming from the *homeserver*, not the client.  Hmmm...
                    request.logger.debug("UIAA\tFound a new unexpected session: \(sessionId)")
                    return request.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "Unknown session \(sessionId)"))
                }
                
                // We've seen this session before
                request.logger.debug("UIAA\tFound an existing session")
                // Attach its existing data to it
                request.uiaaSession = .init(id: id, data: data)

                return next.respond(to: request).map { response in
                    // Check whether we need to remove the session
                    request.logger.debug("UIAA\tChecking for existing session in response")
                    return response
                }
            }
        } else {
            // No credentials.  That's OK.
            request.logger.debug("UIAA\tNo session in the request")
            return next.respond(to: request).flatMap { response in
                // Maybe we got a new session ID here in the response?
                request.logger.debug("UIAA\tChecking for new session in response")
                if let initialState = try? response.content.decode(UiaaSessionState.self) {
                    request.logger.debug("UIAA\tFound new session in response: \(initialState.session)")
                    request.logger.debug("UIAA\tFlows = ")
                    for flow in initialState.flows {
                        request.logger.debug("UIAA\t\t\(flow.stages)")
                    }
                    var data = UiaaSessionData(initialData: [:], initialState: initialState)
                    data["session"] = initialState.session
                    
                    return self.driver
                        .createSession(data, for: request)
                        .map { _ in
                            request.logger.debug("UIAA\tCreated new session")
                            return response
                        }

                } else {
                    request.logger.debug("UIAA\tNo new session in response")
                    return request.eventLoop.makeSucceededFuture(response)
                }
            }
        }
    
    }

}
