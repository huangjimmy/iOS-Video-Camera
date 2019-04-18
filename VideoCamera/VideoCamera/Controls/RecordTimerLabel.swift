//
//  RecordTimerLabel.swift
//  VideoCamera
//
//  Created by jimmy on 2019/4/17.
//  Copyright © 2019 huangsj. All rights reserved.
//

import Foundation
import UIKit

class RecordTimerLabel: UILabel {
    
    var redDot:UIView
    
    var _isRecording: Bool = false
    
    var timer:Timer?
    
    var recordStartTime = 0.0
    
    init(){
        
        redDot = UIView()
        redDot.translatesAutoresizingMaskIntoConstraints = false
        redDot.layer.cornerRadius = 2
        redDot.backgroundColor = .red
        
        super.init(frame: .zero)
        
        self.addSubview(redDot)
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[v(4)]", options: .alignAllCenterY, metrics: nil, views: ["v":redDot]))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-7-[v(4)]", options: .init(rawValue: 0), metrics: nil, views: ["v":redDot]))
        self.textColor = .white
        self.backgroundColor = .clear
        self.text = "00:00:00"
        self.textAlignment = .right
        self.redDot.isHidden = true
        
    }
    
    override init(frame: CGRect) {
        
        redDot = UIView()
        redDot.translatesAutoresizingMaskIntoConstraints = false
        redDot.layer.cornerRadius = 2
        redDot.backgroundColor = .red
        
        super.init(frame: frame)
        
        self.addSubview(redDot)
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[v(4)]", options: .alignAllCenterY, metrics: nil, views: ["v":redDot]))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-7-[v(4)]", options: .init(rawValue: 0), metrics: nil, views: ["v":redDot]))
        self.textColor = .white
        self.backgroundColor = .clear
        self.text = "00:00:00"
        self.textAlignment = .right
        self.redDot.isHidden = true
    }
    
    required init?(coder aCoder:NSCoder) {
        
        redDot = UIView()
        redDot.translatesAutoresizingMaskIntoConstraints = false
        redDot.layer.cornerRadius = 2
        redDot.backgroundColor = .red
        
        super.init(coder: aCoder)
        
        self.addSubview(redDot)
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[v(4)]", options: .alignAllCenterY, metrics: nil, views: ["v":redDot]))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-7-[v(4)]", options: .init(rawValue: 0), metrics: nil, views: ["v":redDot]))
        self.textColor = .white
        self.backgroundColor = .clear
        self.text = "00:00:00"
        self.textAlignment = .right
        self.redDot.isHidden = true
        
    }
    
    public var isRecording: Bool {
        get {
            return _isRecording
        }
        set {
            if(_isRecording != newValue){
                _isRecording = newValue
                
                if let timer = self.timer {
                    timer.invalidate()
                    self.timer = nil
                }
                
                if _isRecording {
                    self.text = "00:00:00"
                    recordStartTime = Date().timeIntervalSince1970
                    self.timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(onTimerEvent(timer:)), userInfo: nil, repeats: true)
                }
                else {
                    self.text = "00:00:00"
                    self.redDot.isHidden = true
                }
            }
        }
    }
    
    @objc func onTimerEvent(timer: Timer) {
        self.redDot.isHidden = !self.redDot.isHidden
        let currentTime = Date().timeIntervalSince1970
        let recordTime = currentTime - recordStartTime
        let hrs = Int(recordTime) / 3600
        let mins = (Int(recordTime)-hrs*3600) / 60
        let secs = Int(recordTime) % 60
        self.text = String(format: "%02d:%02d:%02d", hrs, mins, secs)
    }
}
