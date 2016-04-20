//
//  DiskCache.swift
//  Prose
//
//  Created by Shawn Throop on 18/04/16.
//  Copyright © 2016 Silent H Designs. All rights reserved.
//

import Foundation

private let DiskCachePrefix = "com.DiskCache"
private let DiskCacheDirectory = "DiskCache"

class DiskCache<T: DiskCacheable where T.UncacheableValueType: Equatable> {
    convenience init(name: String) {
        self.init(name: name, rootPath: FileSystem.cachesPath)
    }
    
    init(name: String, rootPath: String) {
        self.memoryCache = MemoryCache(name: name)
        
        // Inserts a default directory so that if you supply "" for a name, you don't end up wiping the Caches folder when calling removeAllObjects() 
        // cachePath = "/{{ rootDir }}/DiskCache/{{ name }}/"
        self.cachePath = FileSystem.encodedPathForKey(DiskCacheDirectory, rootPath: rootPath)
        
        // "In OS X v10.7 and later or iOS 4.3 and later, specify DISPATCH_QUEUE_SERIAL (or NULL) to create a serial queue or specify DISPATCH_QUEUE_CONCURRENT to create a concurrent queue."
        self.queue = dispatch_queue_create(DiskCachePrefix + ".asyncQueue", DISPATCH_QUEUE_SERIAL)
        
        dispatch_async(self.queue) { [weak self] in
            guard let strongSelf = self else {
                return
            }
            
            FileSystem.createDirectory(strongSelf.cachePath)
        }
    }
    
    private let memoryCache: MemoryCache<T.UncacheableValueType>
    private let cachePath: String
    private let queue: dispatch_queue_t
}



// MARK: Asynchronous

extension DiskCache {
    func objectForKey(key: String, _ block: (T.UncacheableValueType?) -> Void) {
        dispatch_async(queue) { [weak self] in
            guard let strongSelf = self else {
                return
            }
            
            let path = FileSystem.encodedPathForKey(key, rootPath: strongSelf.cachePath)
            
            if let objInMemory = strongSelf.memoryCache.objectForKey(key) {
                FileSystem.updateModificationDateOfItemAtPath(path, toDate: NSDate())
                
                // signal completion with object found in memory cache
                dispatch_async(dispatch_get_main_queue()) {
                    block(objInMemory)
                }
                
            } else {
                let objOnDisk = FileSystem.objectAtPath(path) { try T.st_valueFromData($0) }
                
                if let obj = objOnDisk {
                    strongSelf.memoryCache.setObject(obj, forKey: key)
                }
                
                // signal completion
                dispatch_async(dispatch_get_main_queue()) {
                    block(objOnDisk)
                }
            }
        }
    }
    
    func setObject(obj: T.UncacheableValueType, forKey key: String, _ completion: ((Bool) -> Void)? = nil) {
        dispatch_async(queue) { [weak self] in
            guard let strongSelf = self else {
                return
            }
            
            // add object to memory cache
            strongSelf.memoryCache.setObject(obj, forKey: key)
            
            // write object to disk (as NSData)
            let path = FileSystem.encodedPathForKey(key, rootPath: strongSelf.cachePath)
            let success = FileSystem.createObject(obj, atPath: path) { try T.st_toDataFromValue($0) }
            
            // signal completion if necessary
            if let block = completion {
                dispatch_async(dispatch_get_main_queue()) {
                    block(success)
                }
            }
        }
    }
    
    
    func removeObjectForKey(key: String, _ completion: ((Bool) -> Void)? = nil) {
        dispatch_async(queue) { [weak self] in
            guard let strongSelf = self else {
                return
            }
            
            // remove object in memory
            strongSelf.memoryCache.removeObjectForKey(key)
            
            // remove object on disk
            let path = FileSystem.encodedPathForKey(key, rootPath: strongSelf.cachePath)
            let success = FileSystem.removeItemAtPath(path)
            
            // signal completion if necessary
            if let block = completion {
                dispatch_async(dispatch_get_main_queue()) { 
                    block(success)
                }
            }
        }
    }
    
    func removeAllObjects(completion: ((Bool) -> Void)? = nil) {
        dispatch_async(queue) { [weak self] in
            guard let strongSelf = self else {
                return
            }
            
            // remove cache directory (in other words, all files)
            let success = FileSystem.removeItemAtPath(strongSelf.cachePath)
            
            // recreate the cache directory
            if success == true {
                FileSystem.createDirectory(strongSelf.cachePath)
                
                // remove all objects from memory cache
                strongSelf.memoryCache.removeAllObjects()
            }
            
            if let block = completion {
                dispatch_async(dispatch_get_main_queue()) {
                    block(success)
                }
            }
        }
    }
    
    
    func trimToDate(date: NSDate, _ completion: (() -> Void)? = nil) {
        let pointInTime = date.copy() as! NSDate
        
        dispatch_async(queue) { [weak self] in
            guard let strongSelf = self else {
                return
            }
            
            // NSCache lacks an enumerating function, so purge it all
            strongSelf.memoryCache.removeAllObjects()
            
            FileSystem.enumerateItemsAtPath(strongSelf.cachePath, { (filePath, stop) in
                if let modificationDate = FileSystem.modificationDateOfItemAtPath(filePath) where modificationDate.relationToDate(pointInTime) == .Before {
                    FileSystem.removeItemAtPath(filePath)
                }
            })
            
            if let block = completion {
                dispatch_async(dispatch_get_main_queue()) {
                    block()
                }
            }
        }
    }
}



// MARK: Custom Accessors

extension DiskCache {
    var name: String {
        return memoryCache.name
    }
}




// MARK: NSDate helpers

private extension NSDate {
    enum TimeRelation {
        case Before, Same, After
    }
    
    func relationToDate(otherDate: NSDate) -> TimeRelation {
        let result = self.compare(otherDate)
        
        switch result {
        case .OrderedAscending:
            return .Before
        case .OrderedDescending:
            return .After
        case .OrderedSame:
            return .Same
        }
    }
}

