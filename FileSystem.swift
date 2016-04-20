//
//  FileSystem.swift
//  Prose
//
//  Created by Shawn Throop on 20/04/16.
//  Copyright © 2016 Silent H Designs. All rights reserved.
//

import Foundation

// FileSystem is an empty struct that provides convenient access to the file system. 
// All functions operate on the calling queue.

struct FileSystem {}


// MARK: Paths

extension FileSystem {
    static var cachesPath: String {
        return NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0]
    }
    
    
    static func encodedPathForKey(key: String, rootPath: String) ->  String {
        return (rootPath as NSString).stringByAppendingPathComponent(encodedString(key))
    }
}



// MARK: Writing/Reading/Removing Data

extension FileSystem {
    static func createItemWithData(data: NSData, atPath path: String) -> Bool {
        var success = true
        
        do {
            try data.writeToFile(path, options: .DataWritingAtomic)
        } catch {
            success = false
            logError("Failed to creating item on disk", error: error)
        }
        
        return success
    }
    
    
    static func itemDataAtPath(path: String) -> NSData? {
        var data: NSData?
        
        if fileManager.fileExistsAtPath(path)  {
            do {
                data = try NSData(contentsOfFile: path, options: [])
            } catch {
                logError("Failed to get data on disk", error: error)
            }
        }
        
        if data != nil {
            updateModificationDateOfItemAtPath(path, toDate: NSDate())
        }
        
        return data
    }

    
    static func removeItemAtPath(path: String) -> Bool {
        var success = true
        
        if fileManager.fileExistsAtPath(path) == true {
            do {
                try fileManager.removeItemAtPath(path)
            } catch {
                success = false
                logError("Failed to remove item on disk", error: error)
            }
        }
        
        return success
    }
}



// MARK: Transform

extension FileSystem {
    static func createObject<T>(obj: T, atPath path: String, @noescape _ transform: (T) throws -> NSData) -> Bool {
        var success = true; var data: NSData?
        
        do {
            data = try transform(obj)
        } catch {
            success = false
            logError("Failed to transform object into data", error: error)
        }
        
        if success == true, let dataToWrite = data {
            createItemWithData(dataToWrite, atPath: path)
        }
        
        return success
    }
    
    
    static func objectAtPath<T>(path: String, @noescape _ transform: (NSData) throws -> T) -> T? {
        var obj: T?
        
        if let data = itemDataAtPath(path) {
            do {
                obj = try transform(data)
            } catch {
                logError("Failed to transform data into object", error: error)
            }
        }
        
        return obj
    }
}




// MARK: Directory

extension FileSystem {
    static func createDirectory(path: String) -> Bool {
        
        var isDir = ObjCBool(false)
        
        if fileManager.fileExistsAtPath(path, isDirectory: &isDir) == true {
            let isDirectory = Bool(isDir)
            
            if isDirectory == true {
                return true
                
            } else {
                logError("Failed to create directory on disk. A file already exists at path: \(path)", error: nil)
                return false
            }
        }
        
        var success = true
        
        do {
            try fileManager.createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil)
        } catch{
            success = false
            logError("Failed to create directory on disk", error: error)
        }
        
        return success
    }
}



// MARK: Attributes

extension FileSystem {
    static func updateItemAtPath(path: String, withAttributes attributes: [String: AnyObject]) -> Bool {
        var success = true
        
        if fileManager.fileExistsAtPath(path) == true {
            do {
                try fileManager.setAttributes(attributes, ofItemAtPath: path)
            } catch {
                success = false
                logError("Failed updating attributes on disk", error: error)
            }
            
        } else {
            success = false
        }
        
        return success
    }
    
    
    static func attributesOfItemAtPath(path: String) -> [String: AnyObject]? {
        var attributes: [String: AnyObject]?
        
        if fileManager.fileExistsAtPath(path) == true {
            do {
                attributes = try fileManager.attributesOfItemAtPath(path)
            } catch {
                logError("Failed retrieving attributes on disk", error: error)
            }
        }
        
        return attributes
    }
    
    
    static func updateModificationDateOfItemAtPath(path: String, toDate date: NSDate) -> Bool {
        return updateItemAtPath(path, withAttributes: [NSFileModificationDate: date.copy()])
    }
    
    static func modificationDateOfItemAtPath(path: String) -> NSDate? {
        guard let attributes = attributesOfItemAtPath(path) else {
            return nil
        }
        
        return attributes[NSFileModificationDate] as? NSDate
    }
}



extension FileSystem {
    static func enumerateItemsAtPath(path: String, @noescape _ block: (filePath: String, inout stop: Bool) -> Void) {
        
        let url = NSURL(fileURLWithPath: path)
        if let enumerator = fileManager.enumeratorAtURL(url, includingPropertiesForKeys: nil, options: [], errorHandler: nil) {
            while let filePath = enumerator.nextObject() as? String {
                var stop = false
                
                block(filePath: filePath, stop: &stop)
                
                if stop == true {
                    break
                }
            }
        }
    }
}




private extension FileSystem {
    static var fileManager: NSFileManager {
        return NSFileManager.defaultManager()
    }
    
    static func encodedString(str: String) -> String {
        if str == "" {
            return str
        }
        
        return str.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet(charactersInString: ".:/%").invertedSet)!
    }
    
    static func logError(context: String, error: ErrorType?) {
        if let err = error as? NSError {
            print("\(context): \(err.localizedDescription)")
        } else {
            print(context)
        }
    }
}

