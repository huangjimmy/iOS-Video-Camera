//
//  CameraBottomControl.swift
//  VideoCamera
//
//  Created by jimmy on 2019/4/17.
//  Copyright © 2019 huangsj. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class CameraBottomControl: UIView {
    let cameraRollButton: UIButton
    let recordButton: UIButton
    let changeCameraButton: UIButton
    
    var _isRecording: Bool = false
    var isRecording: Bool {
        get {
            return _isRecording
        }
        set{
            _isRecording = newValue
            if(_isRecording){
                self.recordButton.setBackgroundImage(UIImage.init(named: "cameraRecordStop"), for: .normal)
            }
            else{
                self.recordButton.setBackgroundImage(UIImage.init(named: "cameraRecord"), for: .normal)
            }
        }
    }
    
    var portraitConstraints:[NSLayoutConstraint] = []
    var landscapeConstraints:[NSLayoutConstraint] = []
    
    override init(frame: CGRect) {
        cameraRollButton = UIButton.init(type: .custom)
        recordButton = UIButton.init(type: .custom)
        changeCameraButton = UIButton.init(type: .custom)
        
        super.init(frame: frame)
        initSubViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        cameraRollButton = UIButton.init(type: .custom)
        recordButton = UIButton.init(type: .custom)
        changeCameraButton = UIButton.init(type: .custom)
        
        super.init(coder: aDecoder)
        initSubViews()
    }
    
    func initSubViews() {
        
        cameraRollButton.translatesAutoresizingMaskIntoConstraints = false
        cameraRollButton.backgroundColor = UIColor.white
        
        self.addSubview(cameraRollButton)
        
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[v(50)]", options: .init(rawValue: 0), metrics: nil, views: ["v":self.cameraRollButton]))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[v(50)]", options: .init(rawValue: 0), metrics: nil, views: ["v":self.cameraRollButton]))
        
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(recordButton)
        
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[v(68)]", options: .init(rawValue: 0), metrics: nil, views: ["v":self.recordButton]))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[v(68)]", options: .init(rawValue: 0), metrics: nil, views: ["v":self.recordButton]))
        self.addConstraint(NSLayoutConstraint.init(item: self.recordButton, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0))
        self.addConstraint(NSLayoutConstraint.init(item: self.recordButton, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0))
        
        changeCameraButton.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(changeCameraButton)
        
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[v(50)]", options: .init(rawValue: 0), metrics: nil, views: ["v":self.changeCameraButton]))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[v(62)]", options: .init(rawValue: 0), metrics: nil, views: ["v":self.changeCameraButton]))
        
        self.isRecording = false
        
        self.changeCameraButton.setBackgroundImage(UIImage.init(named: "changeCamera"), for: .normal)
        
        portraitConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-16-[v]", options: .init(rawValue: 0), metrics: nil, views: ["v":self.cameraRollButton]))
        portraitConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-25-[v]-25-|", options: .init(rawValue: 0), metrics: nil, views: ["v":self.cameraRollButton]))
        portraitConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:[v]-16-|", options: .init(rawValue: 0), metrics: nil, views: ["v":self.changeCameraButton]))
        portraitConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-19-[v]-19-|", options: .init(rawValue: 0), metrics: nil, views: ["v":self.changeCameraButton]))
        
        landscapeConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[v]-16-|", options: .init(rawValue: 0), metrics: nil, views: ["v":self.cameraRollButton]))
        landscapeConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-25-[v]-25-|", options: .init(rawValue: 0), metrics: nil, views: ["v":self.cameraRollButton]))
        landscapeConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-16-[v]", options: .init(rawValue: 0), metrics: nil, views: ["v":self.changeCameraButton]))
        landscapeConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-25-[v]-25-|", options: .init(rawValue: 0), metrics: nil, views: ["v":self.changeCameraButton]))
        
        let isLandscape = UIDevice.current.orientation == .landscapeLeft ||  UIDevice.current.orientation == .landscapeRight
        
        var allConstraints:[NSLayoutConstraint] = []
        allConstraints.append(contentsOf: landscapeConstraints)
        allConstraints.append(contentsOf: portraitConstraints);
        
        self.addConstraints(portraitConstraints)
        self.addConstraints(landscapeConstraints)
        
        NSLayoutConstraint.deactivate(allConstraints)
        if(isLandscape == false){
            NSLayoutConstraint.activate(portraitConstraints)
        }
        else{
            NSLayoutConstraint.activate(landscapeConstraints)
        }
    
    }
    
    
    
    public func reconfigureLayout(){
        
        let isLandscape = UIDevice.current.orientation == .landscapeLeft ||  UIDevice.current.orientation == .landscapeRight

        var allConstraints:[NSLayoutConstraint] = []
        allConstraints.append(contentsOf: landscapeConstraints)
        allConstraints.append(contentsOf: portraitConstraints);
        NSLayoutConstraint.deactivate(allConstraints)
        
        if(isLandscape == false){
            NSLayoutConstraint.activate(portraitConstraints)
        }
        else{
            NSLayoutConstraint.activate(landscapeConstraints)
        }
    }
    
    public func reload(){
        let camera = CameraManager.sharedInstance
        if let device = camera.videoDeviceInput?.device {
            DispatchQueue.main.async {
                if device.position == .back {
                    switch device.deviceType {
                    case .builtInDualCamera:
                        self.changeCameraButton.setBackgroundImage(UIImage.init(named: "dualcam"), for: .normal)
                        break
                    case .builtInWideAngleCamera:
                        self.changeCameraButton.setBackgroundImage(UIImage.init(named: "backwidecam"), for: .normal)
                        break
                    case AVCaptureDevice.DeviceType.builtInTelephotoCamera:
                        self.changeCameraButton.setBackgroundImage(UIImage.init(named: "backtelecam"), for: .normal)
                        break
                    case AVCaptureDevice.DeviceType.builtInTrueDepthCamera:
                        self.changeCameraButton.setBackgroundImage(UIImage.init(named: "changeCamera"), for: .normal)
                        break
                    default:
                        self.changeCameraButton.setBackgroundImage(UIImage.init(named: "changeCamera"), for: .normal)
                        break
                    }
                }
                else if device.position == .front {
                    switch device.deviceType {
                    case .builtInDualCamera:
                        self.changeCameraButton.setBackgroundImage(UIImage.init(named: "frontcam"), for: .normal)
                        break
                    case .builtInWideAngleCamera:
                        self.changeCameraButton.setBackgroundImage(UIImage.init(named: "frontcam"), for: .normal)
                        break
                    case AVCaptureDevice.DeviceType.builtInTelephotoCamera:
                        self.changeCameraButton.setBackgroundImage(UIImage.init(named: "frontcam"), for: .normal)
                        break
                    case AVCaptureDevice.DeviceType.builtInTrueDepthCamera:
                        self.changeCameraButton.setBackgroundImage(UIImage.init(named: "frontcam"), for: .normal)
                        break
                    default:
                        self.changeCameraButton.setBackgroundImage(UIImage.init(named: "frontcam"), for: .normal)
                        break
                    }
                }
                else {
                    self.changeCameraButton.setBackgroundImage(UIImage.init(named: "changeCamera"), for: .normal)
                }
            }
        }
    }
}
