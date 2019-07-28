//
//  AudioLevelIndicatorView.swift
//  VideoCamera
//
//  Created by jimmy on 2019/7/28.
//  Copyright © 2019 huangsj. All rights reserved.
//

import UIKit

class AudioLevelIndicatorView: UIView {
    
    private let levelBackgroundLayer = CAGradientLayer()
    private let levelMask = CALayer()
    private let avgMask = CALayer()
    private let peakMask = CALayer()
    
    private var _averageLevel: Float = 0.0
    private var _peakLevel: Float = 0.0
    
    public var averageLevel: Float {
        get{
            return _averageLevel
        }
        set{
            _averageLevel = newValue
        }
    }
    
    public var peakLevel: Float{
        get{
            return _peakLevel
        }
        set{
            _peakLevel = newValue
        }
    }
    
    private func initSubviews(){
        levelBackgroundLayer.colors = [UIColor(red: 0x4c/255.0, green: 0xd9/255.0, blue: 0x64/255.0, alpha: 1).cgColor, UIColor.red.cgColor]
        levelBackgroundLayer.startPoint = CGPoint(x: 0, y: 1)
        levelBackgroundLayer.endPoint = CGPoint.zero
        self.layer.addSublayer(levelBackgroundLayer)
        
        avgMask.backgroundColor = UIColor.white.cgColor
        peakMask.backgroundColor = UIColor.white.cgColor
        levelBackgroundLayer.mask = levelMask
        levelMask.addSublayer(avgMask)
        levelMask.addSublayer(peakMask)
        
        self.backgroundColor = UIColor(red: 0x33/255.0, green: 0x33/255.0, blue: 0x33/255.0, alpha: 0.7)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initSubviews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initSubviews()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.levelBackgroundLayer.frame = self.layer.bounds
        let width = self.frame.size.width
        let height = self.frame.size.height
        self.avgMask.frame = CGRect(x: 0, y: CGFloat(1.0-averageLevel)*height, width: width, height: CGFloat(averageLevel)*height)
        self.peakMask.frame = CGRect(x: 0, y: CGFloat(1.0-peakLevel)*height, width: width, height: 2)
    }

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
