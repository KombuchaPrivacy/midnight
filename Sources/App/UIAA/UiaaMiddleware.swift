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
        if let uiaaReqData = try? request.content.decode(UiaaRequestData.self) {
            print("UIAA\tGot UIAA request data")
            let id = SessionID(string: uiaaReqData.auth.session)
            return self.driver.readSession(id, for: request).flatMap { data in
                if let data = data {
                    // We've seen this session before
                    print("UIAA\tFound an existing session")
                    // Attach its existing data to it
                    request.uiaaSession = .init(id: id, data: data)
                } else {
                    // First time we're seeing this one
                    // FIXME Shouldn't this be an error?  The first time we see a new session ID, it should be coming from the *homeserver*, not the client.  Hmmm...
                    print("UIAA\tFound a new session")
                    // Create a new SessionData object for it
                    request.uiaaSession = .init(id: id, data: .init())
                }
                return next.respond(to: request).map { response in
                    // Check whether we need to remove the session
                    print("UIAA\tChecking for existing session in response")
                    return response
                }
            }
        } else {
            // No credentials.  That's OK.
            print("UIAA\tNo session in the request")
            return next.respond(to: request).flatMap { response in
                // Maybe we got a new session ID here in the response?
                print("UIAA\tChecking for new session in response")
                if let creds = try? response.content.decode(UiaaResponseSessionOnly.self) {
                    print("UIAA\tFound new session in response")
                    var data = SessionData()
                    data["session"] = creds.session
                    
                    return self.driver
                        .createSession(data, for: request)
                        .map { _ in
                            print("UIAA\tCreated new session")
                            return response
                        }

                } else {
                    print("UIAA\tNo new session in response")
                    return request.eventLoop.makeSucceededFuture(response)
                }
            }
        }
    
    }

}
