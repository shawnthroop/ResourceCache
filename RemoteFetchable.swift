//
//  RemoteFetchable.swift
//  Prose
//
//  Created by Shawn Throop on 18/04/16.
//  Copyright © 2016 Silent H Designs. All rights reserved.
//

import Foundation

protocol RemoteFetchable {
    associatedtype FetchedType
    static func fromFetchedData(data: NSData) throws -> FetchedType
    
    static func errorForResponse(response: NSHTTPURLResponse) -> ResponseErrorType?
}


extension RemoteFetchable {
    static func errorForResponse(response: NSHTTPURLResponse) -> ResponseErrorType? {
        switch response.statusCode {
        case 200...201:
            return nil
        default:
            return response
        }
    }
}