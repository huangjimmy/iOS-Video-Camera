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

class ViewController: UIViewController {

    var portraitConstraints:[NSLayoutConstraint] = []
    var landscapeConstraints:[NSLayoutConstraint] = []
    var landscapeRightConstraints:[NSLayoutConstraint] = []
    
    private var previewView:PreviewView!
    
    private let camera = CameraManager.sharedInstance
    
    private let sessionQueue = DispatchQueue(label: "session queue") // Communicate with the session and other session objects on this queue.
    
    private var cameraBottom: CameraBottomControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.previewView = PreviewView()
        self.previewView.backgroundColor = .black
        self.previewView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.previewView);
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[v]-0-|", options: .init(rawValue: 0), metrics: nil, views: ["v":self.previewView]))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[v]-0-|", options: .init(rawValue: 0), metrics: nil, views: ["v":self.previewView]))
     
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
        sessionQueue.async {
            self.camera.configureSession(with: self.previewView)
        }
        
        let isLandscape = UIDevice.current.orientation == .landscapeLeft ||  UIDevice.current.orientation == .landscapeRight
        let isLandscapeRight = UIDevice.current.orientation == .landscapeRight
        
        cameraBottom = CameraBottomControl()
        cameraBottom.translatesAutoresizingMaskIntoConstraints = false
        cameraBottom.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.4)
        self.view.addSubview(cameraBottom)
        
        portraitConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[v]-0-|", options: .init(rawValue: 0), metrics: nil, views: ["v":cameraBottom]))
        portraitConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[v(100)]-|", options: .init(rawValue: 0), metrics: nil, views: ["v":cameraBottom]))
        
        landscapeConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[v]-0-|", options: .init(rawValue: 0), metrics: nil, views: ["v":cameraBottom]))
        landscapeConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:[v(100)]-|", options: .init(rawValue: 0), metrics: nil, views: ["v":cameraBottom]))
        landscapeRightConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-[v(100)]", options: .init(rawValue: 0), metrics: nil, views: ["v":cameraBottom]))
        
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
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.recalcConstraints()
        self.view.setNeedsUpdateConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        sessionQueue.async {
            switch self.camera.setupResult {
            case .success:
                // Only setup observers and start the session running if setup succeeded.
                //self.addObservers()
                self.camera.startRunning()
                
            case .notAuthorized:
                DispatchQueue.main.async {
                    let changePrivacySetting = "AVCam doesn't have permission to use the camera, please change privacy settings"
                    let message = NSLocalizedString(changePrivacySetting, comment: "Alert message when the user has denied access to the camera")
                    let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
                    
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
                    let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
                    
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                            style: .cancel,
                                                            handler: nil))
                    
                    self.present(alertController, animated: true, completion: nil)
                }
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
        
        super.viewWillDisappear(animated)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
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
        }
    }

}

