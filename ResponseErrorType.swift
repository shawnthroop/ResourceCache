//
//  ResponseErrorType.swift
//  Prose
//
//  Created by Shawn Throop on 18/04/16.
//  Copyright © 2016 Silent H Designs. All rights reserved.
//

import Foundation

protocol ResponseErrorType {
    var code: Int { get }
    var errorMessage: String? { get }
}



extension NSHTTPURLResponse: ResponseErrorType {
    var code: Int {
        return self.statusCode
    }
    
    var errorMessage: String? {
        return "Response: \(code)"
    }
}