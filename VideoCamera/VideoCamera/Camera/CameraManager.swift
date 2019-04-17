//
//  AVRecorder.swift
//  CameraManager
//
//  Created by jimmy on 2019/4/10.
//  Copyright © 2019 huangsj. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import Photos


@objc class CameraManager : NSObject,AVCaptureFileOutputRecordingDelegate{
    
    class var sharedInstance : CameraManager {
        struct Singleton {
            static let camera = CameraManager()
        }
        return Singleton.camera;
    }
    
    public enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    private let session = AVCaptureSession()
    public var isSessionRunning = false
    
    public var setupResult: SessionSetupResult = .success
    
    @objc dynamic var videoDeviceInput: AVCaptureDeviceInput!
    @objc dynamic var audioDeviceInput: AVCaptureDeviceInput!
    
    private var movieFileOutput: AVCaptureMovieFileOutput?
    
    private let photoOutput = AVCapturePhotoOutput()
    
    private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera], mediaType: .video, position: .unspecified)
    
    public enum LivePhotoMode {
        case on
        case off
    }
    
    public enum DepthDataDeliveryMode {
        case on
        case off
    }
    
    public enum PortraitEffectsMatteDeliveryMode {
        case on
        case off
    }
    
    @objc public var isRecording: Bool {
        get {
            if let movieFileOutput = self.movieFileOutput {
                return movieFileOutput.isRecording
            }
            return false
        }
    }
    
    public func isExposureModeSupported(_ mode:AVCaptureDevice.ExposureMode) -> Bool {
        if let device = self.videoDeviceInput?.device {
            return device.isExposureModeSupported(mode)
        }
        return false
    }
    
    //Current selected exposure mode
    var _exposureMode:  AVCaptureDevice.ExposureMode = .autoExpose
    public var exposureMode : AVCaptureDevice.ExposureMode {
        get {
            return _exposureMode
        }
        set{
            _exposureMode = newValue
        }
    }
    
    var _exposureTargetBias : Float = 0.0
    public var exposureTargetBias : Float {
        get {
            if let device = self.videoDeviceInput?.device {
                _exposureTargetBias = device.exposureTargetBias
            }
            return _exposureTargetBias
        }
        set{
            _exposureTargetBias = newValue
            if let device = self.videoDeviceInput?.device {
                do{
                    try device.lockForConfiguration()
                    device.setExposureTargetBias(_exposureTargetBias, completionHandler: nil)
                    device.unlockForConfiguration()
                }
                catch {
                    print("Could not lock device for configuration: \(error)")
                }
            }
        }
    }
    
    public var maxExposureTargetBias : Float {
        get {
            if let device = self.videoDeviceInput?.device {
                return device.maxExposureTargetBias
            }
            return 3.0
        }
    }
    
    public var minExposureTargetBias : Float {
        get {
            if let device = self.videoDeviceInput?.device {
                return device.minExposureTargetBias
            }
            return 3.0
        }
    }
    
    public var exposureTargetOffset : Float{
        get{
            if let device = self.videoDeviceInput?.device {
                return device.exposureTargetOffset
            }
            return 0
        }
    }
    
    public func isExposurePointOfInterestSupported() -> Bool {
        if let device = self.videoDeviceInput?.device {
            return device.isExposurePointOfInterestSupported
        }
        return false
    }
    
    var _exposurePointOfInterest : CGPoint = CGPoint(x:0.5, y:0.5)
    public var exposurePointOfInterest : CGPoint {
        get {
            if let device = self.videoDeviceInput?.device {
                _exposurePointOfInterest = device.exposurePointOfInterest
            }
            return _exposurePointOfInterest;
        }
        
        set{
            if let device = self.videoDeviceInput?.device {
                if device.isExposurePointOfInterestSupported{
                    _exposurePointOfInterest = newValue
                    
                    do{
                        try device.lockForConfiguration()
                        device.exposurePointOfInterest = _exposurePointOfInterest
                        device.exposureMode = exposureMode
                        device.unlockForConfiguration()
                    }
                    catch {
                        print("Could not lock device for configuration: \(error)")
                    }
                }
            }
        }
    }
    
    //Current selected focus mode/change focus mode
    var _focusMode : AVCaptureDevice.FocusMode = .continuousAutoFocus
    public var focusMode : AVCaptureDevice.FocusMode {
        get {
            if let device = self.videoDeviceInput?.device {
                _focusMode = device.focusMode
            }
            return _focusMode
        }
        
        set {
            if let device = self.videoDeviceInput?.device {
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(newValue){
                    _focusMode = newValue
                    do{
                        try device.lockForConfiguration()
                        device.focusMode = focusMode
                        device.unlockForConfiguration()
                    }
                    catch {
                        print("Could not lock device for configuration: \(error)")
                    }
                }
            }
        }
    }
    
    var _focusPointOfInterest : CGPoint = CGPoint(x:0.5, y:0.5)
    public var focusPointOfInterest : CGPoint {
        get {
            if let device = self.videoDeviceInput?.device {
                _focusPointOfInterest = device.focusPointOfInterest
            }
            return _focusPointOfInterest;
        }
        
        set{
            if let device = self.videoDeviceInput?.device {
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode){
                    _focusPointOfInterest = newValue
                    do{
                        try device.lockForConfiguration()
                        device.focusPointOfInterest = _focusPointOfInterest
                        device.focusMode = focusMode
                        device.unlockForConfiguration()
                    }
                    catch {
                        print("Could not lock device for configuration: \(error)")
                    }
                }
            }
        }
    }
    
    var lensPosition: Float {
        get {
            if let device = self.videoDeviceInput?.device {
               return device.lensPosition
            }
            return 0.0;
        }
    }
    
    public func setFocusModeLocked(lensPosition: Float){
        if let device = self.videoDeviceInput?.device {
            do{
                try device.lockForConfiguration()
                device.setFocusModeLocked(lensPosition: lensPosition, completionHandler: nil)
                device.unlockForConfiguration()
            }
            catch {
                print("Could not lock device for configuration: \(error)")
            }
        }
    }
    
    public func isWhiteBalanceModeSupported(_ mode:AVCaptureDevice.WhiteBalanceMode) -> Bool {
        if let device = self.videoDeviceInput?.device {
            return device.isWhiteBalanceModeSupported(mode)
        }
        return false
    }
    
    public var isLockingWhiteBalanceWithCustomDeviceGainsSupported : Bool {
        get{
            if let device = self.videoDeviceInput?.device {
                return device.isLockingWhiteBalanceWithCustomDeviceGainsSupported
            }
            return false
        }
    }
    
    public var isLockingFocusWithCustomLensPositionSupported : Bool {
        get{
            if let device = self.videoDeviceInput?.device {
                return device.isLockingFocusWithCustomLensPositionSupported
            }
            return false
        }
    }
    
    var whiteBalanceMode : AVCaptureDevice.WhiteBalanceMode {
        get{
            if let device = self.videoDeviceInput?.device {
                return device.whiteBalanceMode
            }
            return .autoWhiteBalance
        }
    }
    
    public var temperatureAndTintValue : AVCaptureDevice.WhiteBalanceTemperatureAndTintValues{
        get {
            if let device = self.videoDeviceInput?.device {
                return device.temperatureAndTintValues(for: currentWhiteBalanceGains)
            }
            return AVCaptureDevice.WhiteBalanceTemperatureAndTintValues.init()
        }
    }
    
    public func setExposureModeCustom(duration: CMTime, iso: Float){
        if let device = self.videoDeviceInput?.device {
            do{
                try device.lockForConfiguration()
                device.setExposureModeCustom(duration: duration, iso: iso, completionHandler: nil)
                device.unlockForConfiguration()
            }
            catch {
                print("Could not lock device for configuration: \(error)")
            }
        }
    }
    
    public func setWhiteBalanceModeLocked(with temperatureAndTintValue:AVCaptureDevice.WhiteBalanceTemperatureAndTintValues){
        if let device = self.videoDeviceInput?.device {
            do{
                try device.lockForConfiguration()
                let whiteBalanceGains = device.deviceWhiteBalanceGains(for: temperatureAndTintValue)
                device.setWhiteBalanceModeLocked(with: whiteBalanceGains, completionHandler: nil)
                device.unlockForConfiguration()
            }
            catch {
                print("Could not lock device for configuration: \(error)")
            }
        }
    }
    
    var lensAperture : Float {
        get {
            if let device = self.videoDeviceInput?.device {
                return device.lensAperture
            }
            return 0.0
        }
    }
    
    var cameraDeviceType: AVCaptureDevice.DeviceType {
        get {
            if let device = self.videoDeviceInput?.device {
                return device.deviceType
            }
            return AVCaptureDevice.DeviceType.builtInWideAngleCamera
        }
    }
    
    var useBluetoothMicrophone : Bool {
        get {
            return session.automaticallyConfiguresApplicationAudioSession
        }
        set {
            session.usesApplicationAudioSession = true
            session.automaticallyConfiguresApplicationAudioSession = newValue
            if session.automaticallyConfiguresApplicationAudioSession == false {
                do {
                    try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord, mode: .videoRecording, options: [.allowBluetooth, .allowBluetoothA2DP])
                    try AVAudioSession.sharedInstance().setActive(true)
                } catch  {
                    print("Error messing with audio session: \(error)")
                }
            }
        }
    }
    
    var microphoneDeviceType: AVCaptureDevice.DeviceType {
        get {
            if let device = self.audioDeviceInput?.device {
                return device.deviceType
            }
            return AVCaptureDevice.DeviceType.builtInMicrophone
        }
    }
    
    var currentExposureDuration : CMTime {
        get {
            return AVCaptureDevice.currentExposureDuration
        }
    }
    
    var currentISO : Float {
        get {
            return AVCaptureDevice.currentISO
        }
    }
    
    var currentExposureTargetBias : Float {
        get {
            return AVCaptureDevice.currentExposureTargetBias
        }
    }
    
    var currentLensPosition : Float {
        get {
            return AVCaptureDevice.currentLensPosition
        }
    }
    
    var currentWhiteBalanceGains : AVCaptureDevice.WhiteBalanceGains {
        get {
            return AVCaptureDevice.currentWhiteBalanceGains
        }
    }
    
    var currentCamera : (AVCaptureDevice.Position, AVCaptureDevice.DeviceType) {
        get {
            if let device = self.videoDeviceInput?.device {
                return (device.position, device.deviceType)
            }
            return (AVCaptureDevice.Position.back, AVCaptureDevice.DeviceType.builtInWideAngleCamera)
        }
    }
    
    var devices : [AVCaptureDevice] {
        get {
            return self.videoDeviceDiscoverySession.devices
        }
    }
    
    public var livePhotoMode: LivePhotoMode = .off
    public var depthDataDeliveryMode: DepthDataDeliveryMode = .off
    public var portraitEffectsMatteDeliveryMode: PortraitEffectsMatteDeliveryMode = .off
    
    private var keyValueObservations = [NSKeyValueObservation]()
    
    // Call this on the session queue.
    /// - Tag: ConfigureSession
    public func configureSession(with previewView:PreviewView!) {
        if setupResult != .success {
            return
        }
        
        DispatchQueue.main.async {
            previewView.session = self.session
        }
        
        print("beginConfiguration()")
        session.beginConfiguration()
        
        /*
         We do not create an AVCaptureMovieFileOutput when setting up the session because
         Live Photo is not supported when AVCaptureMovieFileOutput is added to the session.
         */
        session.sessionPreset = .hd4K3840x2160
        
        // Add video input.
        do {
            var defaultVideoDevice: AVCaptureDevice?
            
            // Choose the back dual camera if available, otherwise default to a wide angle camera.
            
            if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
                defaultVideoDevice = dualCameraDevice
            } else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                // If a rear dual camera is not available, default to the rear wide angle camera.
                defaultVideoDevice = backCameraDevice
            } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                // In the event that the rear wide angle camera isn't available, default to the front wide angle camera.
                defaultVideoDevice = frontCameraDevice
            }
            guard let videoDevice = defaultVideoDevice else {
                print("Default video device is unavailable.")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
                DispatchQueue.main.async {
                    /*
                     Dispatch video streaming to the main queue because AVCaptureVideoPreviewLayer is the backing layer for PreviewView.
                     You can manipulate UIView only on the main thread.
                     Note: As an exception to the above rule, it is not necessary to serialize video orientation changes
                     on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
                     
                     Use the status bar orientation as the initial video orientation. Subsequent orientation changes are
                     handled by CameraViewController.viewWillTransition(to:with:).
                     */
                    let statusBarOrientation = UIApplication.shared.statusBarOrientation
                    var initialVideoOrientation: AVCaptureVideoOrientation = .portrait
                    if statusBarOrientation != .unknown {
                        if let videoOrientation = AVCaptureVideoOrientation(interfaceOrientation: statusBarOrientation) {
                            initialVideoOrientation = videoOrientation
                        }
                    }
                    
                    previewView.videoPreviewLayer.connection?.videoOrientation = initialVideoOrientation
                }
            } else {
                print("Couldn't add video device input to the session.")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
        } catch {
            print("Couldn't create video device input: \(error)")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        // Add audio input.
        do {
            let audioDevice = AVCaptureDevice.default(for: .audio)
            let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice!)
            
            if session.canAddInput(audioDeviceInput) {
                session.addInput(audioDeviceInput)
                self.audioDeviceInput = audioDeviceInput
            } else {
                print("Could not add audio device input to the session")
            }
        } catch {
            print("Could not create audio device input: \(error)")
        }
        
        session.usesApplicationAudioSession = true
        session.automaticallyConfiguresApplicationAudioSession = true
        
        // Add photo output.
        /*if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            
            photoOutput.isHighResolutionCaptureEnabled = true
            photoOutput.isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureSupported
            photoOutput.isDepthDataDeliveryEnabled = photoOutput.isDepthDataDeliverySupported
            photoOutput.isPortraitEffectsMatteDeliveryEnabled = photoOutput.isPortraitEffectsMatteDeliverySupported
            livePhotoMode = photoOutput.isLivePhotoCaptureSupported ? .on : .off
            depthDataDeliveryMode = photoOutput.isDepthDataDeliverySupported ? .on : .off
            portraitEffectsMatteDeliveryMode = photoOutput.isPortraitEffectsMatteDeliverySupported ? .on : .off
            
        } else {
            print("Could not add photo output to the session")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }*/
        let movieFileOutput = AVCaptureMovieFileOutput()
        
        if self.session.canAddOutput(movieFileOutput) {
            self.session.addOutput(movieFileOutput)
            self.session.sessionPreset = .hd4K3840x2160
            if let connection = movieFileOutput.connection(with: .video) {
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .auto
                }
            }
            self.movieFileOutput = movieFileOutput
            
            let keyValueObservation = movieFileOutput.observe(\.isRecording, options: .new) { (_, change) in
                self.willChangeValue(for: \.isRecording)
                
                self.didChangeValue(for: \.isRecording)
            }
            
            keyValueObservations.append(keyValueObservation)
        }
        else {
            print("Could not add movie output to the session")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        session.commitConfiguration()
        print("session.commitConfiguration()")
    }
    
    public func startRunning(){
        if self.setupResult == .success {
            print("session.startRunning()")
            self.session.startRunning()
            self.isSessionRunning = self.session.isRunning
        }
    }
    
    public func stopRunning(){
        if self.setupResult == .success {
            self.session.stopRunning()
            self.isSessionRunning = self.session.isRunning
        }
    }
    
    public func changeCamera(to device:AVCaptureDevice) {
        let currentVideoDevice = self.videoDeviceInput.device
        let currentPosition = currentVideoDevice.position
        
        if currentPosition == device.position && currentVideoDevice.deviceType == device.deviceType {
            return
        }
        
        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: device)
            
            self.session.beginConfiguration()
            
            // Remove the existing device input first, since the system doesn't support simultaneous use of the rear and front cameras.
            self.session.removeInput(self.videoDeviceInput)
            
            if let deviceFormat =
                device.formats.max (by: { (format1, format2) -> Bool in
                let dimension1 = CMVideoFormatDescriptionGetDimensions(format1.formatDescription)
                let dimension2 = CMVideoFormatDescriptionGetDimensions(format2.formatDescription)
                
                return dimension1.width*dimension1.height <= dimension2.width*dimension2.height
                }) {
                
                let dimension = CMVideoFormatDescriptionGetDimensions(deviceFormat.formatDescription)
                if dimension.width >= 3840 && dimension.height >= 2160 {
                    session.sessionPreset = .hd4K3840x2160
                }
                else if dimension.width >= 1920 && dimension.height >= 1080 {
                    session.sessionPreset = .hd1920x1080
                }
                else if dimension.width >= 1280 && dimension.height >= 720 {
                    session.sessionPreset = .hd1280x720
                }
                else if dimension.width >= 960 && dimension.height >= 540 {
                    session.sessionPreset = .iFrame960x540
                }
                else if dimension.width >= 352 && dimension.height >= 288 {
                    session.sessionPreset = .cif352x288
                }
                else{
                    session.sessionPreset = .cif352x288
                }
            }
            
            if self.session.canAddInput(videoDeviceInput) {
                
                self.session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
            } else {
                self.session.addInput(self.videoDeviceInput)
            }
            if let connection = self.movieFileOutput?.connection(with: .video) {
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .auto
                }
            }
            self.session.commitConfiguration()
        }
        catch {
            print("Error occurred while creating video device input: \(error)")
        }
    }
    
    public func recordVideo(at path:String){
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss_ZZZZZ"
        let outputFileName = dateFormatter.string(from: Date())
        let outputFilePath = (path as NSString).appendingPathComponent((outputFileName as NSString).appendingPathExtension("mov")!)
        self.movieFileOutput?.startRecording(to: URL(fileURLWithPath: outputFilePath), recordingDelegate: self)
    }
    
    public func stopRecording(){
        if isRecording {
            if let movieFileOutput = self.movieFileOutput {
                movieFileOutput.stopRecording()
            }
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        
    }
    
    deinit {
        keyValueObservations.forEach { (keyValueObservation) in
            keyValueObservation.invalidate()
        }
        keyValueObservations.removeAll()
    }
    
}

public extension AVCaptureVideoOrientation {
    init?(deviceOrientation: UIDeviceOrientation) {
        switch deviceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeRight
        case .landscapeRight: self = .landscapeLeft
        default: return nil
        }
    }
    
    init?(interfaceOrientation: UIInterfaceOrientation) {
        switch interfaceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeLeft
        case .landscapeRight: self = .landscapeRight
        default: return nil
        }
    }
}

public extension AVCaptureDevice.DiscoverySession {
    var uniqueDevicePositionsCount: Int {
        var uniqueDevicePositions: [AVCaptureDevice.Position] = []
        
        for device in devices {
            if !uniqueDevicePositions.contains(device.position) {
                uniqueDevicePositions.append(device.position)
            }
        }
        
        return uniqueDevicePositions.count
    }
}
