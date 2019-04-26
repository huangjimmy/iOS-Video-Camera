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

@objc public enum WhiteBalanceMode: Int {
    case auto
    case sunlight
    case cloudy
    case tungsten
    case shade
    case flash
    case manual
}


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
    
    internal var _currentVideOrientation:AVCaptureVideoOrientation = .portrait
    var currentVideOrientation:AVCaptureVideoOrientation {
        get{
            return _currentVideOrientation
        }
        set {
            _currentVideOrientation = newValue
        }
    }
    
    private let session = AVCaptureSession()
    
    public var isSessionRunning = false
    
    public var setupResult: SessionSetupResult = .success
    
    @objc dynamic var videoDeviceInput: AVCaptureDeviceInput!
    @objc dynamic var audioDeviceInput: AVCaptureDeviceInput!
    
    private var movieFileOutput: AVCaptureMovieFileOutput?
    
    private let photoOutput = AVCapturePhotoOutput()
    
    private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera, .builtInTelephotoCamera], mediaType: .video, position: .unspecified)
    
    private var previewView:PreviewView? = nil
    
    private let focusOfInterestIndicator = FocusOfInterestIndicatorView()
    private var focusOfInterestConstraintCenterX:NSLayoutConstraint? = nil
    private var focusOfInterestConstraintCenterY:NSLayoutConstraint? = nil
    
    private let exposureOfInterestIndicator = ExposureOfInterestIndicatorView()
    private var exposureOfInterestConstraintCenterX:NSLayoutConstraint? = nil
    private var exposureOfInterestConstraintCenterY:NSLayoutConstraint? = nil
    
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
    
    //
    var _videoFormat: (Int, Int, Int) = (3840,2160,30)
    var videoFormat: (Int, Int, Int) {
        get {
            if let device = self.videoDeviceInput?.device {
                let format = device.activeFormat
                let dimension = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                let fps = Int(device.activeVideoMinFrameDuration.timescale)/Int(device.activeVideoMinFrameDuration.value)
                _videoFormat = (Int(dimension.width), Int(dimension.height), fps)
            }
            return _videoFormat
        }
        set {
            _videoFormat = newValue
            let desireWidth = _videoFormat.0
            let desireHeight = _videoFormat.1
            let desireFps = _videoFormat.2
            
            if let device = self.videoDeviceInput?.device {
                let deviceFormats = device.formats
                if let desireFormat = deviceFormats.first(where: { (format) -> Bool in
                    let dimension = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                    
                    let ranges = format.videoSupportedFrameRateRanges
                    
                    let frameRates = ranges[0]
                    
                    if dimension.width == desireWidth && dimension.height == desireHeight && Int(frameRates.maxFrameRate) >= desireFps {
                        //choose this format
                        return true
                    }
                    return false
                }){
                    do{
                        let ranges = desireFormat.videoSupportedFrameRateRanges
                        let frameRates = ranges[0]
                        
                        try device.lockForConfiguration()
                        
                        device.activeFormat = desireFormat
                        device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: CMTimeScale(desireFps), flags: .valid, epoch: 0)
                        device.activeVideoMaxFrameDuration = frameRates.maxFrameDuration
                        
                        device.unlockForConfiguration()
                    }
                    catch {
                        print("Could not lock device for configuration: \(error)")
                    }
                }
                else{
                    //desire format not available
                }
            }
        }
    }
    
    var _showFocusOfInterestIndicator = false
    var showFocusOfInterestIndicator: Bool {
        get {
            return _showFocusOfInterestIndicator
        }
        
        set {
            if let previewView = self.previewView {
                _showFocusOfInterestIndicator = newValue
                if(_showFocusOfInterestIndicator){
                    DispatchQueue.main.async {
                        let focusPoint = self.focusPointOfInterest
                        let point = previewView.videoPreviewLayer.layerPointConverted(fromCaptureDevicePoint: focusPoint)
                        let previewCenter = previewView.center
                        UIView.animate(withDuration: 0.3, animations: {
                            self.focusOfInterestConstraintCenterX?.constant = point.x - previewCenter.x
                            self.focusOfInterestConstraintCenterY?.constant = point.y - previewCenter.y
                            previewView.layoutIfNeeded()
                        })
                    }
                }
                else {
                    DispatchQueue.main.async {
                        self.focusOfInterestIndicator.isHidden = true
                    }
                }
            }
        }
    }
    
    var _showExposureOfInterestIndicator = false
    var showExposureOfInterestIndicator: Bool {
        get {
            return _showExposureOfInterestIndicator
        }
        
        set {
            if let previewView = self.previewView {
                _showExposureOfInterestIndicator = newValue
                if(_showExposureOfInterestIndicator){
                    DispatchQueue.main.async {
                        self.exposureOfInterestIndicator.isHidden = false
                        let exposurePoint = self.exposurePointOfInterest
                        let point = previewView.videoPreviewLayer.layerPointConverted(fromCaptureDevicePoint: exposurePoint)
                        let previewCenter = previewView.center
                        UIView.animate(withDuration: 0.3, animations: {
                            self.exposureOfInterestConstraintCenterX?.constant = point.x - previewCenter.x
                            self.exposureOfInterestConstraintCenterY?.constant = point.y - previewCenter.y
                            previewView.layoutIfNeeded()
                        })
                    }
                }
                else{
                    DispatchQueue.main.async {
                        self.exposureOfInterestIndicator.isHidden = true
                    }
                }
            }
        }
    }
    
    var zoomFactor: Float {
        get {
            if let device = self.videoDeviceInput?.device {
                return Float(device.videoZoomFactor)
            }
            return 0
        }
        set{
            if let device = self.videoDeviceInput?.device {
                let zoom:Float = {
                    if newValue > Float(device.maxAvailableVideoZoomFactor) {
                        return Float(device.maxAvailableVideoZoomFactor)
                    }
                    
                    if newValue < Float(device.minAvailableVideoZoomFactor) {
                        return Float(device.minAvailableVideoZoomFactor)
                    }
                    
                    return newValue
                }()
                
                do{
                    try device.lockForConfiguration()
                    device.videoZoomFactor = CGFloat(zoom)//ramp(toVideoZoomFactor: CGFloat(zoom), withRate: 1)
                    device.unlockForConfiguration()
                }
                catch {
                    print("Could not lock device for configuration: \(error)")
                }
                
            }
        }
    }
    
    var zoomFactorRange:(Float, Float) {
        get {
            if let device = self.videoDeviceInput?.device {
                return (Float(device.minAvailableVideoZoomFactor), Float(device.maxAvailableVideoZoomFactor))
            }
            return (0, 0)
        }
    }
    
    public func isExposureModeSupported(_ mode:AVCaptureDevice.ExposureMode) -> Bool {
        if let device = self.videoDeviceInput?.device {
            return device.isExposureModeSupported(mode)
        }
        return false
    }
    
    var currentCameraSupportedFormats: [AVCaptureDevice.DeviceType:[(CMVideoDimensions, Int, Int)]] {
        get {
            var formats:[AVCaptureDevice.DeviceType:[(CMVideoDimensions, Int, Int)]] = [:]

            if let videoDeviceInput = self.videoDeviceInput {
            
                let device = videoDeviceInput.device
                
                let deviceFormats = device.formats
                formats[device.deviceType] = deviceFormats.map({ (format) -> (CMVideoDimensions, Int, Int) in
                    let dimension = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                    let ranges = (format.videoSupportedFrameRateRanges as [AVFrameRateRange])
                    
                    let frameRates = ranges[0]
                    return (dimension, Int(frameRates.minFrameRate), Int(frameRates.maxFrameRate))
                })
            }
            
            return formats
        }
    }
    
    var backCameraSupportedFormats: [AVCaptureDevice.DeviceType:[(CMVideoDimensions, Int, Int)]] {
        get {
            var formats:[AVCaptureDevice.DeviceType:[(CMVideoDimensions, Int, Int)]] = [:]
            print(self.devices)
            for device in self.devices {
                if device.position != .back {
                    continue
                }
                
                let deviceFormats = device.formats
                formats[device.deviceType] = deviceFormats.map({ (format) -> (CMVideoDimensions, Int, Int) in
                    let dimension = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                    let ranges = (format.videoSupportedFrameRateRanges as [AVFrameRateRange])
                    
                    let frameRates = ranges[0]
                    return (dimension, Int(frameRates.minFrameRate), Int(frameRates.maxFrameRate))
                })
            }
            
            return formats
        }
    }
    
    var frontCameraSupportedFormats: [AVCaptureDevice.DeviceType:[(CMVideoDimensions, Int, Int)]] {
        get {
            var formats:[AVCaptureDevice.DeviceType:[(CMVideoDimensions, Int, Int)]] = [:]
            print(self.devices)
            for device in self.devices {
                if device.position != .front {
                    continue
                }
                let deviceFormats = device.formats
                formats[device.deviceType] = deviceFormats.map({ (format) -> (CMVideoDimensions, Int, Int) in
                    let dimension = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                    let ranges = (format.videoSupportedFrameRateRanges as [AVFrameRateRange])
                    
                    let frameRates = ranges[0]
                    return (dimension, Int(frameRates.minFrameRate), Int(frameRates.maxFrameRate))
                })
            }
            
            return formats
        }
    }
    
    /*!
     @property exposureMode
     @abstract
     Indicates current exposure mode
     
     @discussion
     
     .autoExpose
        Camera adjst exposure settings once and then exposure settings do not change over time.
     
     .locked
        Exposure settings remain the same over time.
     
     .continuousAutoExposure
        Camera automatically ajust exposure by changing exposure time(Shutter) and ISO. This is the same as Auto mode in Digital Camera
     
     .custom
        User provides exposure time(Shutter) and ISO. Aperture is constant.
     
     */
    var _exposureMode:  AVCaptureDevice.ExposureMode = .autoExpose
    public var exposureMode : AVCaptureDevice.ExposureMode {
        get {
            if let device = self.videoDeviceInput?.device {
                _exposureMode = device.exposureMode
            }
            return _exposureMode
        }
        set{
            _exposureMode = newValue
            if let device = self.videoDeviceInput?.device {
                if device.isExposureModeSupported(newValue){
                    do{
                        try device.lockForConfiguration()
                        device.exposureMode = _exposureMode
                        device.unlockForConfiguration()
                        self.updateFocusAndExposureIndicator()
                    }
                    catch {
                        print("Could not lock device for configuration: \(error)")
                    }
                }
            }
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
    
    public var exposureDuration : CMTime {
        get {
            if let device = self.videoDeviceInput?.device {
                return device.exposureDuration
            }
            return CMTime.zero
        }
    }
    
    public var minExposureDuration: CMTime {
        get {
            if let device = self.videoDeviceInput?.device {
                return device.activeFormat.minExposureDuration
            }
            return CMTime.zero
        }
    }
    
    public var maxExposureDuration: CMTime {
        get {
            if let device = self.videoDeviceInput?.device {
                return device.activeFormat.maxExposureDuration
            }
            return CMTime.zero
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
                        
                        if self.showExposureOfInterestIndicator {
                            self.showExposureOfInterestIndicator = true
                        }
                        
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
                        device.focusMode = _focusMode
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
                if device.isFocusPointOfInterestSupported == false || device.isFocusModeSupported(focusMode) == false {
                    return CGPoint(x:0.5, y:0.5)
                }
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
                        
                        if self.showFocusOfInterestIndicator {
                            self.showFocusOfInterestIndicator = true
                        }
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
                if device.isLockingFocusWithCustomLensPositionSupported {
                    device.setFocusModeLocked(lensPosition: lensPosition, completionHandler: nil)
                }
                else {
                    device.setFocusModeLocked(lensPosition: AVCaptureDevice.currentLensPosition, completionHandler: nil)
                }
                
                device.unlockForConfiguration()
                self.updateFocusAndExposureIndicator()
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
    
    var _desiredWhiteBalanceMode: WhiteBalanceMode = .auto
    var desiredWhiteBalanceMode: WhiteBalanceMode {
        get {
            return _desiredWhiteBalanceMode
        }
        
        set {
            _desiredWhiteBalanceMode = newValue
        
            guard let device = self.videoDeviceInput?.device else {
                return
            }
            
            let tempAndTint = self.temperatureAndTintValue
            var temp: AVCaptureDevice.WhiteBalanceTemperatureAndTintValues?
            switch _desiredWhiteBalanceMode {
                case .auto:
                    do {
                        try device.lockForConfiguration()
                        device.whiteBalanceMode = .continuousAutoWhiteBalance
                        device.unlockForConfiguration()
                    }
                    catch {
                        print("\(error)")
                    }
                    return
                case .sunlight:
                    temp = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues.init(temperature: 5200, tint: tempAndTint.tint)
                    break
                case .cloudy:
                    temp = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues.init(temperature: 6000, tint: tempAndTint.tint)
                    break
                case .tungsten:
                    temp = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues.init(temperature: 3000, tint: tempAndTint.tint)
                    break
                case .shade:
                    temp = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues.init(temperature: 7500, tint: tempAndTint.tint)
                    break
                case .flash:
                    temp = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues.init(temperature: 4000, tint: tempAndTint.tint)
                    break
                case .manual:
                    break
                default:
                    break
            }
            if temp != nil {
                self.setWhiteBalanceModeLocked(with: temp!)
            }
            else{
                self.setWhiteBalanceModeLocked(with: tempAndTint)
            }
        }
    }
    
    var whiteBalanceMode: AVCaptureDevice.WhiteBalanceMode {
        get{
            if let device = self.videoDeviceInput?.device {
                return device.whiteBalanceMode
            }
            return .continuousAutoWhiteBalance
        }
    }
    
    public var temperatureAndTintValue : AVCaptureDevice.WhiteBalanceTemperatureAndTintValues{
        get {
            if let device = self.videoDeviceInput?.device {
                return device.temperatureAndTintValues(for: device.deviceWhiteBalanceGains)
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
                
                self.updateFocusAndExposureIndicator()
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
                _desiredWhiteBalanceMode = .manual
            }
            catch {
                print("Could not lock device for configuration: \(error)")
            }
        }
    }
    
    var lensAperture: Float {
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
    
    var useBluetoothMicrophone: Bool {
        get {
            return !session.automaticallyConfiguresApplicationAudioSession
        }
        set {
            session.usesApplicationAudioSession = true
            session.automaticallyConfiguresApplicationAudioSession = !newValue
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
    
    var currentExposureDuration: CMTime {
        get {
            return AVCaptureDevice.currentExposureDuration
        }
    }
    
    var currentISO: Float {
        get {
            return AVCaptureDevice.currentISO
        }
    }
    
    var currentExposureTargetBias: Float {
        get {
            return AVCaptureDevice.currentExposureTargetBias
        }
    }
    
    var currentLensPosition: Float {
        get {
            return AVCaptureDevice.currentLensPosition
        }
    }
    
    var currentWhiteBalanceGains: AVCaptureDevice.WhiteBalanceGains {
        get {
            return AVCaptureDevice.currentWhiteBalanceGains
        }
    }
    
    var currentCamera: (AVCaptureDevice.Position, AVCaptureDevice.DeviceType) {
        get {
            if let device = self.videoDeviceInput?.device {
                return (device.position, device.deviceType)
            }
            return (AVCaptureDevice.Position.back, AVCaptureDevice.DeviceType.builtInWideAngleCamera)
        }
    }
    
    var iso: Float {
        get {
            return self.videoDeviceInput.device.iso
        }
    }
    
    var flashMode:AVCaptureDevice.FlashMode {
        get{
            if let device = self.videoDeviceInput?.device {
                if device.isFlashAvailable {
                    return device.flashMode
                }
                return .off
            }
            
            return .off
        }
        
        set {
            if let device = self.videoDeviceInput?.device {
                if device.isFlashModeSupported(newValue) {
                    do {
                        try device.lockForConfiguration()
                        
                        device.flashMode = newValue
                        
                        device.unlockForConfiguration()
                    }
                    catch {
                        print("Could not lock device for configuration: \(error)")
                    }
                }
            }
        }
    }
    
    var torchMode:AVCaptureDevice.TorchMode {
        get{
            if let device = self.videoDeviceInput?.device {
                if device.isTorchAvailable {
                    return device.torchMode
                }
                return .off
            }
            
            return .off
        }
        
        set {
            if let device = self.videoDeviceInput?.device {
                if device.isTorchModeSupported(newValue) {
                    do {
                        try device.lockForConfiguration()
                        
                        device.torchMode = newValue
                        
                        device.unlockForConfiguration()
                    }
                    catch {
                        print("Could not lock device for configuration: \(error)")
                    }
                }
            }
        }
    }
    
    var torchLevel:Float {
        get{
            if let device = self.videoDeviceInput?.device {
                if device.isTorchAvailable {
                    return device.torchLevel
                }
                return 0
            }
            
            return 0
        }
        
        set {
            if let device = self.videoDeviceInput?.device {
                do {
                    try device.lockForConfiguration()
                    
                    try device.setTorchModeOn(level: newValue)
                    
                    device.unlockForConfiguration()
                }
                catch {
                    print("Could not lock device for configuration or set torch mode: \(error)")
                }
            }
        }
    }
    
    var preferredVideoStabilizationMode: AVCaptureVideoStabilizationMode {
        get {
            if let connection = self.movieFileOutput?.connection(with: .video) {
                return connection.preferredVideoStabilizationMode
            }
            return .off
        }
        set {
            if let connection = self.movieFileOutput?.connection(with: .video) {
                if let device = self.videoDeviceInput?.device {
                    if connection.isVideoStabilizationSupported {
                        if device.activeFormat.isVideoStabilizationModeSupported(newValue) {
                            connection.preferredVideoStabilizationMode = newValue
                        }
                        else{
                            //if not supported, choose next available value
                            switch newValue {
                            case .auto:
                                if device.activeFormat.isVideoStabilizationModeSupported(.auto) {
                                    connection.preferredVideoStabilizationMode = .auto
                                    break
                                }
                                if device.activeFormat.isVideoStabilizationModeSupported(.standard) {
                                    connection.preferredVideoStabilizationMode = .standard
                                    break
                                }
                                if device.activeFormat.isVideoStabilizationModeSupported(.off) {
                                    connection.preferredVideoStabilizationMode = .off
                                    break
                                }
                                break
                            case .off:
                                if device.activeFormat.isVideoStabilizationModeSupported(.auto) {
                                    connection.preferredVideoStabilizationMode = .auto
                                    break
                                }
                                if device.activeFormat.isVideoStabilizationModeSupported(.off) {
                                    connection.preferredVideoStabilizationMode = .off
                                    break
                                }
                                break
                            case .standard:
                                if device.activeFormat.isVideoStabilizationModeSupported(.standard) {
                                    connection.preferredVideoStabilizationMode = .standard
                                    break
                                }
                                if device.activeFormat.isVideoStabilizationModeSupported(.cinematic) {
                                    connection.preferredVideoStabilizationMode = .cinematic
                                    break
                                }
                                if device.activeFormat.isVideoStabilizationModeSupported(.off) {
                                    connection.preferredVideoStabilizationMode = .off
                                    break
                                }
                                connection.preferredVideoStabilizationMode = .cinematic
                                break
                            case .cinematic:
                                connection.preferredVideoStabilizationMode = .off
                                break
                            default:
                                connection.preferredVideoStabilizationMode = .off
                                break
                            }
                        }
                    }
                }
            }
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
    
    public func connectSession(with previewView:PreviewView!){
        
        if OperationQueue.current != OperationQueue.main {
            DispatchQueue.main.async {
                self.connectSession(with: previewView)
            }
            return
        }
        
        previewView.session = self.session
        
        previewView.addSubview(self.focusOfInterestIndicator)
        self.focusOfInterestConstraintCenterX = NSLayoutConstraint(item: self.focusOfInterestIndicator, attribute: .centerX, relatedBy: .equal, toItem: previewView, attribute: .centerX, multiplier: 1.0, constant: 0)
        self.focusOfInterestConstraintCenterY = NSLayoutConstraint(item: self.focusOfInterestIndicator, attribute: .centerY, relatedBy: .equal, toItem: previewView, attribute: .centerY, multiplier: 1.0, constant: 0)
        previewView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[v(56)]", options: .init(rawValue: 0), metrics: nil, views: ["v":self.focusOfInterestIndicator]))
        previewView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[v(56)]", options: .init(rawValue: 0), metrics: nil, views: ["v":self.focusOfInterestIndicator]))
        previewView.addConstraint(self.focusOfInterestConstraintCenterX!)
        previewView.addConstraint(self.focusOfInterestConstraintCenterY!)
        
        
        previewView.addSubview(self.exposureOfInterestIndicator)
        previewView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[v(46)]", options: .init(rawValue: 0), metrics: nil, views: ["v":self.exposureOfInterestIndicator]))
        previewView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[v(46)]", options: .init(rawValue: 0), metrics: nil, views: ["v":self.exposureOfInterestIndicator]))
        self.exposureOfInterestConstraintCenterX = NSLayoutConstraint(item: self.exposureOfInterestIndicator, attribute: .centerX, relatedBy: .equal, toItem: previewView, attribute: .centerX, multiplier: 1.0, constant: 0)
        self.exposureOfInterestConstraintCenterY = NSLayoutConstraint(item: self.exposureOfInterestIndicator, attribute: .centerY, relatedBy: .equal, toItem: previewView, attribute: .centerY, multiplier: 1.0, constant: 0)
        previewView.addConstraint(self.exposureOfInterestConstraintCenterX!)
        previewView.addConstraint(self.exposureOfInterestConstraintCenterY!)
        self.exposureOfInterestIndicator.layer.cornerRadius = 23
        
        self.focusOfInterestIndicator.addTarget(self, action: #selector(focusDrag(_:withEvent:)), for: .touchDragInside)
        self.exposureOfInterestIndicator.addTarget(self, action: #selector(exposureDrag(_:withEvent:)), for: .touchDragInside)
        
        self.focusOfInterestIndicator.addTarget(self, action: #selector(focusLockUnlock(_:)), for: .valueChanged)
        self.exposureOfInterestIndicator.addTarget(self, action: #selector(exposureLockUnlock(_:)), for: .valueChanged)
    }
    // Call this on the session queue.
    /// - Tag: ConfigureSession
    public func configureSession(with previewView:PreviewView!) {
        if setupResult != .success {
            return
        }
        
        self.previewView = previewView
        
        print("beginConfiguration()")
        session.beginConfiguration()
        
        /*
         We do not create an AVCaptureMovieFileOutput when setting up the session because
         Live Photo is not supported when AVCaptureMovieFileOutput is added to the session.
         */
        
        let desireVideoFormat = self.videoFormat
        
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
                
                if let device = self.videoDeviceInput?.device {
                    let deviceFormats = device.formats
                    if let desireFormat = deviceFormats.first(where: { (format) -> Bool in
                        let dimension = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                        
                        let ranges = (format.videoSupportedFrameRateRanges as [AVFrameRateRange])
                        
                        let frameRates = ranges[0]
                        
                        if dimension.width == desireVideoFormat.0 && dimension.height == desireVideoFormat.1 && Int(frameRates.maxFrameRate) >= desireVideoFormat.2 {
                            //choose this format
                            return true
                        }
                        return false
                    }){
                        let ranges = desireFormat.videoSupportedFrameRateRanges
                        let frameRates = ranges[0]
 
                        do {
                            try device.lockForConfiguration()
                            
                            device.isSubjectAreaChangeMonitoringEnabled = true
                            device.activeFormat = desireFormat
                            device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: CMTimeScale(desireVideoFormat.2), flags: .valid, epoch: 0)
                            device.activeVideoMaxFrameDuration = frameRates.maxFrameDuration
                            
                            device.unlockForConfiguration()
                        }
                        catch {
                            print("Could not lock device for configuration: \(error)")
                        }
                       
                    }
                    else{
                        //desire format not available
                        session.sessionPreset = .high
                    }
                }
                
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
            if let connection = movieFileOutput.connection(with: .video) {
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .auto
                }
                
                if movieFileOutput.availableVideoCodecTypes.contains(AVVideoCodecType.hevc){
                    movieFileOutput.setOutputSettings([AVVideoCodecKey : AVVideoCodecType.hevc], for: connection)
                }
                else if movieFileOutput.availableVideoCodecTypes.contains(AVVideoCodecType.h264){
                    movieFileOutput.setOutputSettings([AVVideoCodecKey : AVVideoCodecType.h264], for: connection)
                }
                else {
                    //use default
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
            self.session.beginConfiguration()
            
            if let deviceFormat =
                device.formats.filter({ (format) -> Bool in
                    let dimension = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                    
                    if (Double(dimension.width)*3.0)/(Double(dimension.height)*4.0) < 1.3 {
                        return false
                    }
                    
                    return dimension.width <= 3840 && !(dimension.width == 1920 && dimension.height >= 1200) && dimension.width != 2592 && !(dimension.width == 1440 && dimension.height == 1080) && dimension.width != 3088
                }).max (by: { (format1, format2) -> Bool in
                    let dimension1 = CMVideoFormatDescriptionGetDimensions(format1.formatDescription)
                    let dimension2 = CMVideoFormatDescriptionGetDimensions(format2.formatDescription)
                    
                    if dimension1.width*dimension1.height == dimension2.width*dimension2.height {
                        let range1 = format1.videoSupportedFrameRateRanges[0]
                        let range2 = format2.videoSupportedFrameRateRanges[0]
                        return range1.maxFrameRate <= range2.maxFrameRate
                    }
                    return dimension1.width*dimension1.height <= dimension2.width*dimension2.height
                }) {
                
                let ranges = deviceFormat.videoSupportedFrameRateRanges
                let frameRates = ranges[0]
                
                do {
                    try device.lockForConfiguration()

                    device.isSubjectAreaChangeMonitoringEnabled = true
                    device.activeFormat = deviceFormat
                    device.activeVideoMinFrameDuration = frameRates.minFrameDuration
                    device.activeVideoMaxFrameDuration = frameRates.maxFrameDuration
                    device.unlockForConfiguration()
                }
                catch {
                    print("Could not lock device for configuration: \(error)")
                }
                
            }
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: device)
            
            // Remove the existing device input first, since the system doesn't support simultaneous use of the rear and front cameras.
            self.session.removeInput(self.videoDeviceInput)
            
            if self.session.canAddInput(videoDeviceInput) {
                
                self.session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
            } else {
                self.session.addInput(self.videoDeviceInput)
            }
            if let connection = self.movieFileOutput?.connection(with: .video) {
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = self.preferredVideoStabilizationMode
                }
            }
            self.session.commitConfiguration()
            self.showFocusOfInterestIndicator = true
            self.showExposureOfInterestIndicator = true
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
        
        if let movieFileOutput = self.movieFileOutput {
            let connection = movieFileOutput.connection(with: .video)
            connection?.videoOrientation = self.currentVideOrientation
            
            movieFileOutput.startRecording(to: URL(fileURLWithPath: outputFilePath), recordingDelegate: self)
        }
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
    
    /////////////////////////////////////
    //
    //
    @objc func focusDrag(_ control:UIControl?, withEvent event:UIEvent){
        if let touch = event.allTouches?.first {
            if let previewView = self.previewView {
                let center = touch.location(in: previewView)
                let devicePoint = previewView.videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: center)
                if  let device = self.videoDeviceInput?.device {
                    if device.isFocusPointOfInterestSupported {
                        self.focusPointOfInterest = devicePoint
                        previewView.bringSubviewToFront(self.focusOfInterestIndicator)
                    }
                }
            }
        }
    }
    
    @objc func exposureDrag(_ control:UIControl?, withEvent event:UIEvent){
        if let touch = event.allTouches?.first {
            if let previewView = self.previewView {
                let center = touch.location(in: previewView)
                let devicePoint = previewView.videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: center)
                if  let device = self.videoDeviceInput?.device {
                    if device.isExposurePointOfInterestSupported {
                        self.exposurePointOfInterest = devicePoint
                        previewView.bringSubviewToFront(self.exposureOfInterestIndicator)
                    }
                }
            }
        }
    }
    
    @objc func focusLockUnlock(_ sender: Any){
        if let device = self.videoDeviceInput?.device {
            switch device.focusMode {
            case .locked:
                self.focusMode = .continuousAutoFocus
                break
            case .continuousAutoFocus:
                self.focusMode = .locked
                break
            default:
                break
            }
            
            self.updateFocusAndExposureIndicator()
        }
    }
    
    @objc func exposureLockUnlock(_ sender: Any){
        if let device = self.videoDeviceInput?.device {
            switch device.exposureMode {
            case .custom, .locked:
                self.exposureMode = .continuousAutoExposure
                self.exposureTargetBias = 0
                break
            case .continuousAutoExposure:
                self.exposureMode = .locked
                break
            default:
                break
            }
            
            self.updateFocusAndExposureIndicator()
        }
    }
    
    private func updateFocusAndExposureIndicator(){
        if let device = self.videoDeviceInput?.device {
            self.focusOfInterestIndicator.locked = device.focusMode == .locked
            self.exposureOfInterestIndicator.locked = device.exposureMode == .locked || device.exposureMode == .custom
        }
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
