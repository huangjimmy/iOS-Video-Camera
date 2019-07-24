//
//  UIVideoResolutionFPSCellView.swift
//  VideoCamera
//
//  Created by jimmy on 2019/7/22.
//  Copyright © 2019 huangsj. All rights reserved.
//

import UIKit

class UIVideoResolutionFPSCellView: UICollectionViewCell {

    let roundRect:UIView
    let resolutionLabel:UILabel
    let fpsLabel:UILabel
    
    required init?(coder aDecoder: NSCoder) {
        roundRect = UIView(frame: CGRect(x: 9, y: 9, width: 68, height: 68))
        resolutionLabel = UILabel(frame: CGRect(x: 9, y: 9, width: 68, height: 34))
        fpsLabel = UILabel(frame: CGRect(x: 9, y: 9+34, width: 68, height: 34))
        
        super.init(coder: aDecoder)
        
        self.setupViews()
    }
    
    override init(frame: CGRect) {
        roundRect = UIView(frame: CGRect(x: 9, y: 9, width: 68, height: 68))
        resolutionLabel = UILabel(frame: CGRect(x: 9, y: 9, width: 68, height: 34))
        fpsLabel = UILabel(frame: CGRect(x: 9, y: 9+34, width: 68, height: 34))
        
        super.init(frame: frame)
        
        self.setupViews()
    }
    
    func setupViews(){
        self.backgroundColor = .clear
        roundRect.backgroundColor = .clear
        roundRect.layer.cornerRadius = 8
        roundRect.layer.borderWidth = 1
        roundRect.layer.borderColor = UIColor.white.cgColor
        
        resolutionLabel.adjustsFontSizeToFitWidth = true
        fpsLabel.adjustsFontSizeToFitWidth = true
        
        resolutionLabel.textColor = .white
        resolutionLabel.font = UIFont.systemFont(ofSize: 26)
        fpsLabel.textColor = .white
        
        resolutionLabel.textAlignment = .center
        fpsLabel.textAlignment = .center
        
        self.addSubview(roundRect)
        self.addSubview(resolutionLabel)
        self.addSubview(fpsLabel)
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
