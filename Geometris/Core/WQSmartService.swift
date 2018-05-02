//
//  WQSmartService.swift
//  Geometris
//
//  Created by Bipin Kadel on 2/15/18.
//  Copyright © 2018 geometris. All rights reserved.
//

import Foundation
import CoreBluetooth


enum WQSmartServiceError: Error {
    case characteristicNotavailable
    
    case invalidUUID
    case invalidString
    case wherequbeUnavailable
    case wherequbeNotFound
    case requestFailed
}

protocol WQSmartServiceDelegate {
    func wqsmartservice(_ wqSmartService: WQSmartService, didDiscover whereqube: CBPeripheral, didReadRSSI RSSI: NSNumber)
    func wqsmartservice(_ wqSmartService: WQSmartService, didConnect whereqube: CBPeripheral)
    func wqsmartservice(_ wqSmartService: WQSmartService, didFailToConnect whereqube: CBPeripheral)
    func wqsmartservice(_ wqSmartService: WQSmartService, didDisconnect whereqube: CBPeripheral)
    func wqsmartservice(_ wqSmartService: WQSmartService, didDiscoverServices whereqube: CBPeripheral)
    func wqsmartservice(_ wqSmartService: WQSmartService, didReceiveCharacters message: String)
    func wqsmartservice(_ wqSmartService: WQSmartService, didReceiveGeoData geoResponse:GeoResponse)
    func wqsmartservice(_ wqSmartService: WQSmartService, didReceiveResponse  baseResponse:BaseResponse)
    func wqsmartservice(_ wqSmartService: WQSmartService, didWriteRequest requestId: ReqType, error: Error?)
    func wqsmartservice(_ wqSmartService: WQSmartService, bluetoothStateChanged poweredOn: Bool)
}


class WQSmartService: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    private var centralManager: CBCentralManager!
    private var peripherals = [String: CBPeripheral]()
    private var savedCharacteristics: [String: CBCharacteristic?]
    var whereqube: CBPeripheral?
    var delegate: WQSmartServiceDelegate?
    var timeoutInterval: TimeInterval = 5
    var timeoutTimer: Timer?
    
    var obdMessage: OBDMessage
    var messageBuffer: String = ""
    var currentRequest: ReqType = .NOTHING
    struct WQSmartUUID {
        struct Service {
            static let OBDService = CBUUID(string: "1816")
        }
        
        struct Characteristics {
            
            // RX and TX characteristics
            static let OBDMeasurementCharacteristics = CBUUID(string: "2A5B")
            static let OBDDataPointCharacteristics = CBUUID(string: "2A57")
            static let OBDDeviceAddressCharacteristics = CBUUID(string: "2A59")
        }
    }
    
    // services
    private var OBDService: CBService?
    
    // characteristics
    private var OBDMeasurementCharacteristics: CBCharacteristic?
    private var OBDDataPointCharacteristics: CBCharacteristic?
    private var OBDDeviceAddressCharacteristics: CBCharacteristic?
   
    
    static let sharedInstance = WQSmartService()
    
    private override init() {
        savedCharacteristics = [String: CBCharacteristic?]()
        obdMessage = OBDMessage();
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    
    
    // MARK: - UartService Bluetooth endpoints
    
    func startScanning() {
        peripherals.removeAll()
        
        let retrievedPeripherals = centralManager.retrieveConnectedPeripherals(withServices: [WQSmartUUID.Service.OBDService])
        for peripheral in retrievedPeripherals {
            
            if peripherals[peripheral.identifier.uuidString] == nil {
                delegate?.wqsmartservice(self, didDiscover: peripheral, didReadRSSI: 0)
                peripherals[peripheral.identifier.uuidString] = peripheral
            }
        }
        
        centralManager.scanForPeripherals(withServices: [WQSmartUUID.Service.OBDService], options: nil)
    }
    
    func stopScanning() {
        if centralManager.isScanning {
            centralManager.stopScan()
        }
    }
    
    func connectTo(wqwithUUID wqUUID: String) throws {
        stopScanning() // ?
        
        guard let _ = UUID(uuidString: wqUUID) else {
            throw WQSmartServiceError.invalidUUID
        }
        
        if let peripheral = peripherals[wqUUID] {
            centralManager.connect(peripheral, options: nil)
            timeoutTimer = Timer.scheduledTimer(withTimeInterval: timeoutInterval, repeats: false, block: { (timer) in
                self.centralManager.cancelPeripheralConnection(peripheral)
            })
        } else {
            throw WQSmartServiceError.wherequbeNotFound
        }
    }
    
    func disconnect() {
        
        guard let peripheral = whereqube else {
            return
        }
        
        // disconnect the device
        peripheral.delegate = nil
        centralManager.cancelPeripheralConnection(peripheral)
        
    }
    
    func reconnect() {
        guard let peripheral = whereqube else {
            return
        }
        
        timeoutTimer?.invalidate()
        centralManager.connect(peripheral, options: nil)
    }
    
    func registerServices() throws {
        guard let peripheral = whereqube else {
            throw WQSmartServiceError.wherequbeUnavailable
        }
        
        peripheral.discoverServices([WQSmartUUID.Service.OBDService])
    }
    func isCharacteristicExists(withService service: CBUUID, withCharacteristic characteristic: CBUUID ) -> Bool{
        let key = service.uuidString+characteristic.uuidString
        let target = savedCharacteristics[key]
        if target != nil {
            print("characteristic  Exist")
            return true
        }
        print("characteristic  Not Exist")
        return false
    }
    
    func writeCharacteristicValue(withRequestId requestId: ReqType, forService service: CBUUID, forCharacteristic characteristic: CBUUID, withData data:Data) throws {
        guard let peripheral = whereqube else {
            throw WQSmartServiceError.wherequbeUnavailable
        }
        let key = service.uuidString + characteristic.uuidString
        guard let targetCharacteristic = savedCharacteristics[key] else{
            throw WQSmartServiceError.characteristicNotavailable
        }
        currentRequest = requestId
        peripheral.writeValue(data, for: targetCharacteristic!, type: CBCharacteristicWriteType.withResponse)
        
    }
    
    func requestCharacteristicNotification(withRequestId requestId: ReqType, withService service: CBUUID, withCharacteristic characteristic: CBUUID, withEnable enable: Bool)
        throws {
            guard let peripheral = whereqube else {
                throw WQSmartServiceError.wherequbeUnavailable
            }
            let key = service.uuidString + characteristic.uuidString
            guard let targetCharacteristic = savedCharacteristics[key] else{
                throw WQSmartServiceError.characteristicNotavailable
            }
            currentRequest = requestId
            peripheral.setNotifyValue(enable, for: targetCharacteristic!)
        }

    
    func readCharacteristicValue(withRequestId requestId: ReqType, withService service: CBUUID, withCharacteristic characteristic: CBUUID)
        throws {
            guard let peripheral = whereqube else {
                throw WQSmartServiceError.wherequbeUnavailable
            }
            let key = service.uuidString + characteristic.uuidString
            guard let targetCharacteristic = savedCharacteristics[key] else {
                throw WQSmartServiceError.characteristicNotavailable
            }
            currentRequest = requestId
            peripheral.readValue(for: targetCharacteristic!)
    }
    
    
    // MARK: - Bluetooth Central protocol implementation
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        delegate?.wqsmartservice(self, bluetoothStateChanged: central.state == .poweredOn)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if peripherals[peripheral.identifier.uuidString] == nil {
            delegate?.wqsmartservice(self, didDiscover: peripheral, didReadRSSI: RSSI)
            peripherals[peripheral.identifier.uuidString] = peripheral
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        timeoutTimer?.invalidate()
        delegate?.wqsmartservice(self, didFailToConnect: peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("connect")
        peripherals.removeAll()
        timeoutTimer?.invalidate()
        whereqube = peripheral
        whereqube?.delegate = self
        savedCharacteristics.removeAll()
        delegate?.wqsmartservice(self, didConnect: peripheral)
 }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("disconnected")
        delegate?.wqsmartservice(self, didDisconnect: peripheral)
    }
    
    
    // MARK: - Bluetooth peripheral protocol and register services implementation
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {
            return
        }
        
        for service in services {
            if service.uuid == WQSmartUUID.Service.OBDService {
                OBDService = service
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else {
            return
        }
        
        for characteristic in characteristics {
            let key = service.uuid.uuidString + characteristic.uuid.uuidString
            savedCharacteristics[key] = characteristic
            
            switch(characteristic.uuid) {
                case WQSmartUUID.Characteristics.OBDMeasurementCharacteristics:
                    OBDMeasurementCharacteristics = characteristic
                case WQSmartUUID.Characteristics.OBDDataPointCharacteristics:
                    OBDDataPointCharacteristics = characteristic
                case WQSmartUUID.Characteristics.OBDDeviceAddressCharacteristics:
                    OBDDeviceAddressCharacteristics = characteristic
                default: ()
            }
        }
        delegate?.wqsmartservice(self, didDiscoverServices: peripheral)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        // TODO: - check later what to do in this case
    }
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?)
    {
        guard error == nil else {
            print("Error occurred while updating characteristic value: \(error!.localizedDescription)")
            return
        }
    
        delegate?.wqsmartservice(self, didWriteRequest: currentRequest, error: error)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        
        if characteristic.uuid == WQSmartUUID.Characteristics.OBDMeasurementCharacteristics {
            guard error == nil else {
                print("Error occurred while updating characteristic value: \(error!.localizedDescription)")
                return
            }
            guard let message = characteristic.value else {
                return
            }
            
            
            obdMessage.insertMessage(withData: message)
            if obdMessage.isFull() {
                let gData: GeoData = obdMessage.getGeoData()
                let geoResponse:GeoResponse = GeoResponse(requestId: ReqType.OBD_MEASUREMENT, geoData: gData)
                delegate?.wqsmartservice(self, didReceiveGeoData: geoResponse)
                obdMessage.reset()
            }
        } else if currentRequest == ReqType.REQUEST_DEVICE_ADDRESS && characteristic.uuid == WQSmartUUID.Characteristics.OBDDeviceAddressCharacteristics {
            guard error == nil else {
                print("Error occurred while updating characteristic value: \(error!.localizedDescription)")
                delegate?.wqsmartservice(self, didReceiveResponse: BaseResponse(requestId: ReqType.REQUEST_DEVICE_ADDRESS, withError: WQSmartServiceError.requestFailed))
                return
            }
            if let message = characteristic.value?.toUInt8Array() {
                let addr = message.map { String(format: "%02x", $0) }.joined(separator: ":")
                
                let addressResponse:AddressResponse = AddressResponse(requestId: ReqType.REQUEST_DEVICE_ADDRESS, address: addr, withError: nil)
                delegate?.wqsmartservice(self, didReceiveResponse: addressResponse)
            }
            
        }
    }
}
