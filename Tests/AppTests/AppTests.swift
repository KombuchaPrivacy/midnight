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

    func _register_second_request(_ app: Application, state: UiaaSessionState) throws {
        try app.test(.POST,
                 "/_matrix/client/r0/register",
                 beforeRequest: { req in
                    let auth = RegistrationUiaaAuthData(
                        session: state.session,
                     type: LOGIN_STAGE_SIGNUP_TOKEN,
                     token: "c308-ffda-12c5-5316")
                    let body = RegistrationRequestBody(auth: auth, username: "bob", password: "hunter2", deviceId: "ABCDEFG", initialDeviceDisplayName: "iPhone")
                    try req.content.encode(body)
                 },
                 afterResponse: { res in
                    XCTAssertEqual(res.status, .unauthorized)

                    let newState = try res.content.decode(UiaaSessionState.self)
                    XCTAssertNotNil(newState)
                    
                    print("TEST\tGot response:")
                    print("TEST\t\tsession = \(newState.session)")
                    print("TEST\t\tcompleted = \(newState.completed ?? [])")
                 }
                )
    }
    
    func _register_first_request(_ app: Application) throws {
        try app.test(.POST,
                     "/_matrix/client/r0/register",
                     beforeRequest: { req in
                        let empty = "{}"
                        try req.content.encode(empty)
                     },
                     afterResponse: { res in
                        XCTAssertEqual(res.status, .unauthorized)

                        let state = try res.content.decode(UiaaSessionState.self)
                        XCTAssertNotNil(state)
                        print("TEST\tGot session = \(state.session)")
                        try _register_second_request(app, state: state)
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
