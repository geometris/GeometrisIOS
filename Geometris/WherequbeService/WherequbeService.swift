//
//  WherequbeService.swift
//  Geometris
//
//  Created by Bipin Kadel on 2/16/18.
//  Copyright © 2018 geometris. All rights reserved.
//

import Foundation
import CoreBluetooth

public class WherequbeService: NSObject {
    public var state: WherequbeServiceState = .idle {
        didSet {
            guard debug else {
                return
            }
            
            let stateStr: String
            switch state {
            case .connected: stateStr = "connected"
            case .connecting: stateStr = "connecting"
            case .disconnected: stateStr = "disconnected"
            case .disconnecting: stateStr = "disconnecting"
            case .idle: stateStr = "idle"
            case .reconnecting: stateStr = "reconnecting"
            case .scanning: stateStr = "scanning"
            }
            print("State changed to: \(stateStr)")
        }
    }
    
    fileprivate let wqSmartService = WQSmartService.sharedInstance
    
    /// Auto reconnect in case of unexpected disconnect
    public var autoReconnect: Bool = false
    
    /// `true` if device bluetooth is on, `false` if it's off
    public fileprivate(set) var bluetoothOn: Bool = false
    
    /// Use this for displaying debug messages
    public var debug: Bool = false
    
    /// Active whereqube, `nil` if there is no whereqube connected
    public var whereqube: Whereqube? {
        get {
            guard state == .connected else {
                return nil
            }
            guard let wherequbePeripheral = wqSmartService.whereqube else {
                return nil
            }
            
            return Whereqube(name: wherequbePeripheral.name, uuid: wherequbePeripheral.identifier.uuidString)
        }
    }
    
    
    /**
     The object that acts as a delegate of `WherequbeService`.
     
     The delegate must adopt the `WherequbeServiceDelegate` protocol.
     */
    public var delegate: WherequbeServiceDelegate?
    
    /// singleton instance of the `WherequbeService`
    public static let sharedInstance = WherequbeService()
    
    private override init() {
        super.init()
        wqSmartService.delegate = self
    }
    
    
    // MARK: - WherequbeService endpoints
    
    /**
     Scans for compatible wherqubes.
     
     Upon discovering  whereqube, it notifies the registered delegate.
     */
    public func startScanningForWherequbes() {
        guard state == .idle else {
            return
        }
        
        state = .scanning
        wqSmartService.startScanning()
    }
    
    /**
     Stops the scanning for compatible wherequbes.
     */
    public func stopScanningForWherequbes() {
        guard state == .scanning else {
            return
        }
        
        state = .idle
        wqSmartService.stopScanning()
    }
    
    /**
     Attempt to connect to device with the specified UUID as `String`.
     
     Upon connecting to a device, it notifies the registered delegate.
     
     - Parameter wherequbeWithUUID: String describing UUID of the device you want to connect to
     */
    public func connectTo(wherequbeWithUUID wherequbeUUID: String) {
        switch(state) {
        case .idle, .scanning:
            do {
                try wqSmartService.connectTo(wqwithUUID: wherequbeUUID)
                state = .connecting
            } catch {
                delegate?.wherequbeService(self, didFailToConnect: Whereqube(name:nil, uuid:wherequbeUUID))
            }
            
        default: ()
        }
    }
    
    /**
     Disconnect from the device.
     
     Upon disconnecting it notifies the registered delegate.
     */
    public func disconnect() {
        if state != .idle || state != .disconnected{
            state = .disconnecting
            wqSmartService.disconnect()
        }
    }
    
    fileprivate func hasSupportVersionTwo()->Bool{
        guard state == .connected else {
            return false
        }
        if(wqSmartService.isCharacteristicExists(withService: WQSmartService.WQSmartUUID.Service.OBDService, withCharacteristic: WQSmartService.WQSmartUUID.Characteristics.OBDDataPointCharacteristics)){
            return true
        }
        return false
    }
    fileprivate func sendAppIdentification(){
        
        let bytes: [UInt8] = [0x01, 0x02]
        let data = Data(bytes: bytes, count: bytes.count)
        do {
            try wqSmartService.writeCharacteristicValue(withRequestId: ReqType.WRITE_APP_IDENTIFIER, forService: WQSmartService.WQSmartUUID.Service.OBDService,
                                                forCharacteristic: WQSmartService.WQSmartUUID.Characteristics.OBDDataPointCharacteristics, withData: data)
        } catch WQSmartServiceError.characteristicNotavailable {
            
        } catch {
            
        }
        
    }
    
    fileprivate func setTXNotification(withEnable flag: Bool){
        do {
            try wqSmartService.requestCharacteristicNotification(withRequestId: ReqType.OBD_MEASUREMENT, withService: WQSmartService.WQSmartUUID.Service.OBDService, withCharacteristic: WQSmartService.WQSmartUUID.Characteristics.OBDMeasurementCharacteristics, withEnable: flag)
        } catch WQSmartServiceError.characteristicNotavailable {
            
        } catch {
            
        }
        
    }
    
    fileprivate func sendRequest(withRequest requestType: RequestType)->Bool{
        if requestType.requestType == ReqType.REQUEST_DEVICE_ADDRESS {
            if hasSupportVersionTwo() && wqSmartService.isCharacteristicExists(withService: WQSmartService.WQSmartUUID.Service.OBDService, withCharacteristic: WQSmartService.WQSmartUUID.Characteristics.OBDDeviceAddressCharacteristics) {
                do {
                    
                    try wqSmartService.readCharacteristicValue(withRequestId: ReqType.REQUEST_DEVICE_ADDRESS, withService: WQSmartService.WQSmartUUID.Service.OBDService,
                                                               withCharacteristic: WQSmartService.WQSmartUUID.Characteristics.OBDDeviceAddressCharacteristics)
                    return true
                } catch WQSmartServiceError.characteristicNotavailable {
                   
                } catch {
                    
                }
            }
            return false
        }
        else if requestType.requestType == ReqType.REQUEST_START_UDEVENTS {
            if hasSupportVersionTwo() {
                do {
                    let bytes: [UInt8] = [0x02, 0x01]
                    let data = Data(bytes: bytes, count: bytes.count)
                    try wqSmartService.writeCharacteristicValue(withRequestId: ReqType.REQUEST_START_UDEVENTS, forService: WQSmartService.WQSmartUUID.Service.OBDService, forCharacteristic: WQSmartService.WQSmartUUID.Characteristics.OBDDataPointCharacteristics, withData: data)
                    return true
                } catch WQSmartServiceError.characteristicNotavailable {
                    
                } catch {
                    
                }
            }
            return false
        }
        else if requestType.requestType == ReqType.REQUEST_STOP_UDEVENTS{
            if hasSupportVersionTwo() {
                do {
                    let bytes: [UInt8] = [0x02, 0x00]
                    let data = Data(bytes: bytes, count: bytes.count)
                    try wqSmartService.writeCharacteristicValue(withRequestId: ReqType.REQUEST_STOP_UDEVENTS, forService: WQSmartService.WQSmartUUID.Service.OBDService, forCharacteristic: WQSmartService.WQSmartUUID.Characteristics.OBDDataPointCharacteristics, withData: data)
                    return true
                } catch WQSmartServiceError.characteristicNotavailable {
                    
                } catch {
                    
                }
            }
            return false
        } else if requestType.requestType == ReqType.PURGE_UDEVENTS {
            if hasSupportVersionTwo() {
                do {
                    let bytes: [UInt8] = [0x03, 0x01]
                    let data = Data(bytes: bytes, count: bytes.count)
                    try wqSmartService.writeCharacteristicValue(withRequestId: ReqType.PURGE_UDEVENTS, forService: WQSmartService.WQSmartUUID.Service.OBDService, forCharacteristic: WQSmartService.WQSmartUUID.Characteristics.OBDDataPointCharacteristics, withData: data)
                    return true
                } catch WQSmartServiceError.characteristicNotavailable {
                    
                } catch {
                    
                }
            }
            return false
        }
        return false
    }
    
    public func readDeviceAddress()->Bool{
        if(state == .connected) {
            if sendRequest(withRequest: RequestType(requestId: ReqType.REQUEST_DEVICE_ADDRESS)) {
                return true
            }
        }
        return false
    }
    
    
    public func startTransmittingUnidentifiedDriverMessages()->Bool {
        if state == .connected {
            if sendRequest(withRequest:RequestType(requestId: ReqType.REQUEST_START_UDEVENTS)) {
                return true
            }
            
        }
        return false
    }
 
    public func stopTransmittingUnidentifiedDriverMessages()->Bool {
        if state == .connected {
            if sendRequest(withRequest:RequestType(requestId: ReqType.REQUEST_STOP_UDEVENTS)) {
                return true
            }
            
        }
        return false
    }
    
    public func purgeTransmittingUnidentifiedDriverMessages()->Bool {
        if state == .connected {
            if sendRequest(withRequest:RequestType(requestId: ReqType.PURGE_UDEVENTS)) {
                return true
            }
        }
        return false
    }
}


extension WherequbeService: WQSmartServiceDelegate {
    
    
    func wqsmartservice(_ wqSmartService: WQSmartService, didDiscover whereqube: CBPeripheral, didReadRSSI RSSI: NSNumber) {
        delegate?.wherequbeService(self, didDiscover: Whereqube(name:whereqube.name, uuid: whereqube.identifier.uuidString, rssi:RSSI))
    }
    
    func wqsmartservice(_ wqSmartService: WQSmartService, didConnect whereqube: CBPeripheral) {
        state = .connected
        delegate?.wherequbeService(self, didConnect: Whereqube(name: whereqube.name, uuid: whereqube.identifier.uuidString))
        do {
            try wqSmartService.registerServices()
        } catch WQSmartServiceError.wherequbeUnavailable {
            delegate?.wherequbeService(self, didFailToConnect: Whereqube(name: nil, uuid: whereqube.identifier.uuidString))
        } catch {
            delegate?.wherequbeService(self, didFailToConnect: Whereqube(name: nil, uuid: whereqube.identifier.uuidString))
        }
    }
    
    func wqsmartservice(_ wqSmartService: WQSmartService, didFailToConnect whereqube: CBPeripheral) {
        if state == .connecting {
            state = .idle
            delegate?.wherequbeService(self, didFailToConnect: Whereqube(name:whereqube.name,uuid:whereqube.identifier.uuidString))
        }
    }
    
    func wqsmartservice(_ wqSmartService: WQSmartService, didDisconnect whereqube: CBPeripheral) {
        switch (state) {
        case .connecting, .reconnecting:
            state = .idle
            delegate?.wherequbeService(self, didFailToConnect: Whereqube(name: whereqube.name, uuid: whereqube.identifier.uuidString))
            return
        case .disconnecting:
            state = .disconnected
            state = .idle
        case .connected:
            if autoReconnect {
                state = .reconnecting
                wqSmartService.reconnect()
            } else {
                state = .disconnected
                state = .idle
            }
            
        default:
            state = .disconnected
            state = .idle
        }
        delegate?.wherequbeService(self, didDisconnect: Whereqube(name: whereqube.name, uuid: whereqube.identifier.uuidString))
    }
    
    func wqsmartservice(_ wqSmartService: WQSmartService, didDiscoverServices whereqube: CBPeripheral){
        if(hasSupportVersionTwo())
        {
            sendAppIdentification();
        }
        else {
            setTXNotification(withEnable: true)
        }
    }
    func wqsmartservice(_ wqSmartService: WQSmartService, didReceiveCharacters message: String) {
        if debug {
            print("Raw message: \(message)")
        }
       // messageService.handle(received: message)
    }
    
    func wqsmartservice(_ wqSmartService: WQSmartService, didReceiveGeoData geoResponse:GeoResponse){
        delegate?.wherequbeService(self, didReceive: geoResponse)
    }
    func wqsmartservice(_ wqSmartService: WQSmartService, didReceiveResponse  baseResponse:BaseResponse){
        guard baseResponse.messageId == nil else {
            return
        }
        delegate?.wherequbeService(self, didReceive: baseResponse)
    }
    func wqsmartservice(_ wqSmartService: WQSmartService, didWriteRequest requestId: ReqType, error: Error?){
        guard error == nil else {
            return
        }
        if requestId == ReqType.WRITE_APP_IDENTIFIER {
            setTXNotification(withEnable: true)
        }
        else
        {
            delegate?.wherequbeService(self, didReceive: BaseResponse(requestId: requestId, withError: error))
        }
    }
    func wqsmartservice(_ wqSmartService: WQSmartService, bluetoothStateChanged poweredOn: Bool) {
        bluetoothOn = poweredOn
        if poweredOn && autoReconnect && state == .reconnecting {
            wqSmartService.reconnect()
        }
        delegate?.wherequbeService(self, bluetoothChangedState: poweredOn)
    }
}

