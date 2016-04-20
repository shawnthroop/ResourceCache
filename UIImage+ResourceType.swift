//
//  UIImage+ResourceType.swift
//  Prose
//
//  Created by Shawn Throop on 20/04/16.
//  Copyright © 2016 Silent H Designs. All rights reserved.
//

import UIKit


extension UIImage: ResourceType {}


// MARK: RemoteFetchable

extension UIImage: RemoteFetchable {
    static func fromFetchedData(data: NSData) throws -> UIImage {
        return UIImage(data: data)!
    }
}



// MARK: DiskCacheable

extension UIImage {
    static func valueFromData(data: NSData) throws -> UIImage {
        return UIImage(data: data)!
    }
    
    static func toDataFromValue(value: UIImage) throws -> NSData {
        return UIImagePNGRepresentation(value)!
    }
}