//
//  ResponseErrorContent.swift
//  
//
//  Created by Charles Wright on 4/12/21.
//

import Foundation
import Vapor

public struct ResponseErrorContent: Content {
    var errcode: String
    var error: String
}
