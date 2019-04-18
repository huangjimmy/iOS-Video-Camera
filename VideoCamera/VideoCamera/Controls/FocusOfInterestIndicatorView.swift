//
//  FocusOfInterestIndicatorView.swift
//  VideoCamera
//
//  Created by jimmy on 2019/4/19.
//  Copyright © 2019 huangsj. All rights reserved.
//

import UIKit

class FocusOfInterestIndicatorView: UIControl {
    
    private var crossHorizontal:UIView?
    private var crossVertical:UIView?
    
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
        
        self.crossHorizontal = UIView()
        self.crossHorizontal?.translatesAutoresizingMaskIntoConstraints = false
        self.crossHorizontal?.backgroundColor = UIColor(red: 0xff/255, green: 0xcc/255, blue: 0, alpha: 0.75)
        
        self.crossVertical = UIView()
        self.crossVertical?.translatesAutoresizingMaskIntoConstraints = false
        self.crossVertical?.backgroundColor = UIColor(red: 0xff/255, green: 0xcc/255, blue: 0, alpha: 0.75)
    
        self.addSubview(crossHorizontal!)
        self.addSubview(crossVertical!)
        
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[v(10)]", options: .init(rawValue: 0), metrics: nil, views: ["v":self.crossHorizontal!]))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[v(1)]", options: .init(rawValue: 0), metrics: nil, views: ["v":self.crossHorizontal!]))
        
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[v(1)]", options: .init(rawValue: 0), metrics: nil, views: ["v":self.crossVertical!]))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[v(10)]", options: .init(rawValue: 0), metrics: nil, views: ["v":self.crossVertical!]))
        
        self.addConstraint(NSLayoutConstraint(item: self.crossHorizontal!, attribute: .centerX, relatedBy: .equal, toItem: self, attribute:.centerX, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self.crossHorizontal!, attribute: .centerY, relatedBy: .equal, toItem: self, attribute:.centerY, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: self.crossVertical!, attribute: .centerX, relatedBy: .equal, toItem: self, attribute:.centerX, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self.crossVertical!, attribute: .centerY, relatedBy: .equal, toItem: self, attribute:.centerY, multiplier: 1, constant: 0))
        
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor(red: 0xff/255, green: 0xcc/255, blue: 0, alpha: 0.75).cgColor
        
        self.backgroundColor = .clear
    }
}
