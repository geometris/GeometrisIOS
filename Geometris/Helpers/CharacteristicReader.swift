//
//  CharacteristicReader.swift
//  Geometris
//
//  Created by Bipin Kadel on 2/22/18.
//  Copyright © 2018 geometris. All rights reserved.
//

import Foundation
struct CharacteristicReader {
    
    static func readUInt8Value(ptr aPointer : inout UnsafeMutablePointer<UInt8>) -> UInt8 {
        let val = aPointer.pointee
        aPointer = aPointer.successor()
        return val
    }
    
    static func readSInt8Value(ptr aPointer : UnsafeMutablePointer<UInt8>) -> Int8 {
        return Int8(aPointer.successor().pointee)
    }
    
    static func readUInt16Value(ptr aPointer : inout UnsafeMutablePointer<UInt8>) -> UInt16 {
        let anUInt16Pointer = UnsafeMutablePointer<UInt16>(OpaquePointer(aPointer))
        let val = CFSwapInt16LittleToHost(anUInt16Pointer.pointee)
        aPointer = aPointer.advanced(by: 2)
        return val
    }
    
    static func readSInt16Value(ptr aPointer : inout UnsafeMutablePointer<UInt8>) -> Int16 {
        let anInt16Pointer = UnsafeMutablePointer<Int16>(OpaquePointer(aPointer))
        let val = CFSwapInt16LittleToHost(UnsafeMutablePointer<UInt16>(OpaquePointer(anInt16Pointer)).pointee)
        aPointer = aPointer.advanced(by: 2)
        return Int16(val)
    }
    
    static func readUInt32Value(ptr aPointer : inout UnsafeMutablePointer<UInt8>) -> UInt32 {
        let anInt32Pointer = UnsafeMutablePointer<UInt32>(OpaquePointer(aPointer))
        let val = (UnsafeMutablePointer<UInt32>(OpaquePointer(anInt32Pointer)).pointee)
        aPointer = aPointer.advanced(by: 4)
        return UInt32(val)
    }
    
    static func readSInt32Value(ptr aPointer : inout UnsafeMutablePointer<UInt8>) -> Int32 {
        let anInt32Pointer = UnsafeMutablePointer<UInt32>(OpaquePointer(aPointer))
        let val  = (UnsafeMutablePointer<UInt32>(OpaquePointer(anInt32Pointer)).pointee)
        aPointer = aPointer.advanced(by: 4)
        return Int32(bitPattern:val)
    }
    
    static func fixUint32Endian(withUInt data: UInt32)->UInt32
    {
        var returndata: UInt32 = 0
        returndata = ((data >> 16) | (data << 16));
        return returndata;
    }
}
