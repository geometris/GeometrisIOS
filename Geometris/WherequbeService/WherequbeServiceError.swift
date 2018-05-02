//
//  WherequbeServiceError.swift
//  Geometris
//
//  Created by Bipin Kadel on 2/16/18.
//  Copyright © 2018 geometris. All rights reserved.
//

import Foundation


/**
 All possible `WherequbeService` error events.
 */
@objc public enum WherequbeServiceError: Int {
    /// Method call succeeded.
    case resultOk = 0
    
    /// Generic failure.
    case failed = 1
    
    /// Invalid parameters were passed to the method.
    case invalidParameters = 2
    
    /// A pre-requisite was not met when the method was executed.
    case invalidState = 3
    
    /// Timeout.
    case timeout = 8
    
    /// Device or connection setup doesn't support the operation.
    case unavailable = -8
}
