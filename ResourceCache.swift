//
//  ResourceCache.swift
//  Prose
//
//  Created by Shawn Throop on 20/04/16.
//  Copyright © 2016 Silent H Designs. All rights reserved.
//

import Foundation

protocol ResourceType: DiskCacheable, RemoteFetchable, Equatable { }

class ResourceCache<T: ResourceType where T == T.UncacheableValueType, T == T.FetchedType> {
    init(cache: DiskCache<T>, fetcher: RemoteFetcher<T>){
        self.cache = cache
        self.fetcher = fetcher
    }
    
    convenience init(name: String, session: NSURLSession? = nil) {
        self.init(cache: DiskCache(name: name), fetcher: RemoteFetcher(session: session))
    }

    private let fetcher: RemoteFetcher<T>
    private let cache: DiskCache<T>
}

extension ResourceCache {
    func fetchObjectAtURL(url: NSURL, cacheKey key: String, failure: (RemoteFetcherError) -> Void, _ completion: (T.FetchedType?) -> Void) {
        let remoteURL = url.copy() as! NSURL
        
        cache.objectForKey(key) { objInCache in
            if objInCache != nil {
                completion(objInCache)
                return
            }
            
            self.fetcher.fetchObjectAtURL(remoteURL, failure: failure, success: { fetchedObj in
                self.cache.setObject(fetchedObj, forKey: key)
                completion(fetchedObj)
            })
        }
    }
}




// MARK: Cache

extension ResourceCache {    
    func purge() {
        self.cache.removeAllObjects()
    }
    
    func trimToDate(date: NSDate) {
        self.cache.trimToDate(date)
    }
}


protocol RemoteResource {
    associatedtype ResourceType
    
    var remoteURL: NSURL { get }
    var cacheKey: String { get }
}

extension ResourceCache {
    func fetch<R: RemoteResource where R.ResourceType == T>(resource: R, failure: (RemoteFetcherError) -> Void, _ completion: (T.FetchedType?) -> Void) {
        fetchObjectAtURL(resource.remoteURL, cacheKey: resource.cacheKey, failure: failure, completion)
    }
}