//
//  ViewController-Gimbal.swift
//  VideoCamera
//
//  Created by jimmy on 2019/4/24.
//  Copyright © 2019 huangsj. All rights reserved.
//

import Foundation

extension ViewController : DJISDKManagerDelegate, DJIAppActivationManagerDelegate, DJIHandheldControllerDelegate{
    
    private struct AssociateKeys {
        static var osmoMobileProductKey = "osmoMobileProductKey"
        static var osmoMobileAvailableProductsKey = "osmoMobileAvailableProductsKey"
    }
    
    /*! stored the osmo mobile product if it is connected */
    @objc var osmoMobileProduct: CBPeripheral? {
        get {
            guard let property = objc_getAssociatedObject(self, &AssociateKeys.osmoMobileProductKey) as! CBPeripheral? else {
                return nil
            }
            
            return property
        }
        set {
            self.willChangeValue(for: \.osmoMobileProduct)
            objc_setAssociatedObject(self, &AssociateKeys.osmoMobileProductKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            self.didChangeValue(for: \.osmoMobileProduct)
        }
    }
    
    @objc var osmoMobileAvailableProducts: [CBPeripheral] {
        get {
            guard let property = objc_getAssociatedObject(self, &AssociateKeys.osmoMobileAvailableProductsKey) as! [CBPeripheral]? else {
                return []
            }
            
            return property
        }
        set {
            self.willChangeValue(for: \.osmoMobileAvailableProducts)
            objc_setAssociatedObject(self, &AssociateKeys.osmoMobileAvailableProductsKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            self.didChangeValue(for: \.osmoMobileAvailableProducts)
        }
    }
    
    func searchAndConnectOsmoMobileProducts(_ showSelectSheet: Bool = true){
        struct SearchOsmoStatic {
            static var searchStarted:Bool = false
        }
        if SearchOsmoStatic.searchStarted == false {
            if showSelectSheet {
                SVProgressHUD.show()
            }
            else {
                SearchOsmoStatic.searchStarted = true
            }
            OsmoMobileExternalHandheldController.shared.searchBluetooth(completion: { (products, error) in
                if let _ = error {
                    if showSelectSheet {
                        SVProgressHUD.showError(withStatus: error?.localizedDescription)
                        SVProgressHUD.dismiss(withDelay: TimeInterval(1000))
                    }
                }
                else {
                    self.osmoMobileAvailableProducts = products!
                    if showSelectSheet {
                        DispatchQueue.main.async {
                            if SearchOsmoStatic.searchStarted == false {
                                SearchOsmoStatic.searchStarted = true
                                self.searchAndConnectOsmoMobileProducts()
                            }
                        }
                    }
                }
            })
            return
        }
        
        if showSelectSheet == false {
            return
        }
        
        DispatchQueue.main.async {
            SVProgressHUD.dismiss()
            let actionSheet = UIAlertController(title: "", message: NSLocalizedString("Choose Gimbal", comment: ""), preferredStyle: .actionSheet)
            self.osmoMobileAvailableProducts.forEach({ (product) in
                let action = UIAlertAction(title: product.name, style: .default, handler: { (action) in
                    guard let bluetoothConnector = OsmoMobileExternalHandheldController.shared.bluetoothConnector else {
                        SVProgressHUD.showError(withStatus: NSLocalizedString("Cannot connect to gimbal", comment: ""))
                        SVProgressHUD.dismiss(withDelay: TimeInterval(1000))
                        return
                    }
                    
                    bluetoothConnector.connectProduct(product, withCompletion: { (error) in
                        
                        DispatchQueue.main.async {
                            if error != nil {
                                SVProgressHUD.showError(withStatus: error?.localizedDescription)
                                SVProgressHUD.dismiss(withDelay: TimeInterval(1000))
                            }
                            else{
                                self.osmoMobileProduct = product
                                
                                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(300)) {
                                    
                                    guard let handheld = OsmoMobileExternalHandheldController.shared.handheldController else {
                                        return
                                    }
                                    
                                    handheld.delegate = self
                                }
                            }
                        }
                        
                    })
                })
                actionSheet.addAction(action)
            })
            
            let action = UIAlertAction.init(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { (action) in
                
            })
            actionSheet.addAction(action)
            
            if OsmoMobileExternalHandheldController.shared.isBluetoothProductConnected {
                let current: String = {
                    guard let product = self.osmoMobileProduct else {
                        return ""
                    }
                    return product.name!
                }()
                
                let format = NSLocalizedString("Disconnect %@", comment: "")
                let action = UIAlertAction.init(title: String(format: format, current), style: .destructive, handler: { (action) in
                    guard let bluetoothConnector = OsmoMobileExternalHandheldController.shared.bluetoothConnector else {
                        return
                    }
                    bluetoothConnector.disconnectProduct(completion: nil)
                    DispatchQueue.main.async {
                        self.osmoMobileProduct = nil
                    }
                })
                actionSheet.addAction(action)
            }
            
            self.present(actionSheet, animated: true, completion: nil)
        }
    }
    
    func reconnectOsmoMobile() -> Bool{
        guard let bluetoothConnector = OsmoMobileExternalHandheldController.shared.bluetoothConnector else {

            return false
        }
        
        guard let product = self.osmoMobileProduct else {
            return false
        }
        
        bluetoothConnector.connectProduct(product, withCompletion: { (error) in
            
            DispatchQueue.main.async {
                if error != nil {
                    SVProgressHUD.showError(withStatus: error?.localizedDescription)
                    SVProgressHUD.dismiss(withDelay: TimeInterval(1000))
                }
                else{
                    self.osmoMobileProduct = product
                    
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(300)) {
                        
                        guard let handheld = OsmoMobileExternalHandheldController.shared.handheldController else {
                            return
                        }
                        
                        handheld.delegate = self
                    }
                }
            }
            
        })
        return true
    }
    
    ////////////////////////////////////
    //DJISDKManagerDelegate
    func appRegisteredWithError(_ error: Error?) {
        if error == nil {
            DJISDKManager.appActivationManager().delegate = self
            DJISDKManager.startConnectionToProduct()
        }
        
    }
    
    //////////////////////////////////
    //DJIAppActivationManagerDelegate
    func productConnected(_ product: DJIBaseProduct?) {
        guard let handheld = OsmoMobileExternalHandheldController.shared.handheldController else {
            return
        }
        
        if handheld.delegate != nil {
            handheld.delegate = nil
        }
        handheld.delegate = self
    }
    
    func productDisconnected() {
        
    }
    
    //////////////////////////
    //DJIHandheldControllerDelegate
    func handheldController(_ controller: DJIHandheldController, didUpdate state: DJIHandheldControllerHardwareState) {
        
        switch state.recordAndShutterButtons {
        case .recordClick:
            print("recordClick")
            break
        case .shutterClick:
            print("shutterClick")
            self.recordTapped(self.cameraBottom.recordButton)
            break
        case .shutterLongClick:
            break
        default:
            break
        }
        
        switch state.modeButton {
        case .tripleClick:
            
            if self.camera.isRecording {
                break;
            }
            
            guard let device = self.camera.videoDeviceInput?.device else {
                break
            }
            switch device.position {
            case .back:
                let newDevice = self.camera.devices.first { (device) -> Bool in
                    return device.position == .front && device.deviceType != .builtInTrueDepthCamera
                }
                guard let _ = newDevice else {
                    break
                }
                self.camera.changeCamera(to: newDevice!)
                break
            case .front, .unspecified:
                let newDevices = self.camera.devices.filter { (device) -> Bool in
                    return device.position == .back
                }
                
                if newDevices.count == 0 {
                    break
                }
                if let dualCam = newDevices.first(where:  { (device) -> Bool in
                    return device.deviceType == .builtInDualCamera
                }){
                    self.camera.changeCamera(to: dualCam)
                }
                else if let dualCam = newDevices.first(where:  { (device) -> Bool in
                    return device.deviceType == .builtInWideAngleCamera
                }){
                    self.camera.changeCamera(to: dualCam)
                }
                else if let backCam = newDevices.first{
                    self.camera.changeCamera(to: backCam)
                }
                
                break
            default:
                break
            }
            break
        case .doubleClick:
            break
        default:
            break
        }
        
        guard let device = self.camera.videoDeviceInput?.device else {
            return
        }
        
        let (zoomFactorMin, zoomFactorMax) = self.camera.zoomFactorRange
        do {
            
            switch state.zoomSlider {
            case .zoomIn:
                try device.lockForConfiguration()
                device.ramp(toVideoZoomFactor: CGFloat(zoomFactorMax), withRate: 1)
                device.unlockForConfiguration()
                break
            case .zoomOut:
                try device.lockForConfiguration()
                device.ramp(toVideoZoomFactor: CGFloat(zoomFactorMin), withRate: 1)
                device.unlockForConfiguration()
                break
            default:
                if device.isRampingVideoZoom {
                    device.cancelVideoZoomRamp()
                    device.unlockForConfiguration()
                }
                break
            }
        }catch {
            print("\(error)")
        }
    }
}
