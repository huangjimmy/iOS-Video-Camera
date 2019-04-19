//
//  CameraParamterButton.swift
//  VideoCamera
//
//  Created by jimmy on 2019/4/19.
//  Copyright © 2019 huangsj. All rights reserved.
//

import UIKit

class CameraParameterButton: UIControl {
    var upperLabel: UILabel
    var bottomLabel: UILabel
    
    var text1:String? {
        get{
            return upperLabel.text
        }
        set{
            upperLabel.text = newValue
        }
    }
    
    var text2:String? {
        get{
            return bottomLabel.text
        }
        set{
            bottomLabel.text = newValue
        }
    }
    
    init(){
        upperLabel = UILabel(frame: CGRect(x: 0,y: 0, width: 69, height: 21))
        bottomLabel = UILabel(frame: CGRect(x: 0,y: 21, width: 69, height: 21))
        super.init(frame: .zero)
        
        self.createSubviews()
    }
    
    override init(frame: CGRect) {
        upperLabel = UILabel(frame: CGRect(x: 0,y: 0, width: 69, height: 21))
        bottomLabel = UILabel(frame: CGRect(x: 0,y: 21, width: 69, height: 21))
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        upperLabel = UILabel(frame: CGRect(x: 0,y: 0, width: 69, height: 21))
        bottomLabel = UILabel(frame: CGRect(x: 0,y: 21, width: 69, height: 21))
        super.init(coder: aDecoder)
        
        self.createSubviews()
    }
    
    func createSubviews(){
        upperLabel.textColor = .white
        bottomLabel.textColor = .white
        
        upperLabel.textAlignment = .center
        bottomLabel.textAlignment = .center
        
        upperLabel.font = UIFont.systemFont(ofSize: 15)
        bottomLabel.font = UIFont.systemFont(ofSize: 15)
        
        self.addSubview(upperLabel)
        self.addSubview(self.bottomLabel)
        self.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.40)
    }
}
