@testable import App
import XCTVapor

final class MidnightTests: XCTestCase {

    func _register_second_request(_ app: Application, state: UiaaSessionState) throws {
        try app.test(.POST,
                 "/_matrix/client/r0/register?kind=user",
                 beforeRequest: { req in
                    let auth = RegistrationUiaaAuthData(
                        session: state.session,
                        type: LOGIN_STAGE_SIGNUP_TOKEN,
                        token: "1234-5678-abcd-efgh"
                    )
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
                     "/_matrix/client/r0/register?kind=user",
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
