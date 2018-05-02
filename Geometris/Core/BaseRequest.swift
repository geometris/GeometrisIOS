//
//  BaseRequest.swift
//  Geometris
//
//  Created by Bipin Kadel on 2/21/18.
//  Copyright © 2018 geometris. All rights reserved.
//

import Foundation
public enum ReqType: Int {
    
    case NOTHING = 1
    
    case OBD_MEASUREMENT = 2
   
    case WRITE_APP_IDENTIFIER = 3
    
    case REQUEST_START_UDEVENTS = 4
    
    case REQUEST_STOP_UDEVENTS = 5
    
    case PURGE_UDEVENTS = 6
    
    case REQUEST_DEVICE_ADDRESS = 7
}

public class RequestType: NSObject {
    public internal(set) var requestType: ReqType = ReqType.NOTHING
    init(requestId reqId: ReqType){
        super.init()
        requestType = reqId
    }
}

 public class GeoRequest: RequestType {
    /// ReqType
    var geoData:GeoData
    
    init(requestId reqId: ReqType, geoData gData: GeoData){
        geoData = gData
        super.init(requestId: reqId)
    }
    
}
