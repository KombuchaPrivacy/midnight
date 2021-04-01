//
//  RegistrationController.swift
//  
//
//  Created by Macro Ramius on 4/1/21.
//

import Foundation
import Vapor
import Fluent

struct RegistrationController {
    //let homeserver = "matrix-synapse"
    //static let homeserver = "192.168.1.89"
    //static let homeserver_port = 6167
    //static let apiVersions = ["r0", "v1"]
    
    var app: Application
    var homeserver: String
    var homeserver_port: Int
    var apiVersions: [String]
    
    func validateSignupToken(_ token: String, forRequest req: Request)
    -> EventLoopFuture<Response>
    {
        // Ok we got a token
        // 1. Is it valid?
        //   1.1. Are we even offering token auth right now?
        //   1.2. Is this a currently valid token that we have issued?
        // 2. Can we use it to register this user?
        //   2.1. Is the number of users registered with this token less than the maximum that the token allows?
        
    }

    
    func handleRegister(req: Request) throws
    -> EventLoopFuture<Response>
    {
        guard let apiVersion = req.parameters.get("version") else {
            throw Abort(HTTPStatus.badRequest)
        }
        if !apiVersions.contains(apiVersion) {
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
            if let token = reqContent.auth.token,
               reqContent.auth.type == "social.kombucha.signup_token" {
                // Hey cool, we got a token.
                // Our job is to authenticate it as valid,
                // and then return the proper response
                return validateSignupToken(token: token, forRequest: req)
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
        }.flatMapThrowing { hsResponse in
            
            if let body = hsResponse.body {
                let string = body.getString(at: 0, length: body.readableBytes)
                print("AURIC\tGot response with body = \(string ?? "(none)")")
            }
            
            let hsResponseData = try hsResponse.content.decode(UiaaResponseData.self)
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
            return responseData
        }
    }
}
