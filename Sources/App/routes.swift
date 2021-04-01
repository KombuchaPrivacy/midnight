import Fluent
import Vapor

//let homeserver = "matrix-synapse"
let homeserver = "192.168.1.89"
let homeserver_port = 6167

func routes(_ app: Application) throws {
       
    app.post(["_matrix", "client", ":version", "register"]) { req -> EventLoopFuture<UiaaResponseData> in
        
        guard let apiVersion = req.parameters.get("version") else {
            throw Abort(HTTPStatus.badRequest)
        }
        let apiVersions = ["r0", "v1"]
        if !apiVersions.contains(apiVersion) {
            throw Abort(HTTPStatus.badRequest)
        }
        
        print("AURIC\tPOST /register\n\tData = \(req.body.string ?? "(no body)")")
        
        // Proxy the request to the "real" homeserver to handle it
        let homeserverURI: URI = URI(scheme: .http,
                            host: homeserver,
                            port: homeserver_port,
                            path: req.url.path)
        return req.client.post(homeserverURI, headers: req.headers) { clientReq in
            clientReq.body = req.body.data
        }.flatMapThrowing { clientRes in
            if let body = clientRes.body {
                let string = body.getString(at: 0, length: body.readableBytes)
                print("AURIC\tGot response with body = \(string ?? "(none)")")
            }
            
            let hsResponseData = try clientRes.content.decode(UiaaResponseData.self)
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
