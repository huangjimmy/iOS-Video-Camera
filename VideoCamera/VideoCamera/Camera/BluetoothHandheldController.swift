//
//  BluetoothHandheldController.swift
//  VideoCamera
//
//  Created by jimmy on 2019/4/23.
//  Copyright © 2019 huangsj. All rights reserved.
//

import UIKit

/*!
 Support DJI Osmo Mobile and Osmo Mobile 2 gimbal
 */
class OsmoMobileExternalHandheldController:NSObject, DJIBluetoothProductConnectorDelegate {
    
    class var shared : OsmoMobileExternalHandheldController {
        struct Singleton {
            static let controller = OsmoMobileExternalHandheldController()
        }
        return Singleton.controller;
    }
    
    override init() {
        
    }
    
    var bluetoothProducts:[CBPeripheral] = []
    
    var bluetoothConnector: DJIBluetoothProductConnector? {
        get {
            return DJISDKManager.bluetoothProductConnector()
        }
    }
    
    /*! if either osmo mobile or osmo mobile 2 is connected, this property will be true, false otherwise */
    var isBluetoothProductConnected: Bool {
        get {
            guard let product = DJISDKManager.product() else {
                return false
            }
            guard let model = product.model else {
                return false
            }
            
            if model == DJIHandheldModelNameOsmoMobile || model == DJIHandheldModelNameOsmoMobile2 {
                return true
            }
            
            return false
        }
    }
    
    func searchBluetooth(completion: ((_ products:[CBPeripheral]?, _ error:Error?) -> Void)?){
        guard let bluetoothConnector = self.bluetoothConnector else {
            return
        }
        
        bluetoothConnector.delegate = self
        bluetoothConnector.searchBluetoothProducts { (error) in
            if let block = completion {
                block(self.bluetoothProducts, error)
            }
        }
    }
    
    /////////////////////////////////////////////
    // protocol DJIBluetoothProductConnectorDelegate
    
    func connectorDidFindProducts(_ peripherals: [CBPeripheral]?) {
        if let products = peripherals {
            self.bluetoothProducts = products
        }
    }
    
    func connectHandheldController(_ product:CBPeripheral!, completion: @escaping DJICompletionBlock){
        self.bluetoothConnector?.connectProduct(product, withCompletion: completion)
    }
    
    func disconnectHandheldController(_ product:CBPeripheral!, completion: @escaping DJICompletionBlock){
        self.bluetoothConnector?.disconnectProduct(completion: completion)
    }
    
    var handheldController: DJIHandheldController? {
        get {
            if let product = DJISDKManager.product() {
                if product.isKind(of: DJIHandheld.self){
                    let handheld = (product as! DJIHandheld)
                    return handheld.handheldController
                }
            }
            return nil
        }
    }
    
}
