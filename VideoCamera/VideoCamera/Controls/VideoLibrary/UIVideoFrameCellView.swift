//
//  UIVideoFrameCellView.swift
//  VideoCamera
//
//  Created by jimmy on 2019/7/22.
//  Copyright © 2019 huangsj. All rights reserved.
//

import UIKit

class UIVideoFrameCellView: UICollectionViewCell {
    
    let imageView:UIImageView
    
    required init?(coder aDecoder: NSCoder) {
        imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 86, height: 86))
        
        super.init(coder: aDecoder)
        
        self.setupViews()
    }
    
    override init(frame: CGRect) {
        imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 86, height: 86))
        
        super.init(frame: frame)
        
        self.setupViews()
    }
    
    func setupViews(){
        self.backgroundColor = .clear//UIColor(red: 0xFF/255.0, green: 0x3B/255.0, blue: 0x30/255.0, alpha: 1.0)
        self.contentView.backgroundColor = self.backgroundColor
        
        self.imageView.backgroundColor = .clear
        self.imageView.contentMode = .scaleAspectFit
        
        self.addSubview(self.imageView)
    }

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
