//
//  GeoResponse.swift
//  Geometris
//
//  Created by Bipin Kadel on 2/26/18.
//  Copyright © 2018 geometris. All rights reserved.
//

import Foundation

public class GeoResponse: RequestType {
    /// ReqType
    public internal(set) var geoData:GeoData
    
    init(requestId reqId: ReqType, geoData gData: GeoData){
         geoData = gData
         super.init(requestId: reqId)
    }
    
}
