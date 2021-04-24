//
//  UiaaResponseData.swift
//  
//
//  Created by Macro Ramius on 3/31/21.
//

import Fluent
import Vapor

public struct UiaaAuthFlow: Content {
    var stages: [String]
    
    func isSatisfiedBy(completed: [String]) -> Bool {
        completed.starts(with: stages)
    }
}

public struct mLoginTermsParams: Content {
    struct PolicyInfo: Codable {
        struct LocalizedPolicy: Codable {
            var name: String
            var url: URL
        }
        
        var version: String
        // FIXME this is the awfulest f**king kludge I think I've ever written
        // But the Matrix JSON struct here is pretty insane
        // Rather than make a proper dictionary, they throw the version in the
        // same object with the other keys of what should be a natural dict.
        // Parsing this properly is going to be something of a shitshow.
        // But for now, we do it the quick & dirty way...
        var en: LocalizedPolicy?
    }
    
    var policies: [String:PolicyInfo]
}

//typealias UiaaStateParams = [String: [String:String]]?
public struct UiaaParams: Content {
    var terms: mLoginTermsParams?
}

public struct UiaaSessionState: Content {
    var errcode: String?
    var error: String?
    var flows: [UiaaAuthFlow]
    var params: [String: [String:String]]?
    var completed: [String]?
    var session: String
}

public struct UiaaSessionStateBare: Content {
    var session: String
}
