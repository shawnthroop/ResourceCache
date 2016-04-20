//
//  RemoteFetcher.swift
//  Prose
//
//  Created by Shawn Throop on 18/04/16.
//  Copyright © 2016 Silent H Designs. All rights reserved.
//

import Foundation

class RemoteFetcher<T: RemoteFetchable> {
    init(session: NSURLSession? = nil) {
        self.session = session ?? NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
    }
    
    private let session: NSURLSession
    
    func fetchObjectAtURL(url: NSURL, failure: (RemoteFetcherError) -> Void, success: (T.FetchedType) -> Void) {
        let task = session.dataTaskWithURL(url) { (data, response, err) in
            if let httpResponse = response as? NSHTTPURLResponse {
                if let responseError = T.errorForResponse(httpResponse) {
                    fail(dispatch_get_main_queue(), fail: failure(RemoteFetcherError.ResponseError(responseError)))

                } else {
                    if let responseData = data {
                        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), { 
                            var parsedValue: T.FetchedType?
                            var parseError: ErrorType?
                            
                            do {
                                parsedValue = try T.fromFetchedData(responseData)
                            } catch {
                                parseError = error
                            }
                            
                            if let parsed = parsedValue {
                                succeed(dispatch_get_main_queue(), success: success(parsed))
                                
                            } else {
                                fail(dispatch_get_main_queue(), fail: failure(RemoteFetcherError.ParsingDataFailed(parseError!)))
                            }
                        })
                        
                    } else {
                        fail(dispatch_get_main_queue(), fail: failure(RemoteFetcherError.Other("No data")))
                    }
                }
                
            } else {
                fail(dispatch_get_main_queue(), fail: failure(RemoteFetcherError.Other(err?.localizedDescription)))
            }
        }
        
        task.resume()
    }
}

private func succeed(queue: dispatch_queue_t, @autoclosure(escaping) success: () -> Void) {
    dispatch_async(queue, success)
}

private func fail(queue: dispatch_queue_t, @autoclosure(escaping) fail: () -> Void) {
    dispatch_async(queue, fail)
}


enum RemoteFetcherError {
    case ParsingDataFailed(ErrorType)
    case ResponseError(ResponseErrorType)
    case Other(String?)
}