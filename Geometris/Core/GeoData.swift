//
//  GeoData.swift
//  Geometris
//
//  Created by Bipin Kadel on 2/22/18.
//  Copyright © 2018 geometris. All rights reserved.
//

import Foundation
public class GeoData: NSObject  {
    public internal(set) var date                                : Date
    public internal(set) var protocolId                          : Int?
    public internal(set) var VIN                                 : String=""
    public internal(set) var odometer                            : Double
    public internal(set) var engine_hours                        : Double
    public internal(set) var speed                               : Double
    public internal(set) var RPM                                 : Double
    public internal(set) var longitude                           : Double
    public internal(set) var latitude                            : Double
    public internal(set) var locationTimeStamp                   : Date
    public internal(set) var totalUdrvEvents                     : Int
    public internal(set) var unidentifiedEventArray              : [UnidentifiedEvent]
    override init(){
        date = Date()
        protocolId = nil
        odometer = 0
        engine_hours = 0
        speed = 0
        RPM = 0
        longitude = 0
        latitude = 0
        locationTimeStamp = Date(timeIntervalSince1970: 0)
        totalUdrvEvents = 0
        unidentifiedEventArray = [UnidentifiedEvent]()
        super.init()
    }
}
