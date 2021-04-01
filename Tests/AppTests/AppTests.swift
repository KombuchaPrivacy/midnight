@testable import App
import XCTVapor

final class AppTests: XCTestCase {
    func testHelloWorld() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)

        try app.test(.GET, "hello", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "Hello, world!")
        })
    }
}

final class AuricTests: XCTestCase {
    public typealias Credentials = UiaaSessionOnly

    func _register_second_request(_ app: Application, session: String) throws {
        try app.test(.POST,
                 "/_matrix/client/r0/register",
                 beforeRequest: { req in
                    try req.content.encode(["session": session,
                                            "username": "bob",
                                            "password": "hunter2"
                                            /*
                                            ,
                                            "auth": [
                                                "type": "m.login.dummy"
                                            ]
                                            */
                    ])
                 },
                 afterResponse: { res in
                    let creds = try res.content.decode(Credentials.self)
                    XCTAssertEqual(session, creds.session)
                 }
                )
    }
    
    func _register_first_request(_ app: Application) throws {
        try app.test(.POST,
                 "/_matrix/client/r0/register",
                 afterResponse: { res in
                    XCTAssertEqual(res.status, .ok)

                    let creds = try res.content.decode(Credentials.self)
                    XCTAssertNotNil(creds)
                    try _register_second_request(app, session: creds.session)
                 }
        )
    }
    
    func testRegistrationSessions() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)
        
        try _register_first_request(app)
    }
}
