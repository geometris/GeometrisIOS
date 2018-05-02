//
//  WQExtensions.swift
//  Geometris
//
//  Created by Bipin Kadel on 2/16/18.
//  Copyright © 2018 geometris. All rights reserved.
//

import Foundation
extension Data {
    
    internal var hexString: String {
        let pointer = self.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> UnsafePointer<UInt8> in
            return bytes
        }
        let array = getByteArray(pointer)
        
        return array.reduce("") { (result, byte) -> String in
            result + String(format: "%02x", byte)
        }
    }
    
    func toUInt8Array() -> [UInt8] {
        var values = [UInt8](repeating:0, count:self.count)
        self.copyBytes(to: &values, count:self.count)
        return values
    }
    
    func toString() -> String? {
        return String(data: self, encoding: .utf8)
    }
    
    var dataString: String? { return String(data: self, encoding: .utf8) }

    fileprivate func getByteArray(_ pointer: UnsafePointer<UInt8>) -> [UInt8] {
        let buffer = UnsafeBufferPointer<UInt8>(start: pointer, count: count)
        return [UInt8](buffer)
    }
}




extension Bool {
    init?(_ num: Int) {
        if num != 1 && num != 0 {
            return nil
        }
        self.init(num != 0)
    }
    
    init?(_ string: String) {
        if let num = Int(string) {
            if num != 1 && num != 0 {
                return nil
            }
            self.init(num != 0)
        } else {
            return nil
        }
    }
}

