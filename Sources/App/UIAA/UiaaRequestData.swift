//
//  File.swift
//  
//
//  Created by Macro Ramius on 3/31/21.
//

import Foundation
import Vapor

// IDEA: What if we made these things be protocols instead of structs???
// Then each of the classes that we'd actually use can just implement the protocols
// For example:
//   * RegistrationRequestBody should implement UiaaRequestData
//   * SignupTokenAuthData should implement UiaaAuthData
//   * Then we can make other types to handle other use cases too
//   * We might need a "bare" type for a concrete type that does nothing but the base protocol,
//     like for the UiaaMiddleware that doesn't care about any of the higher-level functionality

public struct UiaaAuthData: Content {
    // NOTE: This structure might contain many other things that we don't know about
    // However, that's really not our problem here, as long as we can pass those along unmodified to the homeserver
    var type: String
    var session: String?
    var token: String? //
}

// This type represents a generic Matrix API request that uses UIAA.
// Here we assume no knowledge about the contents of the request, other
// than the fact that it's using UIAA, so it must have the 'auth' struct.
// If/when we want to do something "real" with the same request, we will
// then need to decode the request body again, using a purpose-built type
// for whatever kind of thing we're expecting, e.g. for registration or
// changing password or whatever.
public struct UiaaRequestData: Content {
    var auth: UiaaAuthData
}
