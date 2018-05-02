//
//  WherequbeServiceState.swift
//  Geometris
//
//  Created by Bipin Kadel on 2/16/18.
//  Copyright © 2018 geometris. All rights reserved.
//

import Foundation


@objc public enum WherequbeServiceState: Int {
    /// WherequbeService state is idle - there are no wherequbes
    /// connected, and device isn't scanning.
    case idle
    /// WherequbeService is currently trying to connect to a whereqube.
    case connecting
    /// WherequbeService is connected to a whereqube.
    case connected
    /// WherequbeService is scanning for whereqube.
    case scanning
    /// WherequbeService is disconnecting from a whereqube.
    case disconnecting
    /// WherequbeService has disconnected from a whereqube.
    case disconnected
    /// WherequbeService is attempting to reconnect to whereqube.
    case reconnecting
}
