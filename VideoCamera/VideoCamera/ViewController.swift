//
//  ViewController.swift
//  VideoCamera
//
//  Created by jimmy on 2019/3/28.
//  Copyright © 2019 huangsj. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import CoreMotion

class ViewController: UIViewController {

    var portraitConstraints:[NSLayoutConstraint] = []
    var landscapeConstraints:[NSLayoutConstraint] = []
    var landscapeRightConstraints:[NSLayoutConstraint] = []
    
    var timer:Timer?
    
    
    var motionManager:CMMotionManager {
        get {
            struct Singleton {
                static let _motionManager:CMMotionManager = CMMotionManager()
            }
            return Singleton._motionManager
        }
    }
    
    internal let camera = CameraManager.sharedInstance
    
    internal var batteryView:ALBatteryView!
    internal var previewView:PreviewView!
    private let previewTapGestureRecognizer:UILongPressGestureRecognizer = UILongPressGestureRecognizer()
    
    internal var settingsContainerView:UIControl!
    internal var formatSettingsView:FormatSettingsView!
    
    internal let sessionQueue = DispatchQueue(label: "session queue") // Communicate with the session and other session objects on this queue.
    
    internal var cameraBottom: CameraBottomControl!
    private var recordTimeLabel: RecordTimerLabel!
    private var landscapeTopBannerBackgroundView: UIView!
    
    /*! The settings button is for 4k/1080p/720p resoltuon and fps configurations */
    internal var settingsButton: UIButton!
    /*! The lens button is for lens configuration, such as Optical Image Stablization */
    internal var lensButton: UIButton!
    internal var flashButton: UIButton!
    internal var cameraParameterButtons:[CameraParameterButton] = []
    
    private var keyValueObservations = [NSKeyValueObservation]()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            return .lightContent
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.previewView = PreviewView()
        self.previewView.backgroundColor = .black
        self.previewView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.previewView);
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[v]-0-|", options: .init(rawValue: 0), metrics: nil, views: ["v":self.previewView!]))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[v]-0-|", options: .init(rawValue: 0), metrics: nil, views: ["v":self.previewView!]))
     
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                // The user has previously granted access to the camera.
                break
            
            case .notDetermined:
                /*
                 The user has not yet been presented with the option to grant
                 video access. We suspend the session queue to delay session
                 setup until the access request has completed.
                 
                 Note that audio access will be implicitly requested when we
                 create an AVCaptureDeviceInput for audio during session setup.
                 */
                sessionQueue.suspend()
                AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                    if !granted {
                        self.camera.setupResult = .notAuthorized
                    }
                    self.sessionQueue.resume()
                })
            
            default:
                // The user has previously denied access.
                self.camera.setupResult = .notAuthorized
        }
        /*
         Setup the capture session.
         In general, it is not safe to mutate an AVCaptureSession or any of its
         inputs, outputs, or connections from multiple threads at the same time.
         
         Don't perform these tasks on the main queue because
         AVCaptureSession.startRunning() is a blocking call, which can
         take a long time. We dispatch session setup to the sessionQueue, so
         that the main queue isn't blocked, which keeps the UI responsive.
         */
        self.camera.connectSession(with: self.previewView)
        sessionQueue.async {
            self.camera.configureSession(with: self.previewView)
            
            DispatchQueue.main.async {
                let format = self.camera.videoFormat
                let formatStr:String = {
                    if format.0 == 3840 {
                        return "4k"
                    }
                    if format.0 == 1920{
                        return "1080p"
                    }
                    return "720p"
                }()
                let settingsTitle = NSAttributedString(string: "\(formatStr) \(format.2)", attributes: [NSAttributedString.Key.font:UIFont.systemFont(ofSize: 12), NSAttributedString.Key.foregroundColor:UIColor.white])
                self.settingsButton.setAttributedTitle(settingsTitle, for: .normal)
                self.cameraBottom.reload()
            }
        }
        
        let isLandscape = UIDevice.current.orientation == .landscapeLeft ||  UIDevice.current.orientation == .landscapeRight
        let isLandscapeRight = UIDevice.current.orientation == .landscapeRight
        
        cameraBottom = CameraBottomControl()
        cameraBottom.translatesAutoresizingMaskIntoConstraints = false
        cameraBottom.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.4)
        self.view.addSubview(cameraBottom)
        
        self.landscapeTopBannerBackgroundView = UIView(frame: .zero)
        self.landscapeTopBannerBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        self.landscapeTopBannerBackgroundView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)
        self.view.addSubview(self.landscapeTopBannerBackgroundView)
        
        self.recordTimeLabel = RecordTimerLabel(frame: .zero)
        self.recordTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.recordTimeLabel)
        self.recordTimeLabel.isRecording = false
        
        self.settingsButton = UIButton(type: .custom)
        self.settingsButton.translatesAutoresizingMaskIntoConstraints = false
        let settingsTitle = NSAttributedString(string: "4k 30", attributes: [NSAttributedString.Key.font:UIFont.systemFont(ofSize: 12), NSAttributedString.Key.foregroundColor:UIColor.white])
        self.settingsButton.contentHorizontalAlignment = .right
        self.settingsButton.setAttributedTitle(settingsTitle, for: .normal)
        self.settingsButton.addTarget(self, action: #selector(showSettingsView(_:)), for: .touchUpInside)
        self.view.addSubview(self.settingsButton)
        
        self.lensButton = UIButton(type: .custom)
        self.lensButton.translatesAutoresizingMaskIntoConstraints = false
        self.lensButton.setImage(UIImage(named: "OIS"), for: .normal)
        self.lensButton.contentHorizontalAlignment = .left
        self.view.addSubview(self.lensButton)
        self.lensButton.addTarget(self, action: #selector(lensButtonTap(_:)), for: .touchUpInside)
        
        self.flashButton = UIButton(type: .custom)
        self.flashButton.translatesAutoresizingMaskIntoConstraints = false
        self.flashButton.setImage(UIImage(named: "flash_auto"), for: .normal)
        self.view.addSubview(self.flashButton)
        self.flashButton.addTarget(self, action: #selector(flashButtonTap(_:)), for: .touchUpInside)
        
        self.batteryView = ALBatteryView()
        self.batteryView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.batteryView)
        
        self.settingsContainerView = UIControl()
        self.formatSettingsView = FormatSettingsView()
        self.settingsContainerView.translatesAutoresizingMaskIntoConstraints = false
        self.formatSettingsView.translatesAutoresizingMaskIntoConstraints = false
        
        self.settingsContainerView.addTarget(self, action: #selector(hideSettingsView(_:)), for: .touchUpInside)
        
        self.view.addSubview(self.settingsContainerView)
        self.settingsContainerView.addSubview(self.formatSettingsView)
        self.settingsContainerView.addConstraint(NSLayoutConstraint(item: self.formatSettingsView!, attribute: .centerX, relatedBy: .equal, toItem: self.settingsContainerView, attribute: .centerX, multiplier: 1.0, constant: 0))
        self.settingsContainerView.addConstraint(NSLayoutConstraint(item: self.formatSettingsView!, attribute: .centerY, relatedBy: .equal, toItem: self.settingsContainerView, attribute: .centerY, multiplier: 1.0, constant: 0))
        self.settingsContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[v(320)]", options: .init(rawValue: 0), metrics: nil, views: ["v":self.formatSettingsView!]))
        self.settingsContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[v(270)]", options: .init(rawValue: 0), metrics: nil, views: ["v":self.formatSettingsView!]))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[v]-0-|", options: .init(rawValue: 0), metrics: nil, views: ["v":self.settingsContainerView!]))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[v]-0-|", options: .init(rawValue: 0), metrics: nil, views: ["v":self.settingsContainerView!]))
        self.settingsContainerView.isHidden = true
        
        let screenBounds = UIScreen.main.bounds
        let screenWidth = screenBounds.width <= screenBounds.height ? screenBounds.width:screenBounds.height
        let screenHeight = screenBounds.width >= screenBounds.height ? screenBounds.width:screenBounds.height
        
        let cameraParameterButtonWidth:Float = {
            if screenWidth >= 375 {
                return Float(screenWidth)/6
            }
            return 69
        }()
        
        self.cameraParameterButtons = [NSLocalizedString("Exposure", comment: ""), NSLocalizedString("Shutter", comment: ""), NSLocalizedString("ISO", comment: ""), NSLocalizedString("WB", comment: ""), NSLocalizedString("Focus", comment: ""), NSLocalizedString("Zoom", comment: "")].map({ (str) -> CameraParameterButton in
            let button = CameraParameterButton()
            button.text2 = str
            button.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(button)
            self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[v(\(cameraParameterButtonWidth))]", options: .init(rawValue: 0), metrics: nil, views: ["v":button]));
            self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[v(42)]", options: .init(rawValue: 0), metrics: nil, views: ["v":button]));
            return button
        })
        
        
        
        let landscapeSpacing = (screenHeight - 6*CGFloat(cameraParameterButtonWidth) - 100 - 44)/7
        
        if screenWidth >= 375 {
            
            let portraitSpacing = (screenWidth - 6*CGFloat(cameraParameterButtonWidth))/5
            
            for i in 0...5 {
                let button = self.cameraParameterButtons[i]
                portraitConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[v]-0-[v1]", options: .init(rawValue: 0), metrics: nil, views: ["v":button, "v1":self.cameraBottom!]))
                landscapeConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[v]-|", options: .init(rawValue: 0), metrics: nil, views: ["v":button]))
                landscapeRightConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[v]-|", options: .init(rawValue: 0), metrics: nil, views: ["v":button]))
                
                if(i == 0){
                    let constraint = NSLayoutConstraint(item: button, attribute: .left, relatedBy: .equal, toItem: self.cameraBottom, attribute: .left, multiplier: 1.0, constant: 0)
                    portraitConstraints.append(constraint)
                    
                    let constraintLandscape = NSLayoutConstraint.constraints(withVisualFormat: "H:|-\(landscapeSpacing*2)-[v]", options: .init(rawValue: 0), metrics: nil, views: ["v":button])
                    landscapeConstraints.append(contentsOf: constraintLandscape)
                    
                    let constraintLandscapeRight = NSLayoutConstraint.constraints(withVisualFormat: "H:[v1]-\(20)-[v]", options: .init(rawValue: 0), metrics: nil, views: ["v":button, "v1":self.cameraBottom!])
                    landscapeRightConstraints.append(contentsOf: constraintLandscapeRight)
                }
                else{
                    let constraint = NSLayoutConstraint(item: button, attribute: .left, relatedBy: .equal, toItem: self.cameraParameterButtons[i-1], attribute: .right, multiplier: 1.0, constant: portraitSpacing)
                    portraitConstraints.append(constraint)
                    
                    let constraintLandscape = NSLayoutConstraint(item: button, attribute: .left, relatedBy: .equal, toItem: self.cameraParameterButtons[i-1], attribute: .right, multiplier: 1.0, constant: landscapeSpacing)
                    landscapeConstraints.append(constraintLandscape)
                    
                    let constraintLandscapeRight = NSLayoutConstraint(item: button, attribute: .left, relatedBy: .equal, toItem: self.cameraParameterButtons[i-1], attribute: .right, multiplier: 1.0, constant: landscapeSpacing)
                    landscapeRightConstraints.append(constraintLandscapeRight)
                }
                
            }
        }
        else{
            let portraitSpacing = (screenWidth - 3*CGFloat(cameraParameterButtonWidth))/2
            let landscapeSpacingSmall = (screenHeight - 6*CGFloat(cameraParameterButtonWidth) - 100 - 10)/7
            
            for i in 0...5 {
                //two row
                let button = self.cameraParameterButtons[i]
                portraitConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[v]-\((1-i/3)*(16+42))-[v1]", options: .init(rawValue: 0), metrics: nil, views: ["v":button, "v1":self.cameraBottom!]))
                
                landscapeConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[v]-|", options: .init(rawValue: 0), metrics: nil, views: ["v":button]))
                
                landscapeRightConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[v]-|", options: .init(rawValue: 0), metrics: nil, views: ["v":button]))
                
                if(i == 0){
                    let constraint = NSLayoutConstraint(item: button, attribute: .left, relatedBy: .equal, toItem: self.cameraBottom, attribute: .left, multiplier: 1.0, constant: 0)
                    portraitConstraints.append(constraint)
                    
                    let constraintLandscape = NSLayoutConstraint.constraints(withVisualFormat: "H:|-\(landscapeSpacing*2)-[v]", options: .init(rawValue: 0), metrics: nil, views: ["v":button])
                    landscapeConstraints.append(contentsOf: constraintLandscape)
                    
                    let constraintLandscapeRight = NSLayoutConstraint.constraints(withVisualFormat: "H:[v1]-\(20)-[v]", options: .init(rawValue: 0), metrics: nil, views: ["v":button, "v1":self.cameraBottom!])
                    landscapeRightConstraints.append(contentsOf: constraintLandscapeRight)
                }
                else{
                    let constraint = i == 3 ? NSLayoutConstraint(item: button, attribute: .left, relatedBy: .equal, toItem: self.cameraParameterButtons[0], attribute: .left, multiplier: 1.0, constant: 0):NSLayoutConstraint(item: button, attribute: .left, relatedBy: .equal, toItem: self.cameraParameterButtons[(i-1)%3], attribute: .right, multiplier: 1.0, constant: portraitSpacing)
                    portraitConstraints.append(constraint)
                    
                    let constraintLandscape = NSLayoutConstraint(item: button, attribute: .left, relatedBy: .equal, toItem: self.cameraParameterButtons[i-1], attribute: .right, multiplier: 1.0, constant: landscapeSpacingSmall)
                    landscapeConstraints.append(constraintLandscape)
                    
                    let constraintLandscapeRight = NSLayoutConstraint(item: button, attribute: .left, relatedBy: .equal, toItem: self.cameraParameterButtons[i-1], attribute: .right, multiplier: 1.0, constant: landscapeSpacingSmall)
                    landscapeRightConstraints.append(constraintLandscapeRight)
                }
                
            }
        }
        
        portraitConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[v]-0-|", options: .init(rawValue: 0), metrics: nil, views: ["v":cameraBottom!]))
        portraitConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[v(100)]-0-|", options: .init(rawValue: 0), metrics: nil, views: ["v":cameraBottom!]))
        
        landscapeConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[v]-0-|", options: .init(rawValue: 0), metrics: nil, views: ["v":cameraBottom!]))
        landscapeConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:[v(100)]-0-|", options: .init(rawValue: 0), metrics: nil, views: ["v":cameraBottom!]))
        landscapeRightConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[v(100)]", options: .init(rawValue: 0), metrics: nil, views: ["v":cameraBottom!]))
        
        ////////////////////////////
        //position of recordTimeLabel
        portraitConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:[v(80)]", options: .alignAllCenterX, metrics: nil, views: ["v":self.recordTimeLabel!]));
        portraitConstraints.append(NSLayoutConstraint(item: self.recordTimeLabel!, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1.0, constant: 0))
        //portraitConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-6-[v(18)]", options: .init(rawValue: 0), metrics: nil, views: ["v":self.recordTimeLabel!]));
        self.view.addConstraint(NSLayoutConstraint(item: self.recordTimeLabel!, attribute: .centerY, relatedBy: .equal, toItem: self.landscapeTopBannerBackgroundView, attribute: .centerY, multiplier: 1.0, constant: 0))
        
        landscapeConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:[v(80)]", options: .alignAllCenterX, metrics: nil, views: ["v":self.recordTimeLabel!]));
        landscapeConstraints.append(NSLayoutConstraint(item: self.recordTimeLabel!, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1.0, constant: 0))
        landscapeConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-31-[v(18)]", options: .init(rawValue: 0), metrics: nil, views: ["v":self.recordTimeLabel!]));
        
        landscapeRightConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:[v(80)]", options: .alignAllCenterX, metrics: nil, views: ["v":self.recordTimeLabel!]));
        ////////////////////////////
        //position of landscapeTopBannerBackgroundView
        portraitConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[v]-0-|", options: .alignAllCenterX, metrics: nil, views: ["v":self.landscapeTopBannerBackgroundView!]));
        portraitConstraints.append(NSLayoutConstraint(item: self.landscapeTopBannerBackgroundView!, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1.0, constant: 0))
        portraitConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-[v]", options: .init(rawValue: 0), metrics: nil, views: ["v":self.landscapeTopBannerBackgroundView!]));
        portraitConstraints.append(NSLayoutConstraint(item: self.landscapeTopBannerBackgroundView!, attribute: .centerY, relatedBy: .equal, toItem: self.settingsButton, attribute: .centerY, multiplier: 1.0, constant: 0));
        
        landscapeConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:[v(309)]", options: .alignAllCenterX, metrics: nil, views: ["v":self.landscapeTopBannerBackgroundView!]));
        landscapeConstraints.append(NSLayoutConstraint(item: self.landscapeTopBannerBackgroundView!, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1.0, constant: 0))
        landscapeConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-16-[v(47)]", options: .init(rawValue: 0), metrics: nil, views: ["v":self.landscapeTopBannerBackgroundView!]));
        
        landscapeRightConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:[v(309)]", options: .alignAllCenterX, metrics: nil, views: ["v":self.landscapeTopBannerBackgroundView!]));
        /////////////////////////////
        
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[v]-(-30)-[batteryView(30)]", options: .init(rawValue: 0), metrics: nil, views: ["batteryView":self.batteryView!, "v":self.landscapeTopBannerBackgroundView!]))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[batteryView(30)]", options: .alignAllCenterY, metrics: nil, views: ["batteryView":self.batteryView!, "v":self.landscapeTopBannerBackgroundView!]))
        self.view.addConstraint(NSLayoutConstraint(item: self.batteryView!, attribute: .centerY, relatedBy: .equal, toItem: self.landscapeTopBannerBackgroundView, attribute: .centerY, multiplier: 1.0, constant: 0))
        
        /////////////////////////////
        //position of settingsButton
        portraitConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:[v(88)]-0-[batteryView]", options: .alignAllCenterY, metrics: nil, views: ["v":self.settingsButton!, "batteryView":self.batteryView!]));
        portraitConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-[v(30)]", options: .init(rawValue: 0), metrics: nil, views: ["v":self.settingsButton!]));
        
        landscapeConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:[v(88)]", options: .alignAllCenterX, metrics: nil, views: ["v":self.settingsButton!]));
        landscapeConstraints.append(NSLayoutConstraint(item: self.settingsButton!, attribute: .right, relatedBy: .equal, toItem: self.batteryView!, attribute: .left, multiplier: 1.0, constant: 0))
        //landscapeConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:-[v(30)]", options: .init(rawValue: 0), metrics: nil, views: ["v":self.settingsButton!]));
        self.view.addConstraint(NSLayoutConstraint(item: self.settingsButton!, attribute: .centerY, relatedBy: .equal, toItem: self.landscapeTopBannerBackgroundView, attribute: .centerY, multiplier: 1.0, constant: 0))
        
        landscapeRightConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:[v(88)]", options: .alignAllCenterX, metrics: nil, views: ["v":self.settingsButton!]));
        /////////////////////////////
        //position of flashButton
        portraitConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-[v(30)]", options: .alignAllCenterX, metrics: nil, views: ["v":self.flashButton!]));
        portraitConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-[v(30)]", options: .init(rawValue: 0), metrics: nil, views: ["v":self.flashButton!]));
        
        landscapeConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:[v(30)]", options: .alignAllCenterX, metrics: nil, views: ["v":self.flashButton!]));
        landscapeConstraints.append(NSLayoutConstraint(item: self.flashButton!, attribute: .left, relatedBy: .equal, toItem: self.landscapeTopBannerBackgroundView, attribute: .left, multiplier: 1.0, constant: 8))
        landscapeConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-31-[v(30)]", options: .init(rawValue: 0), metrics: nil, views: ["v":self.flashButton!]));
        
        landscapeRightConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:[v(30)]", options: .alignAllCenterX, metrics: nil, views: ["v":self.flashButton!]));
        
        /////////////////////////////////
        //position of lensButton
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[flashButton]-0-[lensButton(118)]", options: .init(rawValue: 0), metrics: nil, views: ["flashButton":self.flashButton!, "lensButton":self.lensButton!]))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[lensButton(30)]", options: .init(rawValue: 0), metrics: nil, views: [ "lensButton":self.lensButton!]));
        self.view.addConstraint(NSLayoutConstraint(item: self.lensButton!, attribute: .centerY, relatedBy: .equal, toItem: self.flashButton!, attribute: .centerY, multiplier: 1.0, constant: 0))
        
        landscapeRightConstraints.forEach { (constraint) in
            if isLandscapeRight {
                constraint.priority = .defaultHigh
            }
            else{
                constraint.priority = .defaultLow
            }
            constraint.isActive = isLandscape
        }
        
        portraitConstraints.forEach { (constraint) in
            constraint.isActive = !isLandscape
        }
        
        landscapeConstraints.forEach { (constraint) in
            if !isLandscapeRight {
                constraint.priority = .defaultHigh
            }
            else{
                constraint.priority = .defaultLow
            }
            constraint.isActive = isLandscape
        }
        
        self.view.addConstraints(portraitConstraints)
        self.view.addConstraints(landscapeConstraints)
        self.view.addConstraints(landscapeRightConstraints)
        
        //Add Target for Control Events
        self.cameraBottom.cameraRollButton.addTarget(self, action: #selector(cameraRollTapped(_:)), for: .touchUpInside)
        self.cameraBottom.recordButton.addTarget(self, action: #selector(recordTapped(_:)), for: .touchUpInside)
        self.cameraBottom.changeCameraButton.addTarget(self, action: #selector(changeCameraTapped(_:)), for: .touchUpInside)
        
        self.addObservers()
        
        self.previewTapGestureRecognizer.minimumPressDuration = 0
        self.previewView.addGestureRecognizer(self.previewTapGestureRecognizer)
        self.previewTapGestureRecognizer.addTarget(self, action: #selector(focusTap(_:)))

    }
    
    
    let motionQueue = OperationQueue()
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.recalcConstraints()
        self.view.setNeedsUpdateConstraints()
        
        DispatchQueue.global().async {
            
            if self.motionManager.isDeviceMotionAvailable {
                let camera = self.camera
                self.motionManager.deviceMotionUpdateInterval = 0.2
                self.motionManager.startDeviceMotionUpdates(to: self.motionQueue) { (motion, error) in
                    if let deviceMotion = motion{
                        let x = deviceMotion.gravity.x
                        let y = deviceMotion.gravity.y
                        if (fabs(y) >= fabs(x)) {
                            if (y >= 0) {
                                //UIDeviceOrientationPortraitUpsideDown;
                                camera.currentVideOrientation = .portraitUpsideDown
                            } else {
                                //UIDeviceOrientationPortrait;
                                camera.currentVideOrientation = .portrait
                            }
                        } else {
                            if (x >= 0) {
                                //UIDeviceOrientationLandscapeRight;    // Home to the left
                                camera.currentVideOrientation = .landscapeLeft
                            } else {
                                //UIDeviceOrientationLandscapeLeft;     // Home to the right
                                camera.currentVideOrientation = .landscapeRight
                            }
                        }
                    }
                }
            }
            else {
                /*
                 
                 Use the status bar orientation as the initial video orientation. Subsequent orientation changes are
                 handled by CameraViewController.viewWillTransition(to:with:).
                 */
                let statusBarOrientation = UIApplication.shared.statusBarOrientation
                let initialVideoOrientation: AVCaptureVideoOrientation = .portrait
                if statusBarOrientation != .unknown {
                    if let videoOrientation = AVCaptureVideoOrientation(interfaceOrientation: statusBarOrientation) {
                        self.camera.currentVideOrientation = videoOrientation
                    }
                    else{
                        self.camera.currentVideOrientation = initialVideoOrientation
                    }
                }
            }
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        sessionQueue.async {
            switch self.camera.setupResult {
            case .success:
                // Only setup observers and start the session running if setup succeeded.
                //self.addObservers()
                self.camera.startRunning()
                self.camera.showFocusOfInterestIndicator = true
                
            case .notAuthorized:
                DispatchQueue.main.async {
                    let changePrivacySetting = "VideoCamera doesn't have permission to use the camera, please change privacy settings"
                    let message = NSLocalizedString(changePrivacySetting, comment: "Alert message when the user has denied access to the camera")
                    let alertController = UIAlertController(title: "VideoCamera", message: message, preferredStyle: .alert)
                    
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                            style: .cancel,
                                                            handler: nil))
                    
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: "Alert button to open Settings"),
                                                            style: .`default`,
                                                            handler: { _ in
                                                                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                                                                          options: [:],
                                                                                          completionHandler: nil)
                    }))
                    
                    self.present(alertController, animated: true, completion: nil)
                }
                
            case .configurationFailed:
                DispatchQueue.main.async {
                    let alertMsg = "Alert message when something goes wrong during capture session configuration"
                    let message = NSLocalizedString("Unable to capture media", comment: alertMsg)
                    let alertController = UIAlertController(title: "VideoCamera", message: message, preferredStyle: .alert)
                    
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                            style: .cancel,
                                                            handler: nil))
                    
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
        
        sessionQueue.async {
            DispatchQueue.main.async {
                self.updateCameraParameterDisplay()
                if let timer = self.timer {
                    timer.invalidate()
                    self.timer = nil
                }
                self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.onTimerEvent(timer:)), userInfo: nil, repeats: true)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        sessionQueue.async {
            if self.camera.setupResult == .success {
                self.camera.stopRunning()
                //self.removeObservers()
            }
        }
        
        
        if let timer = self.timer {
            timer.invalidate()
            self.timer = nil
        }
        
        self.motionManager.stopDeviceMotionUpdates()
        
        super.viewWillDisappear(animated)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    func updateCameraParameterDisplay(){
        if let videoDeviceInput = self.camera.videoDeviceInput {
            let device = videoDeviceInput.device
            self.cameraParameterButtons[0].text1 = String(format: "%.2f", arguments: [device.exposureTargetBias])
            
            let exposureTime = Float(device.exposureDuration.value) / Float(device.exposureDuration.timescale)
            if !exposureTime.isNaN {
                if exposureTime >= 1 {
                    self.cameraParameterButtons[1].text1 = String(format: "%.4f", arguments: [exposureTime])
                }
                else{
                    let exposureDenominator = Int(1 / exposureTime)
                    self.cameraParameterButtons[1].text1 = "1/\(exposureDenominator)"
                }
            }
            
            self.cameraParameterButtons[2].text1 = String(format: "%.0f", arguments: [device.iso])
            switch (device.whiteBalanceMode) {
            case .autoWhiteBalance:
                self.cameraParameterButtons[3].text2 = NSLocalizedString("AWB", comment: "")
                break
            case .continuousAutoWhiteBalance:
                self.cameraParameterButtons[3].text2 = NSLocalizedString("AWB", comment: "")
                break
            case .locked:
                self.cameraParameterButtons[3].text2 = NSLocalizedString("WB", comment: "")
                break
            default:
                self.cameraParameterButtons[3].text2 = NSLocalizedString("WB", comment: "")
                break
            }
            
            let whiteBalanceGains = device.deviceWhiteBalanceGains
            if whiteBalanceGains.redGain <= device.maxWhiteBalanceGain
                && whiteBalanceGains.greenGain <= device.maxWhiteBalanceGain
                && whiteBalanceGains.blueGain <= device.maxWhiteBalanceGain
                && whiteBalanceGains.redGain >= 1
                && whiteBalanceGains.greenGain >= 1
                && whiteBalanceGains.blueGain >= 1 {
                let wb = device.temperatureAndTintValues(for: device.deviceWhiteBalanceGains)
                self.cameraParameterButtons[3].text1 = String(format: "%dK", Int(wb.temperature))
            }
            
            self.cameraParameterButtons[4].text1 = String(format: "%.2f", arguments: [device.lensPosition])
            self.cameraParameterButtons[5].text1 = String(format: "%.2f", arguments: [device.videoZoomFactor])
            
            self.batteryView.setBatteryLevelWithAnimation(false, forValue: UIDevice.batteryLevelInPercentage(UIDevice.current)(), inPercent: true)
        }
        
        switch self.camera.preferredVideoStabilizationMode {
        case .auto:
            self.lensButton.setImage(UIImage(named: "OIS"), for: .normal)
            let lensTitle = NSLocalizedString("Auto", comment: "")
            self.lensButton.setAttributedTitle(NSAttributedString(string: lensTitle, attributes: [NSAttributedString.Key.font:UIFont.systemFont(ofSize: 12), NSAttributedString.Key.foregroundColor:UIColor.white]), for: .normal)
            break
        case .standard:
            self.lensButton.setImage(UIImage(named: "OIS"), for: .normal)
            let lensTitle = NSLocalizedString("Standard", comment: "")
            self.lensButton.setAttributedTitle(NSAttributedString(string: lensTitle, attributes: [NSAttributedString.Key.font:UIFont.systemFont(ofSize: 12), NSAttributedString.Key.foregroundColor:UIColor.white]), for: .normal)
            break
        case .cinematic:
            self.lensButton.setImage(UIImage(named: "OIS"), for: .normal)
            let lensTitle = NSLocalizedString("Cinematic", comment: "")
            self.lensButton.setAttributedTitle(NSAttributedString(string: lensTitle, attributes: [NSAttributedString.Key.font:UIFont.systemFont(ofSize: 12), NSAttributedString.Key.foregroundColor:UIColor.white]), for: .normal)
            break
        case .off:
            self.lensButton.setImage(UIImage(named: "OISoff"), for: .normal)
            let lensTitle = NSLocalizedString("Off", comment: "")
            self.lensButton.setAttributedTitle(NSAttributedString(string: lensTitle, attributes: [NSAttributedString.Key.font:UIFont.systemFont(ofSize: 12), NSAttributedString.Key.foregroundColor:UIColor.white]), for: .normal)
            break
        default:
            self.lensButton.setImage(UIImage(named: "OISoff"), for: .normal)
            let lensTitle = NSLocalizedString("Off", comment: "")
            self.lensButton.setAttributedTitle(NSAttributedString(string: lensTitle, attributes: [NSAttributedString.Key.font:UIFont.systemFont(ofSize: 12), NSAttributedString.Key.foregroundColor:UIColor.white]), for: .normal)
            break
        }
        
        switch self.camera.torchMode {
        case .auto:
            self.flashButton.setImage(UIImage(named: "flash_auto"), for: .normal)
            break
        case .on:
            self.flashButton.setImage(UIImage(named: "flash_on"), for: .normal)
            break
        case .off:
            self.flashButton.setImage(UIImage(named: "flash_off"), for: .normal)
            break
        default:
            self.flashButton.setImage(UIImage(named: "flash_off"), for: .normal)
            break
        }
    }
    
    func updateSettingsButton(){
        DispatchQueue.main.async {
            let format = self.camera.videoFormat
            let formatStr:String = {
                if format.0 == 3840 {
                    return "4k"
                }
                if format.0 == 1920{
                    return "1080p"
                }
                return "720p"
            }()
            let settingsTitle = NSAttributedString(string: "\(formatStr) \(format.2)", attributes: [NSAttributedString.Key.font:UIFont.systemFont(ofSize: 12), NSAttributedString.Key.foregroundColor:UIColor.white])
            self.settingsButton.setAttributedTitle(settingsTitle, for: .normal)
        }
    }
    
    func recalcConstraints(){
        let isLandscape = UIDevice.current.orientation == .landscapeLeft ||  UIDevice.current.orientation == .landscapeRight
        let isLandscapeRight = UIDevice.current.orientation == .landscapeRight
        
        
        NSLayoutConstraint.deactivate(landscapeRightConstraints)
        NSLayoutConstraint.deactivate(landscapeConstraints)
        NSLayoutConstraint.deactivate(portraitConstraints)
        
        self.cameraBottom.reconfigureLayout()
        
        landscapeRightConstraints.forEach { (constraint) in
            if isLandscapeRight {
                constraint.priority = .defaultHigh
            }
            else{
                constraint.priority = .defaultLow
            }
        }
        
        landscapeConstraints.forEach { (constraint) in
            if !isLandscapeRight {
                constraint.priority = .defaultHigh
            }
            else{
                constraint.priority = .defaultLow
            }
        }
        
        if(isLandscape){
            NSLayoutConstraint.deactivate(portraitConstraints)
            if(isLandscapeRight){
                NSLayoutConstraint.activate(landscapeConstraints)
                NSLayoutConstraint.activate(landscapeRightConstraints)
            }
            else{
                NSLayoutConstraint.deactivate(landscapeRightConstraints)
                NSLayoutConstraint.activate(landscapeConstraints)
            }
        }
        else{
            NSLayoutConstraint.deactivate(landscapeRightConstraints)
            NSLayoutConstraint.deactivate(landscapeConstraints)
            NSLayoutConstraint.activate(portraitConstraints)
        }
        
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        self.recalcConstraints()
        self.view.setNeedsUpdateConstraints()
        
        let deviceOrientation = UIDevice.current.orientation
        
        if let videoPreviewLayerConnection = previewView.videoPreviewLayer.connection {
            
            guard let newVideoOrientation = AVCaptureVideoOrientation(deviceOrientation: deviceOrientation),
                deviceOrientation.isPortrait || deviceOrientation.isLandscape else {
                    return
            }
            
            videoPreviewLayerConnection.videoOrientation = newVideoOrientation
            
            if self.motionManager.isDeviceMotionAvailable == false || self.motionManager.isDeviceMotionActive == false {
                /*
                 If device motion is not available
                 Use the status bar orientation as the initial video orientation. Subsequent orientation changes are
                 handled by CameraViewController.viewWillTransition(to:with:).
                 */
                let statusBarOrientation = UIApplication.shared.statusBarOrientation
                let initialVideoOrientation: AVCaptureVideoOrientation = .portrait
                if statusBarOrientation != .unknown {
                    if let videoOrientation = AVCaptureVideoOrientation(interfaceOrientation: statusBarOrientation) {
                        self.camera.currentVideOrientation = videoOrientation
                    }
                    else{
                        self.camera.currentVideOrientation = initialVideoOrientation
                    }
                }
            }
        }
    }

    //////////////////////////////////////////////////////////////////////////////////
    
    private func addObservers(){
        let keyValueObservation = self.camera.observe(\.isRecording) { (_, change) in
            if self.camera.isRecording {
                self.recordTimeLabel.isRecording = true
                self.cameraBottom.recordButton.setBackgroundImage(UIImage.init(named: "cameraRecordStop"), for: .normal)
            }
            else{
                self.recordTimeLabel.isRecording = false
                self.cameraBottom.recordButton.setBackgroundImage(UIImage.init(named: "cameraRecord"), for: .normal)
            }
        }
        
        keyValueObservations.append(keyValueObservation)
        
        if let videoDeviceInput = self.camera.videoDeviceInput {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(subjectAreaDidChange),
                                                   name: .AVCaptureDeviceSubjectAreaDidChange,
                                                   object: videoDeviceInput.device)
        }
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionRuntimeError),
                                               name: .AVCaptureSessionRuntimeError,
                                               object: self.camera)
        
        /*
         A session can only run when the app is full screen. It will be interrupted
         in a multi-app layout, introduced in iOS 9, see also the documentation of
         AVCaptureSessionInterruptionReason. Add observers to handle these session
         interruptions and show a preview is paused message. See the documentation
         of AVCaptureSessionWasInterruptedNotification for other interruption reasons.
         */
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionWasInterrupted),
                                               name: .AVCaptureSessionWasInterrupted,
                                               object: self.previewView.session)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionInterruptionEnded),
                                               name: .AVCaptureSessionInterruptionEnded,
                                               object: self.previewView.session)
    }
    
    
    deinit {
        keyValueObservations.forEach { (keyValueObservation) in
            keyValueObservation.invalidate()
        }
        keyValueObservations.removeAll()
    }
    
}

