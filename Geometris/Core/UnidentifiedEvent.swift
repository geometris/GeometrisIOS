//
//  UnidentifiedEvent.swift
//  Geometris
//
//  Created by Bipin Kadel on 3/27/18.
//  Copyright © 2018 geometris. All rights reserved.
//

import Foundation
public class UnidentifiedEvent: NSObject  {
    public internal(set) var reason                             : Int?
    public internal(set) var timestamp                          : Date?
    public internal(set) var engTotalHours                      : Double
    public internal(set) var vehicleSpeed                       : Double
    public internal(set) var odometer                           : Double
    public internal(set) var longitude                          : Double
    public internal(set) var latitude                           : Double
    public internal(set) var gpsTimeStamp                       : Date
    
    override init(){
        reason = nil
        timestamp = nil
        engTotalHours = 0
        vehicleSpeed = 0
        odometer = 0
        longitude = 0
        latitude = 0
        gpsTimeStamp = Date(timeIntervalSince1970: 0)
        super.init()
    }
    
}
