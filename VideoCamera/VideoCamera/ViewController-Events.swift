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

extension ViewController : CRRulerControlDataSource {
    
    func string(forMark numberMark: NSNumber!) -> String? {
        switch currentSelectedParameterIndex {
        case 0:
            //Exposure
            return nil
        case 1:
            //Shutter
            let exposureTimeIndex = min(numberMark.intValue, 23)
            if exposureTimeIndex < 0 || exposureTimeIndex >= shutterSpeed.count {
                return nil
            }
            
            let speed = shutterSpeed[exposureTimeIndex]
            if speed == 25 ||
                speed == 60 ||
                speed == 125 ||
                speed == 250 ||
                speed == 500 ||
                speed == 800 ||
                speed == 1600 ||
                speed == 2500 ||
                speed == 5000 ||
                speed == 8000 {
                return "\(shutterSpeed[exposureTimeIndex])"
            }
            else {
                return ""
            }
        case 2:
            //ISO
            break
        case 3:
            //WB
            break
        case 4:
            //Focus
            break
        case 5:
            //Zoom
            break
        default:
            break
        }
        return nil
    }
    
    
    @objc func cameraRollTapped(_ sender : Any){
//        let documentPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
//        let documentPath = documentPaths[0]
        
//        let fileBrowser = FileBrowser(initialPath: URL(fileURLWithPath: documentPath), allowEditing: true)
        let videoLibraryBrowser = self.storyboard!.instantiateViewController(withIdentifier: "VideoLibrary")
        let fileBrowser = UINavigationController(rootViewController: videoLibraryBrowser)
        
        present(fileBrowser, animated: true, completion: nil)
    }
    
    @objc func recordTapped(_ sender : Any){
        
        self.cameraBottom.recordButton.isEnabled = false
        
        let camera = CameraManager.shared
        
        if(camera.isRecording){
            camera.stopRecording()
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(2000)){
                self.cameraBottom.recordButton.isEnabled = true
            }
            return
        }
        
        let documentPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentPath = documentPaths[0]
        camera.recordVideo(at: documentPath)
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(2000)){
            self.cameraBottom.recordButton.isEnabled = true
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
    
    func currentCameraLocalizedName() -> String {
        let (currentPosition, currentDevice) = camera.currentCamera
        let currentPositionDesc = currentPosition == .back ?NSLocalizedString("Back", comment: ""):NSLocalizedString("Front", comment: "")
        let currentDeviceName = NSLocalizedString(deviceName(of: currentDevice), comment: "")
        
        let currentCamera = "\(currentPositionDesc) \(currentDeviceName)"
        
        return currentCamera
    }
    
    @objc func changeCameraTapped(_ sender : Any){
    
        let changeCameraButton = sender as! UIButton
        
        let camera = CameraManager.shared
        
        let (currentPosition, currentDevice) = camera.currentCamera
        let currentPositionDesc = currentPosition == .back ?NSLocalizedString("Back", comment: ""):NSLocalizedString("Front", comment: "")
        let currentDeviceName = NSLocalizedString(deviceName(of: currentDevice), comment: "")
        
        let currentCamera = "\(currentPositionDesc) \(currentDeviceName)"
        
        let currentLabel = NSLocalizedString("Current Camera:", comment: "")
        let actionSheet = UIAlertController(title: "", message: "\(currentLabel)\(currentCamera)", preferredStyle: .actionSheet)
        
        camera.devices.sorted(by: { (device1, device2) -> Bool in
            if device1.position == .back {
                return true
            }
            if device2.position == .back {
                return false
            }
            if device1.deviceType == .builtInDualCamera {
                return true
            }
            if device1.deviceType == .builtInWideAngleCamera {
                return true
            }
            return false
        }).forEach { (device) in
            let position = device.position
            let type = device.deviceType
            
            let positionDesc = position == .back ?NSLocalizedString("Back", comment: ""):NSLocalizedString("Front", comment: "")
            let deviceName = self.deviceName(of: type)
            
            let action = UIAlertAction(title: "\(positionDesc) \(deviceName)", style: .default, handler: { (action) in
                
                changeCameraButton.isEnabled = false
                SVProgressHUD.show()
                
                self.sessionQueue.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(50)) {
                    
                    let currentVideoDevice = camera.videoDeviceInput.device
                    
                    camera.changeCamera(to: device)
                    
                    self.updateSettingsButton()
                    self.cameraBottom.reload()
                    
                    if let device = camera.videoDeviceInput?.device {
                        NotificationCenter.default.removeObserver(self, name: .AVCaptureDeviceSubjectAreaDidChange, object: currentVideoDevice)
                        NotificationCenter.default.addObserver(self, selector: #selector(self.subjectAreaDidChange), name: .AVCaptureDeviceSubjectAreaDidChange, object: device)
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(300)) {
                        self.parameterRuler.isHidden = true
                        self.whiteBalanceSettingsView.isHidden = true
                        self.currentSelectedParameterIndex = -1
                        changeCameraButton.isEnabled = true
                        SVProgressHUD.dismiss()
                    }
                    
                }
            })
            actionSheet.addAction(action)
            
        }
        
        let action = UIAlertAction.init(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { (action) in
            
        })
        actionSheet.addAction(action)
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    @objc func focusTap(_ gestureRecognizer: UITapGestureRecognizer) {
        
        let tapPoint = gestureRecognizer.location(in: gestureRecognizer.view)
        let devicePoint = previewView.videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: tapPoint)
        camera.focusPointOfInterest = devicePoint
        camera.exposurePointOfInterest = devicePoint
        
    }
    
    @objc func showSettingsView(_ sender:Any){
        self.formatSettingsView.loadSettingsFromCamera()
        UIView.animate(withDuration: 0.3) {
            self.settingsContainerView.isHidden = false
        }
    }
    
    @objc func hideSettingsView(_ sender:Any){
        UIView.animate(withDuration: 0.3) {
            self.settingsContainerView.isHidden = true
            self.formatSettingsView.saveSettingsToCamera()
            
            self.updateSettingsButton()
        }
    }
    
    @objc func flashButtonTap(_ sender:Any) {
        switch self.camera.torchMode {
        case .auto:
            self.camera.torchMode = .on
            break
        case .off:
            self.camera.torchMode = .auto
            break
        case .on:
            self.camera.torchMode = .off
            break
        default:
            self.camera.torchMode = .auto
            break
        }
    }
    
    func videoStablizationModeDescription(_ mode:AVCaptureVideoStabilizationMode) -> String {
        var lensTitle: String?
        switch mode {
        case .auto:
            lensTitle = NSLocalizedString("Auto", comment: "")
            break
        case .standard:
            lensTitle = NSLocalizedString("Standard", comment: "")
            break
        case .cinematic:
            lensTitle = NSLocalizedString("Cinematic", comment: "")
            break
        case .off:
            lensTitle = NSLocalizedString("Off", comment: "")
            break
        default:
            lensTitle = NSLocalizedString("Off", comment: "")
            break
        }
        return lensTitle!
    }
    
    @objc func lensButtonTap(_ sender:Any) {
        self.lensButton.isEnabled = false
        SVProgressHUD.show()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(50)) {
            switch self.camera.preferredVideoStabilizationMode {
            case .auto:
                self.camera.preferredVideoStabilizationMode = .standard
                break
            case .off:
                self.camera.preferredVideoStabilizationMode = .auto
                break
            case .standard:
                self.camera.preferredVideoStabilizationMode = .cinematic
                break
            case .cinematic:
                self.camera.preferredVideoStabilizationMode = .off
                break
            default:
                self.camera.preferredVideoStabilizationMode = .auto
                break
            }
            
            SVProgressHUD.showInfo(withStatus: self.videoStablizationModeDescription(self.camera.preferredVideoStabilizationMode));
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(300)) {
                self.lensButton.isEnabled = true
                SVProgressHUD.dismiss()
            }
        }
    }
    
    func toggleFocusLock(){
        let button = self.cameraParameterButtons[4]
        
        if button.parameterLocked {
            button.parameterLocked = false
            camera.focusMode = .continuousAutoFocus
        }
        else {
            button.parameterLocked = true
            if camera.isLockingFocusWithCustomLensPositionSupported {
                camera.setFocusModeLocked(lensPosition: AVCaptureDevice.currentLensPosition)
            }
            else {
                camera.setFocusModeLocked(lensPosition: AVCaptureDevice.currentLensPosition)
            }
        }
    }
    
    /*
     rulerMark 0 means 8000, last one 25
     */
    func rulerMark2ShutterSpeed(rulerMark: Float) -> Int{
        let markFloor = Int(floor(rulerMark))
        let markCeil = Int(ceil(rulerMark))
        if markCeil == markFloor {
            return shutterSpeed[markFloor]
        }
        
        //shutter speed between markFloor and markCeil
        
        let diff1 = shutterSpeed[markFloor] - shutterSpeed[markCeil]
        let diff2 = Int(Float(diff1)*( (rulerMark - Float(markFloor)) / Float(markCeil - markFloor)))
        let speed = shutterSpeed[markFloor] - diff2
        
        return speed
    }
    
    func shutterSpeed2RulerMark(speed: Int) -> Float {
        if  speed >= shutterSpeed[0] {
            return 0.0
        }
        
        if  speed <= shutterSpeed[shutterSpeed.count - 1] {
            return Float(shutterSpeed.count - 1)
        }
        
        for i in 1...(shutterSpeed.count - 1){
            if speed == shutterSpeed[i]{
                return Float(i)
            }
            if speed >= shutterSpeed[i] && speed <= shutterSpeed[i-1] {
                return Float(i) - Float(speed - shutterSpeed[i])/Float(shutterSpeed[i-1]-shutterSpeed[i])
            }
        }
        
        return 0.0
    }
    
    func shutterSpeed2Duration(speed: Int) -> Float {
        if  speed > shutterSpeed[0] {
            return 1.0 / Float(shutterSpeed[0])
        }
        
        if  speed < shutterSpeed[shutterSpeed.count - 1] {
            return 1.0 / Float(shutterSpeed[shutterSpeed.count - 1])
        }
        
        return 1.0 / Float(speed)
    }
    
    @objc func parameterButtonTapped(_ sender:Any) {
        let button = sender as! CameraParameterButton
        
        self.whiteBalanceSettingsView.isHidden = true
        func unselectParameter(_ i:Int) {
            if(i >= 0 && i <= 5) {
                self.cameraParameterButtons[i].parameterSelected = false
            }
        }
        
        func selectParameter(_ selectedIndex:Int){
            
            let oldSelectedIndex = currentSelectedParameterIndex
            
            if currentSelectedParameterIndex != selectedIndex && selectedIndex >= 0 && selectedIndex <= 5 {
                
                currentSelectedParameterIndex = selectedIndex
                unselectParameter(oldSelectedIndex)
                let button = self.cameraParameterButtons[selectedIndex]
                button.parameterSelected = true
            }
            else{
                currentSelectedParameterIndex = -1
                unselectParameter(oldSelectedIndex)
            }
        }
        
        self.parameterRuler.isHidden = true
        
        self.parameterRuler.tintColor = UIColor(red: 0xff/255.0, green: 0x3b/255.0, blue: 0x30/255.0, alpha: 1.0)
        self.parameterRuler.setTextColor(.white, for: .all)
        self.parameterRuler.setColor(.white, for: .all)
        
        if button == self.cameraParameterButtons[0] {
            //Exposure
            let selectedIndex = 0
            selectParameter(selectedIndex)
            
            if currentSelectedParameterIndex == 0 {
                self.parameterRuler.rangeFrom = CGFloat(camera.minExposureTargetBias)
                self.parameterRuler.rangeLength = CGFloat(camera.maxExposureTargetBias - camera.minExposureTargetBias)
                self.parameterRuler.value = CGFloat(camera.exposureTargetBias)
                self.parameterRuler.setFrequency(1, for: .minor)
                self.parameterRuler.isHidden = false
            }
            else{
                self.parameterRuler.isHidden = true
            }
        }
        else if button == self.cameraParameterButtons[1] {
            //Shutter
            let selectedIndex = 1
            selectParameter(selectedIndex)
            
            if currentSelectedParameterIndex == 1 {
                
                let exposureTimeMin = Float(camera.minExposureDuration.value)/Float(camera.minExposureDuration.timescale)
                let exposureTime = Float(camera.exposureDuration.value)/Float(camera.exposureDuration.timescale)
                
                if !exposureTimeMin.isNaN && !exposureTime.isNaN && camera.isExposureModeSupported(.custom) {
                    self.parameterRuler.rangeFrom = 0
                    self.parameterRuler.rangeLength = CGFloat(shutterSpeed.count-1)
                    self.parameterRuler.value = CGFloat(shutterSpeed2RulerMark(speed: Int(round(1/exposureTime))))
                    self.parameterRuler.setFrequency(1, for: .minor)
                    self.parameterRuler.value = 1
                    self.parameterRuler.isHidden = false
                }
                else{
                    self.parameterRuler.isHidden = true
                }
                
                if !camera.isExposureModeSupported(.custom){
                    selectParameter(-1)
                    let deviceCapabilityDesc = NSLocalizedString("Manual shutter is not available in dual lens mode.", comment: "")
                    SVProgressHUD.showInfo(withStatus: "\(deviceCapabilityDesc)")
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(2000)) {
                        SVProgressHUD.dismiss()
                    }
                }
                
            }
            else{
                self.parameterRuler.isHidden = true
            }
        }
        else if button == self.cameraParameterButtons[2] {
            //ISO
            let selectedIndex = 2
            selectParameter(selectedIndex)
            
            if currentSelectedParameterIndex == 2 {
                if let format = camera.videoDeviceInput?.device.activeFormat {
                    if camera.isExposureModeSupported(.custom) {
                        self.parameterRuler.rangeFrom = CGFloat(format.minISO)
                        self.parameterRuler.rangeLength = CGFloat(format.maxISO - format.minISO)
                        self.parameterRuler.setFrequency(self.parameterRuler.rangeLength/10, for: .minor)
                        self.parameterRuler.value = CGFloat(camera.currentISO)
                        self.parameterRuler.isHidden = false
                    }
                    else{
                        selectParameter(-1)
                        self.parameterRuler.isHidden = true
                        if !camera.isExposureModeSupported(.custom){
                            let deviceCapabilityDesc = NSLocalizedString("Manual ISO is not available in dual lens mode.", comment: "")
                            SVProgressHUD.showInfo(withStatus: "\(deviceCapabilityDesc)")
                            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(2000)) {
                                SVProgressHUD.dismiss()
                            }
                        }
                    }
                }
                else{
                    self.parameterRuler.isHidden = true
                }
                
            }
            else{
                self.parameterRuler.isHidden = true
            }
        }
        else if button == self.cameraParameterButtons[3] {
            //White Balance
            let selectedIndex = 3
            
            if currentSelectedParameterIndex == 3 {
                currentSelectedParameterIndex = -1
                self.whiteBalanceSettingsView.isHidden = true
                self.parameterRuler.isHidden = true
            }
            else {
                self.parameterRuler.isHidden = true
                selectParameter(selectedIndex)
                self.parameterRuler.isHidden = self.currentSelectedParameterIndex != 3
                self.whiteBalanceSettingsView.isHidden = self.currentSelectedParameterIndex != 3
                
                self.parameterRuler.rangeFrom = 3000
                self.parameterRuler.rangeLength = 6000
                self.parameterRuler.setFrequency(self.parameterRuler.rangeLength/10, for: .minor)
                self.parameterRuler.value = CGFloat(self.camera.temperatureAndTintValue.temperature)
                self.parameterRuler.isHidden = false
            }
            
        }
        else if button == self.cameraParameterButtons[4] {
            //Focus
            let selectedIndex = 4
            
            if camera.isLockingFocusWithCustomLensPositionSupported {
                
                selectParameter(selectedIndex)
                
                if currentSelectedParameterIndex == 4 {
                    self.parameterRuler.rangeFrom = 0
                    self.parameterRuler.rangeLength = 1
                    self.parameterRuler.value = CGFloat(camera.lensPosition)
                    self.parameterRuler.setFrequency(0.1, for: .minor)
                    self.parameterRuler.isHidden = false
                }
                else{
                    self.parameterRuler.isHidden = true
                }
            }
            else {
                selectParameter(-1)//custom focus mode not supported
                self.parameterRuler.isHidden = true
                /*if button.parameterLocked {
                    camera.focusMode = .continuousAutoFocus
                }
                else {
                    camera.setFocusModeLocked(lensPosition: AVCaptureDevice.currentLensPosition)
                }*/
                if !camera.isExposureModeSupported(.custom){
                    let deviceCapabilityDesc = NSLocalizedString("Manual focus is not available in dual lens mode.", comment: "")
                    SVProgressHUD.showInfo(withStatus: "\(deviceCapabilityDesc)")
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(2000)) {
                        SVProgressHUD.dismiss()
                    }
                }
            }
        }
        else if button == self.cameraParameterButtons[5] {
            //Zoom
            let selectedIndex = 5
           selectParameter(selectedIndex)
            
            let (zoomMin, zoomMax) = camera.zoomFactorRange
            if currentSelectedParameterIndex == 5 {
                self.parameterRuler.rangeFrom = CGFloat(zoomMin)
                self.parameterRuler.rangeLength = CGFloat(min(zoomMax, 10 ) - zoomMin)
                self.parameterRuler.value = CGFloat(camera.zoomFactor)
                self.parameterRuler.setFrequency(1, for: .minor)
                self.parameterRuler.isHidden = false
            }
            else{
                self.parameterRuler.isHidden = true
            }
        }
    }
    
    @objc func cameraParameterChanged(_ sender:Any) {
        let value:Float = {
            var value = self.parameterRuler.value
        
            if value < self.parameterRuler.rangeFrom {
                value = self.parameterRuler.rangeFrom
            }
            else if value > self.parameterRuler.rangeFrom + self.parameterRuler.rangeLength {
                value = self.parameterRuler.rangeFrom + self.parameterRuler.rangeLength
            }
            
            return Float(value)
        }()
        
        self.whiteBalanceSettingsView.isHidden = true
        
        switch currentSelectedParameterIndex {
        case 0:
            //Exposure
            camera.exposureMode = .continuousAutoExposure
            camera.exposureTargetBias = value
            break
        case 1:
            //Shutter
            let speed = rulerMark2ShutterSpeed(rulerMark: value)
            let exposureDuration = CMTime(value: 1, timescale: CMTimeScale(speed), flags: .valid, epoch: 0)
            camera.setExposureModeCustom(duration: exposureDuration, iso: camera.iso)
//            let newExpDuration = camera.exposureDuration
//            self.cameraParameterButtons[1].text1 = "1/\(Int64(newExpDuration.timescale)/newExpDuration.value)"
            break
        case 2:
            //ISO
            camera.setExposureModeCustom(duration: camera.exposureDuration, iso: value)
            break
        case 3:
            //WB
            self.whiteBalanceSettingsView.whiteBalanceMode = self.camera.desiredWhiteBalanceMode
            self.whiteBalanceSettingsView.isHidden = false
            if self.camera.isLockingWhiteBalanceWithCustomDeviceGainsSupported {

                let tempAndTint = self.camera.temperatureAndTintValue
                let temp = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues.init(temperature: value, tint: tempAndTint.tint)
                self.camera.setWhiteBalanceModeLocked(with: temp)
            }
            else {
                SVProgressHUD.showInfo(withStatus: NSLocalizedString("Manual white balance is not available in dual lens mode.", comment: ""))
                SVProgressHUD.dismiss(withDelay: TimeInterval(1000))
            }
            break
        case 4:
            //Focus
            camera.setFocusModeLocked(lensPosition: value)
            break
        case 5:
            //Zoom
            camera.zoomFactor = value
            break
        default:
            break
        }
        
        DispatchQueue.main.async {
            self.updateCameraParameterDisplay(false)
        }
    }
    
    @objc func whiteBalanceChanged() {
        if self.camera.isLockingWhiteBalanceWithCustomDeviceGainsSupported == false && self.whiteBalanceSettingsView.whiteBalanceMode != .auto {
            SVProgressHUD.showInfo(withStatus: NSLocalizedString("Manual white balance is not available in dual lens mode.", comment: ""))
            SVProgressHUD.dismiss(withDelay: TimeInterval(1000))
            self.whiteBalanceSettingsView.whiteBalanceMode = .auto
            return
        }
        self.camera.desiredWhiteBalanceMode = self.whiteBalanceSettingsView.whiteBalanceMode
    }
    
    @objc func subjectAreaDidChange(notification: NSNotification) {
        let centerFocusPoint = CGPoint(x: 0.5, y: 0.5)
        
        let camera = self.camera
        
        if camera.exposureMode == .custom || camera.exposureMode == .locked {
            return
        }
        
        if camera.focusMode == .locked {
            return
        }
        
        camera.focusPointOfInterest = centerFocusPoint
        camera.exposurePointOfInterest = centerFocusPoint
        
    }
    
    @objc func onTimerEvent(timer: Timer) {
        self.updateCameraParameterDisplay(true)
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
