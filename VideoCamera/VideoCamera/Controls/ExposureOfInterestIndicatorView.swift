//
//  ExposureOfInterestIndicatorView.swift
//  VideoCamera
//
//  Created by jimmy on 2019/4/21.
//  Copyright © 2019 huangsj. All rights reserved.
//

import UIKit

class ExposureOfInterestIndicatorView: UIControl {
    required init() {
        super.init(frame: .zero)
        
        createSubViews()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        createSubViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        createSubViews()
    }
    
    private func createSubViews(){
        
        self.translatesAutoresizingMaskIntoConstraints = false
        
        self.layer.borderWidth = 2
        self.layer.borderColor = UIColor(red: 0xff/255, green: 0x3b/255, blue: 0x30/255, alpha: 0.75).cgColor
        
        self.backgroundColor = .clear
    }
}
