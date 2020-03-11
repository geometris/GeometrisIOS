//
//  OBDMessage.swift
//  Geometris
//
//  Created by Bipin Kadel on 2/22/18.
//  Copyright © 2018 geometris. All rights reserved.
//

import Foundation

class OBDMessage {
    let RPM_MAX_AGE_IN_SECONDS:Double   = 30; // 30 seconds
    let RPM_THRESHOLD           = 200.00;
    var prevEngineRPM: Double = 0
    var prevEngineRPMTimeStamp: Date = Date()
    let PACKET_COUNT_OFFSET     = 0
    let PACKET_IDENTIFIER       = 1
    let PROTOCOL_IDENTIFIER     = 2
    let TOTAL_PACKET_INDEX      = 3
    
    var packetList  : [Int: Data]
    var pi              : Set<Int>
    var protocolId      : Int
    var totalPacket     : Int
    
    init()
    {
        packetList = [Int: Data]()
        pi = Set<Int>()
        protocolId = -1
        totalPacket = 0
        
    }
    func reset(){
        totalPacket = 0
        pi.removeAll()
        packetList.removeAll()
        protocolId = -1
    }
    
    private func isRPMActive()->Bool {
        let now = Date()
        if (prevEngineRPM < RPM_THRESHOLD || ((now.timeIntervalSince(prevEngineRPMTimeStamp)) > RPM_MAX_AGE_IN_SECONDS) ) {
            return false
        }
        else {
            return true
        }
    }
    private func setProtocolId(withId id: Int)
    {
        protocolId = id
        if protocolId == 0 {
            totalPacket = 7
        }
    }
    private func getProtocolId()->Int
    {
        return protocolId;
    }
    private func setTotalPacket(withTotalPacket total: Int)
    {
        totalPacket = total
    }
    
    private func getTotalPacket()-> Int{
        return totalPacket
    }
    func isFull() -> Bool{
        if totalPacket > 0 {
            if protocolId == 0 {
                return pi.count >= 7
            }
            else if protocolId >= 1 {
                return pi.count >= totalPacket
            }
        }
        return false
    }
    
    func insertMessage(withData data: Data) {
        if data.count <= 0 {
            return
        }
        print(data.hexString)
        let value = UnsafeMutablePointer<UInt8>(mutating: (data as NSData).bytes.bindMemory(to: UInt8.self, capacity: data.count))
        let packet_count = value[PACKET_COUNT_OFFSET]
        if packet_count > 0 && pi.count == 0 {
            return
        }
        if packet_count == 0 {
            if data.count > 1 && value[PACKET_IDENTIFIER] == 0xCB {
                let protocol_id = value[PROTOCOL_IDENTIFIER]
                let totalPacket = value[TOTAL_PACKET_INDEX]
                setProtocolId(withId: Int(protocol_id))
                setTotalPacket(withTotalPacket: Int(totalPacket))
            }
            else {
                setProtocolId(withId: 0)
            }
        }
        insertPacket(withData: data, withIndex: Int(packet_count))
        insertIndex(withIndex: Int(packet_count))
        
    }
    
    private func insertIndex(withIndex index: Int){
        pi.insert(index)
    }
    
    private func insertPacket(withData data: Data,withIndex index: Int ) {
        packetList[index] = data
    }
    
    private func setRPM(withRPM RPM:Double, withRPMTime rpmTime: Date, withGeoData geoData: GeoData) {
        if RPM != -1 {
            geoData.RPM = RPM
            prevEngineRPM = RPM
            prevEngineRPMTimeStamp = rpmTime
        }
        else {
            if isRPMActive() {
                geoData.RPM = prevEngineRPM
            }
            
        }
    }
    func getGeoData()->GeoData {
        
        let geoData = GeoData()
        geoData.protocolId = getProtocolId()
        let sTotalPacket = getTotalPacket()
        
        if getProtocolId() == 0 {
            var counter = 0
            var vinBuffer: String = ""
            while counter < sTotalPacket {
                let sData : Data = packetList[counter]!
                var sValue = UnsafeMutablePointer<UInt8>(mutating: (sData as NSData).bytes.bindMemory(to: UInt8.self, capacity: sData.count))
                let pCount = CharacteristicReader.readUInt8Value(ptr: &sValue)
                switch(pCount)
                {
                case 0:
                    if(sData.count>1)
                    {
                        var pointer = sData.withUnsafeBytes { (bytes: UnsafePointer<CChar>) -> UnsafePointer<CChar> in
                            return bytes }
                        pointer = pointer.advanced(by: 1)
                        vinBuffer = String(cString: pointer)
                    }
                    
                    break
                    
                case 1:
                    if(sData.count>1 && vinBuffer.count>0)
                    {
                        var pointer = sData.withUnsafeBytes { (bytes: UnsafePointer<CChar>) -> UnsafePointer<CChar> in
                            return bytes
                        }
                        pointer = pointer.advanced(by: 1)
                        vinBuffer += String(cString: pointer)
                        
                    }
                    geoData.VIN = vinBuffer;
                    
                    break
                case 2:
                    var rValue = Double(CharacteristicReader.readSInt32Value(ptr: &sValue))
                    if rValue != -1 {
                        geoData.odometer = rValue
                    }
                    
                    
                    rValue = Double(CharacteristicReader.readSInt32Value(ptr: &sValue))
                    setRPM(withRPM: rValue, withRPMTime: Date(), withGeoData: geoData)
                    /*if rValue != -1 {
                        geoData.RPM = rValue
                    }*/
                    
                    
                    
                    rValue = Double(CharacteristicReader.readSInt32Value(ptr: &sValue))
                    
                    rValue = Double(CharacteristicReader.readSInt32Value(ptr: &sValue))
                    if rValue != -1 {
                        geoData.speed = rValue
                        
                    }
                    
                    break
                    
                case 3:
                    
                    let rValue = Double(CharacteristicReader.readSInt32Value(ptr: &sValue))
                    if rValue != -1{
                        geoData.fuelLevel = rValue
                    }
                    
                    break
                    
                case 4:
                    
                    break
                case 5:
                    
                    break
                case 6:
                    var rValue = Double(CharacteristicReader.readSInt32Value(ptr: &sValue))
                    //print("dpfag_inhibit_status is \(dpfag_inhibit_status)")
                    
                    rValue = Double(CharacteristicReader.readSInt32Value(ptr: &sValue))
                    if rValue != -1 {
                        geoData.engine_hours = rValue/10
                    }
                    
                    break
                default: break
                    
                }
                counter+=1
            }
            
        }
        else if getProtocolId() == 1 {
            var longData : Data = Data()
            for i in 0..<sTotalPacket
            {
                let sData : Data = packetList[i]!
                let sDataLength = sData.count
                var startIndex: Int = 0
                if i == 0 {
                    startIndex = TOTAL_PACKET_INDEX+2
                }
                else {
                    startIndex = 1
                }
                //print("sDatalenth : \(sDataLength)")
                let subSData : Data = sData.subdata(in: startIndex..<sDataLength)
                longData.append(subSData)
                
            }
            var sValue = UnsafeMutablePointer<UInt8>(mutating: (longData as NSData).bytes.bindMemory(to: UInt8.self, capacity: longData.count))
            
            let offsetPointer = sValue+longData.count
            
            let unidentifiedEvent = UnidentifiedEvent()
            var vinBuffer: String = ""
            var parseexit : Bool = false
            sValue = sValue.advanced(by: 2)
            
            while(sValue < offsetPointer)
            {
                
                let paramIndex = CharacteristicReader.readUInt16Value(ptr: &sValue)
                //paramIndex = paramIndex;
                switch(paramIndex)
                {
                case 0x01:
                    let vinlength = Int(CharacteristicReader.readSInt16Value(ptr: &sValue))
                    
                    var vinBytes :[UInt8]
                    var vIndex = 0
                    var i = 0
                    vinBytes = [UInt8]()
                    while vIndex < (vinlength*2) {
                        vinBytes.append(CharacteristicReader.readUInt8Value(ptr: &sValue))
                        sValue = sValue.advanced(by: 1)
                        vIndex += 2
                        i+=1
                    }
                    
                    let tmpVIN = String(data: Data(vinBytes), encoding: .utf8)
                    vinBuffer = tmpVIN!;
                    geoData.VIN = vinBuffer;
                    
                    break
                    case 0x02:
                        var value = CharacteristicReader.readUInt32Value(ptr: &sValue)
                        value =   CharacteristicReader.fixUint32Endian(withUInt: value)
                        let fvalue: Int32 = Int32(bitPattern: value)
                        let odometer = Double(fvalue)
                        if odometer != -1 {
                            geoData.odometer = odometer
                        }
        
                        break
                    case 0x03:
                        var value = CharacteristicReader.readUInt32Value(ptr: &sValue)
                        value =   CharacteristicReader.fixUint32Endian(withUInt: value)
                        let fvalue: Int32 = Int32(bitPattern: value)
                        let RPM = Double(fvalue)
                        setRPM(withRPM: RPM, withRPMTime: Date(), withGeoData: geoData)
                        /*if RPM != -1 {
                            geoData.RPM = RPM
                        }*/
                        
                        break
                    case 0x04:
                        sValue = sValue.advanced(by: 4)
                        break
                    case 0x05:
                        var value = CharacteristicReader.readUInt32Value(ptr: &sValue)
                        value =   CharacteristicReader.fixUint32Endian(withUInt: value)
                        let fvalue: Int32 = Int32(bitPattern: value)
                        let speed = Double(fvalue)
                        if speed != -1 {
                            geoData.speed = speed
                        }
                        
                        
                        break
                    
                    case 0x06:
                        var value = CharacteristicReader.readUInt32Value(ptr: &sValue)
                        value =   CharacteristicReader.fixUint32Endian(withUInt: value)
                        let fvalue: Int32 = Int32(bitPattern: value)
                        let fuelLevel = Double(fvalue)
                        if fuelLevel != -1 {
                            geoData.fuelLevel = fuelLevel
                        }
                        
                        break
                    case 0x07:
                        sValue = sValue.advanced(by: 4)
                        break
                    case 0x08:
                        
                        sValue = sValue.advanced(by: 4)
                        break
                    case 0x09:
                        
                        sValue = sValue.advanced(by: 4)
                        break
                    
                    case 0x0A:
                        
                        sValue = sValue.advanced(by: 4)
                        break
                    case 0x0B:
                        
                        sValue = sValue.advanced(by: 4)
                        break
                    case 0x0C:
                        
                        sValue = sValue.advanced(by: 4)
                        break
                    case 0x0D:
                        
                        //print("MIL Status is \(mil_status)")
                        sValue = sValue.advanced(by: 4)
                        break
                    case 0x0E:
                        
                        sValue = sValue.advanced(by: 4)
                        break
            
                    case 0x0F:
                        var serialLength = Int(CharacteristicReader.readSInt16Value(ptr: &sValue))
                        serialLength *= 2
                        sValue = sValue.advanced(by: serialLength)
                        
                        break
                    case 0x10:
                        
                        sValue = sValue.advanced(by: 4)
                        break
                    case 0x11:
                        var value = CharacteristicReader.readUInt32Value(ptr: &sValue)
                        value =   CharacteristicReader.fixUint32Endian(withUInt: value)
                        let fvalue: Int32 = Int32(bitPattern: value)
                        var engine_hours = Double(fvalue)
                        if engine_hours != -1
                        {
                            engine_hours/=10
                            geoData.engine_hours = engine_hours
                        }
                        
                        break
                    case 0x12:
                        
                        sValue = sValue.advanced(by: 4)
                        break
                    case 0x013:
                        var value = CharacteristicReader.readUInt32Value(ptr: &sValue)
                        value =   CharacteristicReader.fixUint32Endian(withUInt: value);
                        let fvalue: Int32 = Int32(bitPattern: value)
                        var latitude = Double(fvalue)
                        latitude /= 100000
                        geoData.latitude = latitude
                        
                        
                        break
                    case 0x14:
                        var value = CharacteristicReader.readUInt32Value(ptr: &sValue)
                        value =   CharacteristicReader.fixUint32Endian(withUInt: value)
                        let fvalue: Int32 = Int32(bitPattern: value)
                        //let signedValue = Int(value)
                        var longitude = Double(fvalue)
                        longitude /= 100000
                        geoData.longitude = longitude
                        //print("longitude is \(longitude)")
                        
                        break
                    case 0x015:
                        var value = CharacteristicReader.readUInt32Value(ptr: &sValue)
                        value =   CharacteristicReader.fixUint32Endian(withUInt: value)
                        var locationTimeStamp: Double
                        if value == 0xFFFFFFFF {
                            locationTimeStamp = -1
                        }
                        else {
                            locationTimeStamp = Double(value)
                            let gpsTime = Date(timeIntervalSince1970: locationTimeStamp)
                            geoData.locationTimeStamp = gpsTime
                        }
                        //print("Location TimeStamp is \(locationTimeStamp)")
                        
                        break
                
                case 0x16, 0x17, 0x18, 0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E:
                    switch (paramIndex) {
                    case 0x1E:
                        var value = CharacteristicReader.readUInt32Value(ptr: &sValue)
                        value =   CharacteristicReader.fixUint32Endian(withUInt: value);
                        geoData.totalUdrvEvents = Int(value)
                        break

                    case 0x17:
                        var value = CharacteristicReader.readUInt32Value(ptr: &sValue)
                        value =   CharacteristicReader.fixUint32Endian(withUInt: value)
                        var tstamp : Double
                        if value == 0xFFFFFFFF {
                            tstamp = -1
                        }
                        else {
                            tstamp = Double(value)
                            let dtime = Date(timeIntervalSince1970: tstamp)
                            unidentifiedEvent.timestamp = dtime
                        }
                        //print("Unidentified TimeStamp is \(tstamp)")
                        break

                    case 0x16:
                        var value = CharacteristicReader.readUInt32Value(ptr: &sValue)
                        value =   CharacteristicReader.fixUint32Endian(withUInt: value);
                        unidentifiedEvent.reason = Int(value)
                        break

                    case 0x18:
                        var value = CharacteristicReader.readUInt32Value(ptr: &sValue)
                        value =   CharacteristicReader.fixUint32Endian(withUInt: value)
                        let fvalue: Int32 = Int32(bitPattern: value)
                        var engine_hours = Double(fvalue)
                        engine_hours/=10
                        unidentifiedEvent.engTotalHours = engine_hours
                        break

                    case 0x19:
                        var value = CharacteristicReader.readUInt32Value(ptr: &sValue)
                        value =   CharacteristicReader.fixUint32Endian(withUInt: value)
                        let fvalue: Int32 = Int32(bitPattern: value)
                        let speed = Double(fvalue)
                        unidentifiedEvent.vehicleSpeed = speed
                        break

                    case 0x1A:
                        var value = CharacteristicReader.readUInt32Value(ptr: &sValue)
                        value =   CharacteristicReader.fixUint32Endian(withUInt: value)
                        let fvalue: Int32 = Int32(bitPattern: value)
                        let odometer = Double(fvalue)
                        unidentifiedEvent.odometer = odometer
                        //print("unidentified odometer is \(odometer)")
                        break

                    case 0x1B:
                        var value = CharacteristicReader.readUInt32Value(ptr: &sValue)
                        value =   CharacteristicReader.fixUint32Endian(withUInt: value);
                        let fvalue: Int32 = Int32(bitPattern: value)
                        var latitude = Double(fvalue)
                        latitude /= 100000
                        unidentifiedEvent.latitude = latitude
                        //print("latitude is \(latitude)")
                        break

                    case 0x1C:
                        var value = CharacteristicReader.readUInt32Value(ptr: &sValue)
                        value =   CharacteristicReader.fixUint32Endian(withUInt: value)
                        let fvalue: Int32 = Int32(bitPattern: value)
                        //let signedValue = Int(value)
                        var longitude = Double(fvalue)
                        longitude /= 100000
                        unidentifiedEvent.longitude = longitude
                        //print("longitude is \(longitude)")
                        break

                    case 0x1D:
                        var value = CharacteristicReader.readUInt32Value(ptr: &sValue)
                        value =   CharacteristicReader.fixUint32Endian(withUInt: value)
                        var locationTimeStamp: Double
                        if value == 0xFFFFFFFF {
                            locationTimeStamp = -1
                        }
                        else {
                            locationTimeStamp = Double(value)
                            let gpsTime = Date(timeIntervalSince1970: locationTimeStamp)
                            unidentifiedEvent.gpsTimeStamp = gpsTime
                        }
                        //print("Unidentified Location TimeStamp is \(locationTimeStamp)")
                        break

                    default:
                        parseexit = true
                        print("default udrv")
                    }
                    
                break
                
                default:
                    parseexit = true
                    
                }
                if parseexit == true{
                    break
                }
            }
            if unidentifiedEvent.timestamp != nil {
                geoData.unidentifiedEventArray.append(unidentifiedEvent)
            }
        }
        let dateFormater = DateFormatter()
        dateFormater.dateFormat = "MM-dd-yyyy HH:mm:ss"
        let datestr = dateFormater.string(from: geoData.date)
        var st = String()
        st = st + "vi:" + geoData.VIN + " od:" + String(geoData.odometer) + " r:" + String(geoData.RPM)
        st = st + " sp:" + String(geoData.speed) + " ehr:" + String(geoData.engine_hours)
        st = st + " fl:" + String(geoData.fuelLevel)
        st = st + " lt:" + String(geoData.latitude) + " ln:" + String(geoData.longitude)
        st = st + " date:" + datestr
        
        print(st)
        return geoData
        }
        
    }

