//
//  BaseResponse.swift
//  Geometris
//
//  Created by Bipin Kadel on 3/20/18.
//  Copyright © 2018 geometris. All rights reserved.
//

import Foundation

public class BaseResponse: RequestType {
    /// ReqType
    public internal(set) var messageId :Error?
    
    init(requestId reqId: ReqType, withError error: Error?){
        messageId = error
        super.init(requestId: reqId)
    }
    
}
