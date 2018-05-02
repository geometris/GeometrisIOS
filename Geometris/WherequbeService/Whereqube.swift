//
//  Whereqube.swift
//  Geometris
//
//  Created by Bipin Kadel on 2/16/18.
//  Copyright © 2018 geometris. All rights reserved.
//

import Foundation

/**
 Whereqube information
 */
@objc public class Whereqube: NSObject {
    /// name
    public var wqName: String?
    /// UUID
    public var uuid: String
    /// Signal strength
    public var rssi: NSNumber
    
    init(name: String?, uuid: String, rssi: NSNumber) {
        self.wqName = name
        self.uuid = uuid
        self.rssi = rssi
        super.init()
    }
    
    init(name: String?, uuid: String) {
        self.wqName = name
        self.uuid = uuid
        self.rssi = 0
        super.init()
    }
    
}
