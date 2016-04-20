//
//  MemoryCache.swift
//  Prose
//
//  Created by Shawn Throop on 20/04/16.
//  Copyright © 2016 Silent H Designs. All rights reserved.
//

import Foundation

class MemoryCache<T: Equatable> {
    init(name: String? = nil) {
        if let name = name {
            self.cache.name = name
        }
    }
    
    private let cache = NSCache()
}



extension MemoryCache {
    var name: String {
        get {
            return cache.name
        }
        set {
            cache.name = newValue
        }
    }
    
    func setObject(obj: T, forKey key: String) {
        cache.setObject(NSCacheWrapper(obj), forKey: key)
    }
    
    
    func objectForKey(key: String) -> T? {
        guard let wrapped = cache.objectForKey(key) as? NSCacheWrapper<T> else {
            return nil
        }
        
        return wrapped.value
    }
    
    
    func removeObjectForKey(key: String) {
        cache.removeObjectForKey(key)
    }
    
    
    func removeAllObjects() {
        cache.removeAllObjects()
    }
}



// MARK: Wrapper (for NSCache)

private class NSCacheWrapper<T: Equatable>: NSObject {
    let value: T
    
    init(_ value: T) {
        self.value = value
    }
    
    override func isEqual(object: AnyObject?) -> Bool {
        guard let other = object as? NSCacheWrapper<T> else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return self.value == other.value
    }
}
