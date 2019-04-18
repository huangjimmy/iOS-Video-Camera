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
            return NSLocalizedString("DualCamera", comment: "")
        }
        else if deviceType == .builtInTelephotoCamera {
            return NSLocalizedString("Telephoto", comment: "")
        }
        else if deviceType == .builtInTrueDepthCamera {
            return NSLocalizedString("TrueDepth", comment: "")
        }
        else if deviceType == .builtInWideAngleCamera {
            return NSLocalizedString("WideAngle", comment: "")
        }
        
        return NSLocalizedString("Unknow", comment: "")
    }
    
    @objc func changeCameraTapped(_ sender : Any){
        
        let camera = CameraManager.sharedInstance
        
        let (currentPosition, currentDevice) = camera.currentCamera
        let currentPositionDesc = currentPosition == .back ?NSLocalizedString("Back", comment: ""):NSLocalizedString("Front", comment: "")
        let currentDeviceName = deviceName(of: currentDevice)
        
        let currentCamera = "\(currentPositionDesc) \(currentDeviceName)"
        
        let actionSheet = UIAlertController.init(title: "", message: "Current Camera:\(currentCamera)", preferredStyle: .actionSheet)
        
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
    
    @objc func focusTap(_ gestureRecognizer: UITapGestureRecognizer) {
        let devicePoint = previewView.videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: gestureRecognizer.location(in: gestureRecognizer.view))
        camera.focusPointOfInterest = devicePoint
        camera.focusMode = camera.focusMode
        //focus(with: .autoFocus, exposureMode: .autoExpose, at: devicePoint, monitorSubjectAreaChange: true)
    }
    
    
    @objc func subjectAreaDidChange(notification: NSNotification) {
        let _ = CGPoint(x: 0.5, y: 0.5)
        
    }
    
    /// - Tag: HandleRuntimeError
    @objc func sessionRuntimeError(notification: NSNotification) {
        guard let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError else { return }
        
        print("Capture session runtime error: \(error)")
        // If media services were reset, and the last start succeeded, restart the session.
        if error.code == .mediaServicesWereReset {
            sessionQueue.async {
                if self.camera.isSessionRunning {
                    self.camera.startRunning()
                } else {
                }
            }
        } else {
            
        }
        
    }
    
    /// - Tag: HandleInterruption
    @objc func sessionWasInterrupted(notification: NSNotification) {
        /*
         In some scenarios we want to enable the user to resume the session running.
         For example, if music playback is initiated via control center while
         using AVCam, then the user can let AVCam resume
         the session running, which will stop music playback. Note that stopping
         music playback in control center will not automatically resume the session
         running. Also note that it is not always possible to resume, see `resumeInterruptedSession(_:)`.
         */
        if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?,
            let reasonIntegerValue = userInfoValue.integerValue,
            let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue) {
            print("Capture session was interrupted with reason \(reason)")
            
            if reason == .audioDeviceInUseByAnotherClient || reason == .videoDeviceInUseByAnotherClient {
   
            } else if reason == .videoDeviceNotAvailableWithMultipleForegroundApps {
                // Fade-in a label to inform the user that the camera is unavailable.
                
            } else if reason == .videoDeviceNotAvailableDueToSystemPressure {
                print("Session stopped running due to shutdown system pressure level.")
            }
        }
    }
    
    @objc func sessionInterruptionEnded(notification: NSNotification) {
        print("Capture session interruption ended")
    }
}
