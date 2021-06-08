//
//  ListTokensCommand.swift
//  
//
//  Created by Charles Wright on 4/14/21.
//

import Foundation
import Vapor
import Fluent

struct ListTokensCommand: Command {   
    
    var help: String {
        "Lists tokens that can be used to register for an account"
    }
    
    struct Signature: CommandSignature {
        @Argument(name: "user")
        var user: String
    }
    
    func run(using context: CommandContext, signature: Signature) throws {
        let db = context.application.db
        let logger = context.application.logger

        guard let signupTokens = try? SignupToken.query(on: db)
            .filter(\.$createdBy == signature.user)
            .all()
            .wait()
        else {
            logger.critical("Database query failed")
            return
        }

        if signupTokens.isEmpty {
            logger.critical("No matching tokens")
        } else {
            for signupToken in signupTokens {
                logger.info("Token: \(signupToken.token)")
            }
        }

            /*
            .map { signupTokens in
                if signupTokens.isEmpty {
                    logger.critical("No matching tokens")
                } else {
                    for signupToken in signupTokens {
                        logger.critical("Token: \(signupToken.token)")
                    }
                }

            }
            */

    }
}
