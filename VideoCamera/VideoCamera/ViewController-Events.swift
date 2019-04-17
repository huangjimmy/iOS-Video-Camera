//
//  ViewController-Events.swift
//  VideoCamera
//
//  Created by jimmy on 2019/4/17.
//  Copyright © 2019 huangsj. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import FileBrowser

extension ViewController {
    
    @objc func cameraRollTapped(_ sender : Any){
        let documentPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentPath = documentPaths[0]
        
        let fileBrowser = FileBrowser(initialPath: URL(fileURLWithPath: documentPath), allowEditing: true)
        present(fileBrowser, animated: true, completion: nil)
    }
    
    @objc func recordTapped(_ sender : Any){
        let camera = CameraManager.sharedInstance
        if(camera.isRecording){
            camera.stopRecording()
        }
        else{
            let documentPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
            let documentPath = documentPaths[0]
            camera.recordVideo(at: documentPath)
        }
    }
    
    func deviceName(of deviceType:AVCaptureDevice.DeviceType) -> String {
        if deviceType == .builtInDualCamera {
            return "DualCamera"
        }
        else if deviceType == .builtInTelephotoCamera {
            return "Telephoto"
        }
        else if deviceType == .builtInTrueDepthCamera {
            return "TrueDepth"
        }
        else if deviceType == .builtInWideAngleCamera {
            return "WideAngle"
        }
        
        return "Unknow"
    }
    
    @objc func changeCameraTapped(_ sender : Any){
        
        let camera = CameraManager.sharedInstance
        
        let (currentPosition, currentDevice) = camera.currentCamera
        let currentPositionDesc = currentPosition == .back ?NSLocalizedString("Back", comment: ""):NSLocalizedString("Front", comment: "")
        let currentDeviceName = deviceName(of: currentDevice)
        
        let currentCamera = "\(currentPositionDesc) \(currentDeviceName)"
        
        let actionSheet = UIAlertController.init(title: "", message: "当前摄像头:\(currentCamera)", preferredStyle: .actionSheet)
        
        camera.devices.forEach { (device) in
            let position = device.position
            let type = device.deviceType
            
            let positionDesc = position == .back ?NSLocalizedString("Back", comment: ""):NSLocalizedString("Front", comment: "")
            let deviceName = self.deviceName(of: type)
            
            let action = UIAlertAction.init(title: "\(positionDesc) \(deviceName)", style: .default, handler: { (action) in
                self.sessionQueue.async {
                    camera.changeCamera(to: device)
                }
            })
            actionSheet.addAction(action)
            
        }
        
        let action = UIAlertAction.init(title: "Cancel", style: .cancel, handler: { (action) in
            
        })
        actionSheet.addAction(action)
        
        self.present(actionSheet, animated: true, completion: nil)
    }
}
