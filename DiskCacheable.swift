//
//  DiskCacheable.swift
//  Prose
//
//  Created by Shawn Throop on 18/04/16.
//  Copyright © 2016 Silent H Designs. All rights reserved.
//

import Foundation

protocol DiskCacheable {
    associatedtype UncacheableValueType
    
    static func valueFromData(data: NSData) throws -> UncacheableValueType
    static func toDataFromValue(value: UncacheableValueType) throws -> NSData
}