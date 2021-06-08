//
//  CreateTokenCommand.swift
//  
//
//  Created by Charles Wright on 4/9/21.
//

import Foundation
import Vapor
import Fluent

struct CreateTokenCommand: Command {

    var help: String {
        "Creates a token that can be used to register for one or more accounts on the server"
    }
    
    struct Signature: CommandSignature {
        @Argument(name: "user")
        var user: String
        
        @Argument(name: "slots")
        var slots: UInt
        
        @Argument(name: "access-level")
        var level: String
        
        @Argument(name: "access-duration")
        var duration: UInt
        
        @Argument(name: "valid-for")
        var validDays: UInt
    }
    
    func run(using context: CommandContext, signature: Signature) throws {
        //print("Got user [\(signature.user)]")
        
        let expiration = Date(timeIntervalSinceNow: TimeInterval(60 * 60 * 24 * signature.validDays))
        
        let token = SignupToken(for: signature.user,
                                slots: signature.slots,
                                accessLevel: signature.level,
                                accessDuration: signature.duration,
                                expiresAt: expiration)

        let logger = context.application.logger
        //print("Creating token [\(token.token)]")
        logger.info("Creating token [\(token.token)]")

        let dgroup = DispatchGroup()

        dgroup.enter()
        context.application.db.transaction { (database) -> EventLoopFuture<Void> in
            logger.info("Saving token [\(token.token)] in the database...")
            return token.save(on: database)
        }.whenComplete { result in
            logger.info("Done with transaction")
            switch result {
            case .failure(let err):
                logger.critical("Error: \(err)")
            case .success:
                logger.critical("Token: \(token.token)")
            }
            dgroup.leave()
        }

        let seconds = 4.0
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            // Put your code which should be executed with a delay here
            logger.info("asyncAfter")
        }

        dgroup.notify(queue: .main) {
            logger.info("Done")
        }
        
        /*
        whenSuccess {
            print(token.token)
        }
        */
    }
    
}
