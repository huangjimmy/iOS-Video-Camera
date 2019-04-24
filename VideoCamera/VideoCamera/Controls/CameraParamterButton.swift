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
    var lockedIndicator: UIView
    
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
    
    var parameterLocked:Bool {
        get{
            return self.lockedIndicator.isHidden == false
        }
        set {
            self.lockedIndicator.isHidden = !newValue
        }
    }
    
    var _parameterSelected: Bool = false
    var parameterSelected:Bool {
        get{
            return _parameterSelected
        }
        set {
            _parameterSelected = newValue
            if newValue {
                self.backgroundColor = UIColor(red: 0xFF/255.0, green: 0x95/255, blue: 0, alpha: 1)
            }
            else{
                self.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.40)
            }
        }
    }
    
    init(){
        upperLabel = UILabel(frame: CGRect(x: 0,y: 0, width: 69, height: 21))
        bottomLabel = UILabel(frame: CGRect(x: 0,y: 21, width: 69, height: 21))
        lockedIndicator = UIView(frame: CGRect(x: 0,y: 39, width: 69, height: 3))
        super.init(frame: .zero)
        
        self.initSubViews()
    }
    
    override init(frame: CGRect) {
        upperLabel = UILabel(frame: CGRect(x: 0,y: 0, width: 69, height: 21))
        bottomLabel = UILabel(frame: CGRect(x: 0,y: 21, width: 69, height: 21))
        lockedIndicator = UIView(frame: CGRect(x: 0,y: 39, width: 69, height: 3))
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        upperLabel = UILabel(frame: CGRect(x: 0,y: 0, width: 69, height: 21))
        bottomLabel = UILabel(frame: CGRect(x: 0,y: 21, width: 69, height: 21))
        lockedIndicator = UIView(frame: CGRect(x: 0,y: 39, width: 69, height: 3))
        super.init(coder: aDecoder)
        
        self.initSubViews()
    }
    
    func initSubViews(){
        upperLabel.textColor = .white
        bottomLabel.textColor = .white
        
        upperLabel.textAlignment = .center
        bottomLabel.textAlignment = .center
        
        upperLabel.font = UIFont.systemFont(ofSize: 15)
        bottomLabel.font = UIFont.systemFont(ofSize: 15)
        
        self.addSubview(upperLabel)
        self.addSubview(self.bottomLabel)
        self.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.40)
        
        self.lockedIndicator.backgroundColor = UIColor(red: 0xff/255, green: 0x3b/255, blue: 0x30/255, alpha: 1)
        self.lockedIndicator.isHidden = true
        self.addSubview(self.lockedIndicator)
    }
}
