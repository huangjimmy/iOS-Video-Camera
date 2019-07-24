 //
//  UIVideInfoLengthAndTimeCellView.swift
//  VideoCamera
//
//  Created by jimmy on 2019/7/22.
//  Copyright © 2019 huangsj. All rights reserved.
//

import UIKit

class UIVideInfoLengthAndTimeCellView: UICollectionViewCell {
    let timeShotLabel:UILabel
    let lengthLabel:UILabel
    
    required init?(coder aDecoder: NSCoder) {
        lengthLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 86, height: 43))
        timeShotLabel = UILabel(frame: CGRect(x: 0, y: 43, width: 86, height: 43))
        
        super.init(coder: aDecoder)
        
        self.setupViews()
    }
    
    override init(frame: CGRect) {
        lengthLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 86, height: 43))
        timeShotLabel = UILabel(frame: CGRect(x: 0, y: 43, width: 86, height: 43))
        
        super.init(frame: frame)
        
        self.setupViews()
    }
    
    func setupViews(){
        self.backgroundColor = .clear
       
        timeShotLabel.adjustsFontSizeToFitWidth = false
        lengthLabel.adjustsFontSizeToFitWidth = true
        
        lengthLabel.textColor = .white
        lengthLabel.font = UIFont.systemFont(ofSize: 36)
        timeShotLabel.textColor = .white
        timeShotLabel.font = UIFont.systemFont(ofSize: 16)
        
        timeShotLabel.textAlignment = .center
        lengthLabel.textAlignment = .center
        
        self.addSubview(timeShotLabel)
        self.addSubview(lengthLabel)
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
