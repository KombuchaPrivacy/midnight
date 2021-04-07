import Fluent
import Vapor



func routes(_ app: Application, reg: RegistrationController) throws {
       
    app.post(["_matrix", "client", ":version", "register"],
             use: reg.handleRegisterRequest)
        

        

}
