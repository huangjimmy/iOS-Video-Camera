//
//  FormatSettingsView.swift
//  VideoCamera
//
//  Created by jimmy on 2019/4/19.
//  Copyright © 2019 huangsj. All rights reserved.
//

import UIKit
import AVFoundation

class FormatSettingsView: UIView {
    
    var selectedResolution:(Int, Int) = (0,0)
    var selectedFps:Int = 0
    var selectedMicrophone:Int = 0
    
    var is4ksupported = false
    var is1080psupported = false
    
    var maxFps4k = 0
    var maxFps1080p = 0
    var maxFps720p = 0
    
    var resolutionLabel:UILabel
    var fpsLabel:UILabel
    var microphoneLabel:UILabel
    
    //available resoltuion: 720p(1280x720) 1080p(1920x1080) 4k(3840x2160)
    var resolutionSettingSegment: UISegmentedControl
    //available fps: 24 30 48 50 60 120 240
    var fpsSettingsButtons:[UIButton]
    //builtin or builtin with external bluetooth
    var microphoneSegment:UISegmentedControl
    
    required init?(coder aDecoder: NSCoder) {
        
        resolutionLabel = UILabel()
        fpsLabel = UILabel()
        microphoneLabel = UILabel()
        
        resolutionSettingSegment = UISegmentedControl()
        fpsSettingsButtons = []
        microphoneSegment = UISegmentedControl()
        
        super.init(coder: aDecoder)
        
        createSubviews()
    }
    
    override init(frame: CGRect) {
        
        resolutionLabel = UILabel()
        fpsLabel = UILabel()
        microphoneLabel = UILabel()
        
        resolutionSettingSegment = UISegmentedControl()
        fpsSettingsButtons = []
        microphoneSegment = UISegmentedControl()
        
        super.init(frame: frame)
        
        createSubviews()
    }
    
    init(){
        
        resolutionLabel = UILabel()
        fpsLabel = UILabel()
        microphoneLabel = UILabel()
        
        resolutionSettingSegment = UISegmentedControl()
        fpsSettingsButtons = []
        microphoneSegment = UISegmentedControl()
        
        super.init(frame: .zero)
        
        createSubviews()
    }
    
    private func createSubviews(){
        self.resolutionLabel.text = NSLocalizedString("Format", comment: "4k/1080p/720p")
        self.fpsLabel.text = NSLocalizedString("Frame rate", comment: "24/30/48/50/60/120/240")
        self.microphoneLabel.text = NSLocalizedString("Microphone", comment: "")
        
        self.resolutionLabel.backgroundColor = .clear
        self.resolutionLabel.textColor = .white
        
        self.fpsLabel.backgroundColor = .clear
        self.fpsLabel.textColor = .white
        
        self.microphoneLabel.backgroundColor = .clear
        self.microphoneLabel.textColor = .white
        
        self.resolutionLabel.frame = CGRect(x: 16, y: 25, width: 200, height: 17)
        self.resolutionLabel.adjustsFontSizeToFitWidth = true
        
        self.fpsLabel.frame = CGRect(x: 16, y: 90, width: 200, height: 17)
        self.fpsLabel.adjustsFontSizeToFitWidth = true
        
        self.microphoneLabel.frame = CGRect(x: 16, y: 196, width: 200, height: 17)
        self.microphoneLabel.adjustsFontSizeToFitWidth = true
        
        self.resolutionSettingSegment.frame = CGRect(x: 16, y: 53, width: 288, height: 28)
        self.microphoneSegment.frame = CGRect(x: 16, y: 222, width: 288, height: 28)
        
        self.resolutionSettingSegment.insertSegment(withTitle: NSLocalizedString("720p", comment: ""), at: 0, animated: false)
        self.resolutionSettingSegment.insertSegment(withTitle: NSLocalizedString("1080p", comment: ""), at: 1, animated: false)
        self.resolutionSettingSegment.insertSegment(withTitle: NSLocalizedString("4K", comment: ""), at: 2, animated: false)
        self.resolutionSettingSegment.selectedSegmentIndex = 0
        
        self.microphoneSegment.insertSegment(withTitle: NSLocalizedString("Builtin", comment: ""), at: 0, animated: false)
        self.microphoneSegment.insertSegment(withTitle: NSLocalizedString("Builtin and Bluetooth", comment: ""), at: 1, animated: false)
        self.microphoneSegment.selectedSegmentIndex = 0
        
        self.fpsSettingsButtons = [24,30,48,50,60,120,240].map({ (fps) -> UIButton in
            let button = UIButton(type: .custom)
            button.setTitle("\(fps)", for: .normal)
            button.tag = fps
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.white.cgColor
            return button
        })
        
        self.addSubview(self.resolutionLabel)
        self.addSubview(self.fpsLabel)
        self.addSubview(self.microphoneLabel)
        
        self.addSubview(self.resolutionSettingSegment)
        self.addSubview(self.microphoneSegment)
        
        for i in 0...6 {
            let button = self.fpsSettingsButtons[i]
            button.frame = CGRect(x: 16+(i%5)*60, y: 119+39*(i/5), width: 48, height: 26)
            button.addTarget(self, action: #selector(chooseFps(_:)), for: .touchUpInside)
            
            self.addSubview(button)
        }
        
        self.resolutionSettingSegment.addTarget(self, action: #selector(chooseResolution(_:)), for: .valueChanged)
        self.microphoneSegment.addTarget(self, action: #selector(chooseMicrophone(_:)), for: .valueChanged)
        
        self.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.75)
    }
    
    func loadFpsButtons(){
        
        let camera = CameraManager.sharedInstance
        let format = camera.videoFormat
        let selectedFps = format.2
        
        let fps = [24,30,48,50,60,120,240]
        for i in 0...6 {
            let button = self.fpsSettingsButtons[i]
            if fps[i] == selectedFps {
                button.layer.borderColor = UIColor(red: 0xFF/255.0, green: 0x95/255.0, blue: 0, alpha: 1.0).cgColor
                button.setTitleColor(UIColor(red: 0xFF/255.0, green: 0x95/255.0, blue: 0, alpha: 1.0), for: .normal)
            }
            else {
                button.layer.borderColor = UIColor.white.cgColor
                button.setTitleColor(.white, for: .normal)
            }
            
            if format.0 >= 3840 {
                if fps[i] > maxFps4k {
                    button.isUserInteractionEnabled = false
                    button.layer.borderColor = UIColor.gray.cgColor
                    button.setTitleColor(.gray, for: .normal)
                }
                else {
                    button.isUserInteractionEnabled = true
                }
            }
            else if format.0 >= 1920 {
                if fps[i] > maxFps1080p {
                    button.isUserInteractionEnabled = false
                    button.layer.borderColor = UIColor.gray.cgColor
                    button.setTitleColor(.gray, for: .normal)
                }
                else {
                    button.isUserInteractionEnabled = true
                }
            }
            else if format.0 >= 1280 {
                if fps[i] > maxFps720p {
                    button.isUserInteractionEnabled = false
                    button.layer.borderColor = UIColor.gray.cgColor
                    button.setTitleColor(.gray, for: .normal)
                }
                else {
                    button.isUserInteractionEnabled = true
                }
            }
        }
    }
    
    func updateFpsButtons(){
        
        let format = self.selectedResolution
        var selectedFps = self.selectedFps
        
        let fps = [24,30,48,50,60,120,240]
        for i in 0...6 {
            let button = self.fpsSettingsButtons[i]
            
            if fps[i] < selectedFps && fps[i] >= maxFps4k && self.resolutionSettingSegment.selectedSegmentIndex == 2 {
                selectedFps = fps[i]
                self.selectedFps = selectedFps
            }
            else if fps[i] < selectedFps && fps[i] >= maxFps1080p && self.resolutionSettingSegment.selectedSegmentIndex == 1 {
                selectedFps = fps[i]
                self.selectedFps = selectedFps
            }
            else if fps[i] < selectedFps && fps[i] >= maxFps720p && self.resolutionSettingSegment.selectedSegmentIndex == 0 {
                selectedFps = fps[i]
                self.selectedFps = selectedFps
            }
            
            if fps[i] == selectedFps {
                button.layer.borderColor = UIColor(red: 0xFF/255.0, green: 0x95/255.0, blue: 0, alpha: 1.0).cgColor
                button.setTitleColor(UIColor(red: 0xFF/255.0, green: 0x95/255.0, blue: 0, alpha: 1.0), for: .normal)
            }
            else {
                button.layer.borderColor = UIColor.white.cgColor
                button.setTitleColor(.white, for: .normal)
            }
            
            if format.0 >= 3840 {
                if fps[i] > maxFps4k {
                    button.isUserInteractionEnabled = false
                    button.layer.borderColor = UIColor.gray.cgColor
                    button.setTitleColor(.gray, for: .normal)
                }
                else {
                    button.isUserInteractionEnabled = true
                }
            }
            else if format.0 >= 1920 {
                if fps[i] > maxFps1080p {
                    button.isUserInteractionEnabled = false
                    button.layer.borderColor = UIColor.gray.cgColor
                    button.setTitleColor(.gray, for: .normal)
                }
                else {
                    button.isUserInteractionEnabled = true
                }
            }
            else if format.0 >= 1280 {
                if fps[i] > maxFps720p {
                    button.isUserInteractionEnabled = false
                    button.layer.borderColor = UIColor.gray.cgColor
                    button.setTitleColor(.gray, for: .normal)
                }
                else {
                    button.isUserInteractionEnabled = true
                }
            }
        }
    }
    
    public func loadSettingsFromCamera(){
        
        let camera = CameraManager.sharedInstance
        let supportedFormats:[AVCaptureDevice.DeviceType:[(CMVideoDimensions, Int, Int)]] = camera.currentCameraSupportedFormats
        
        maxFps4k = 0
        maxFps1080p = 0
        maxFps720p = 0
        
        supportedFormats.forEach { arg0 in
            
            let (_, value) = arg0
            value.forEach({ (arg1) in
                if arg1.0.width >= 3840 {
                    if maxFps4k < arg1.2 {
                        maxFps4k = arg1.2
                    }
                }
                else if arg1.0.width >= 1920 {
                    if maxFps1080p < arg1.2 {
                        maxFps1080p = arg1.2
                    }
                }
                else if arg1.0.width >= 1280 {
                    if maxFps720p < arg1.2 {
                        maxFps720p = arg1.2
                    }
                }
            })
        }
        
        is4ksupported = supportedFormats.first { (arg0) -> Bool in
            
            let (_, value) = arg0
            return value.first(where: { (arg1) -> Bool in
                return arg1.0.width == 3840
            }) != nil
            } != nil
        
        is1080psupported = supportedFormats.first { (arg0) -> Bool in
            
            let (_, value) = arg0
            return value.first(where: { (arg1) -> Bool in
                return arg1.0.width == 1920
            }) != nil
        } != nil
        
        if !is4ksupported {
            self.resolutionSettingSegment.setEnabled(false, forSegmentAt: 2)
        }
        
        if !is1080psupported {
            self.resolutionSettingSegment.setEnabled(false, forSegmentAt: 1)
        }
        
        let format = camera.videoFormat
        if format.0 >= 3840 && format.1 >= 2160 {
            self.resolutionSettingSegment.selectedSegmentIndex = 2
            self.selectedResolution = (3840, 2160)
        }
        else if format.0 >= 1920 && format.1 >= 1080 {
            self.resolutionSettingSegment.selectedSegmentIndex = 1
            self.selectedResolution = (1920, 1080)
        }
        else if format.0 >= 1280 && format.1 >= 720 {
            self.resolutionSettingSegment.selectedSegmentIndex = 0
            self.selectedResolution = (1280, 720)
        }
        
        self.selectedFps = format.2
        
        self.loadFpsButtons()
        
        if CameraManager.sharedInstance.useBluetoothMicrophone {
            self.microphoneSegment.selectedSegmentIndex = 1
        }
        else{
            self.microphoneSegment.selectedSegmentIndex = 0
        }
    }
    
    public func saveSettingsToCamera(){
        let camera = CameraManager.sharedInstance
        camera.videoFormat = (self.selectedResolution.0, self.selectedResolution.1, self.selectedFps)
        camera.useBluetoothMicrophone = self.selectedMicrophone == 1
    }
    
    @objc func chooseResolution(_ sender: Any){
        
        if self.resolutionSettingSegment.selectedSegmentIndex == 2 && !is4ksupported {
            DispatchQueue.main.async {
                self.resolutionSettingSegment.selectedSegmentIndex = 0
                self.chooseResolution(sender)
            }
        }
        else if self.resolutionSettingSegment.selectedSegmentIndex == 1 && !is1080psupported {
            DispatchQueue.main.async {
                self.resolutionSettingSegment.selectedSegmentIndex = 0
                self.chooseResolution(sender)
            }
        }
        
        self.selectedResolution = {
            if self.resolutionSettingSegment.selectedSegmentIndex == 0{
                return (1280,720)
            }
            if self.resolutionSettingSegment.selectedSegmentIndex == 1{
                return (1920,1080)
            }
            if self.resolutionSettingSegment.selectedSegmentIndex == 2{
                return (3840,2160)
            }
            return (0,0)
        }()
        
        self.updateFpsButtons()
    }
    
    @objc func chooseMicrophone(_ sender: Any){
        self.selectedMicrophone = self.microphoneSegment.selectedSegmentIndex
    }
    
    @objc func chooseFps(_ sender: Any){
        let selectedFps = (sender as! UIButton).tag
        
        let camera = CameraManager.sharedInstance
        var supportedFormats:[AVCaptureDevice.DeviceType:[(CMVideoDimensions, Int, Int)]] = [:]
        
        switch (camera.videoDeviceInput.device.position){
        case .back:
            supportedFormats = camera.backCameraSupportedFormats
            break
        case .front:
            supportedFormats = camera.frontCameraSupportedFormats
            break
        case .unspecified:
            break
        @unknown default:
            break
        }
        
        let isFpsSupported = supportedFormats.first { (arg0) -> Bool in
            
            let (_, value) = arg0
            return value.first(where: { (arg1) -> Bool in
                return arg1.0.width == self.selectedResolution.0 && arg1.0.height == self.selectedResolution.1 && selectedFps <= arg1.2
            }) != nil
        } != nil
        
        if (!isFpsSupported){
            return;
        }
        
        self.selectedFps = selectedFps
        
        self.updateFpsButtons()
    }
}
