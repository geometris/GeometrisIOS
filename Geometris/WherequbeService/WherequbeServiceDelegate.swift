//
//  WherequbeServiceDelegate.swift
//  Geometris
//
//  Created by Bipin Kadel on 2/16/18.
//  Copyright © 2018 geometris. All rights reserved.
//

import Foundation

/**
 The delegate of a WherequbeService object must adopt the WherequbeServiceDelegate protocol.
 
 WherequbeService notifies the delegate about events and messages using this protocol.
 */
@objc public protocol WherequbeServiceDelegate {
    /**
     Whereqube was discovered.
     
     - Parameters:
     - wherequbeService: delegator object
     - whereqube: whereqube that was discovered
     */
    func wherequbeService(_ wherequbeService: WherequbeService, didDiscover whereqube: Whereqube)
    
    /**
     Whereqube successfully connected to device.
     
     - Parameters:
     - wherequbeService: delegator object
     - whereqube: connected device
     */
    func wherequbeService(_ wherequbeService: WherequbeService, didConnect whereqube: Whereqube)
    
    /**
     Device failed to connect.
     
     - Parameters:
     - wherequbeService: delegator object
     - whereqube: device that failed to connect
     */
    func wherequbeService(_ wherequbeService: WherequbeService, didFailToConnect whereqube: Whereqube)
    
    /**
     Device has disconnected from the device.
     
     - Parameters:
     - wherequbeService: delegator object
     - whereqube: device that disconnected
     */
    func wherequbeService(_ wherequbeService: WherequbeService, didDisconnect whereqube: Whereqube)
    
    /**
     Device has sent a preiodic event
     
     - Parameters:
     - wherequbeService: delegator object
     - event: event notification that device has sent
     */
    func wherequbeService(_ wherequbeService: WherequbeService, didReceive response: RequestType)
 
    
    /**
     WherequbeService detected that central's bluetooth state has changed.
     
     - Parameters:
     - wherequbeService: delegator object
     - poweredOn: indicates whether the central's Bluetooth is now powered On or Off
     */
    func wherequbeService(_ wherequbeService: WherequbeService, bluetoothChangedState poweredOn: Bool)
    
    /**
     WherequbeService has encountered an error
     
     - Parameters:
     - wherequbeService: delegator object
     - error: error type
     */
    func wherequbeService(_ wherequbeService: WherequbeService, onError error: WherequbeServiceError)
    
}

