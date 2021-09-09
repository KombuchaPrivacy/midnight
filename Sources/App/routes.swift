import Fluent
import Vapor

func routes(_ app: Application, reg: RegistrationController) throws {
    //app.post(["_matrix", "client", ":version", "register"], use: reg.handleRegisterRequest)

    // Maybe if we specify the max request body size explicitly, we will get different behavior???
    app.on(.POST, ["_matrix", "client", ":version", "register"], body: .collect(maxSize: "8mb"), use: reg.handleRegisterRequest)
}
