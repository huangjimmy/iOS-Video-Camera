//
//  WhiteBalanceSettingsView.swift
//  VideoCamera
//
//  Created by jimmy on 2019/4/26.
//  Copyright © 2019 huangsj. All rights reserved.
//

import UIKit

fileprivate let WhiteBalanceModes = [WhiteBalanceMode.auto, WhiteBalanceMode.sunlight, WhiteBalanceMode.cloudy, WhiteBalanceMode.tungsten, WhiteBalanceMode.shade, WhiteBalanceMode.flash, WhiteBalanceMode.manual]

/*! This is a view of size 300x240,
 
 View Layout
 
   auto   ---- sunlight --- cloudy
     |
 tungsten  ---  shade   --- flash
     |
                manual
 */
class WhiteBalanceSettingsView: UIControl {
    let autoButton: CameraParameterButton = CameraParameterButton(frame: .zero)
    /*! 5200K*/
    let sunlightButton: CameraParameterButton = CameraParameterButton(frame: .zero)
    /*! 6000K*/
    let cloudyButton: CameraParameterButton = CameraParameterButton(frame: .zero)
    /*! 3000K*/
    let tungstenButton: CameraParameterButton = CameraParameterButton(frame: .zero)
    /*! 7500K*/
    let shadeButton: CameraParameterButton = CameraParameterButton(frame: .zero)
    /*! 4000K*/
    let flashButton: CameraParameterButton = CameraParameterButton(frame: .zero)
    let manualButton: CameraParameterButton = CameraParameterButton(frame: .zero)
    
    var buttons:[CameraParameterButton]!
    
    private var _whiteBalanceMode: WhiteBalanceMode = .auto
    @objc var whiteBalanceMode: WhiteBalanceMode {
        get {
            return _whiteBalanceMode
        }
        set {
            self.willChangeValue(for: \.whiteBalanceMode)
            _whiteBalanceMode = newValue
            
            buttons.forEach { (button) in
                button.parameterSelected = false
            }
            
            switch _whiteBalanceMode {
            case .auto:
                buttons[0].parameterSelected = true
                break
            case .sunlight:
                buttons[1].parameterSelected = true
                break
            case .cloudy:
                buttons[2].parameterSelected = true
                break
            case .tungsten:
                buttons[3].parameterSelected = true
                break
            case .shade:
                buttons[4].parameterSelected = true
                break
            case .flash:
                buttons[5].parameterSelected = true
                break
            case .manual:
                buttons[6].parameterSelected = true
                break
            default:
                break
            }
            self.didChangeValue(for: \.whiteBalanceMode)
        }
    }
    
    convenience init() {
        self.init(frame: .zero)
        self.initViews()
    }
    
    func initViews(){
        
        buttons = [autoButton, sunlightButton, cloudyButton, tungstenButton, shadeButton, flashButton, manualButton]
        let buttonTexts1 = ["AWB", "5200K", "6000K", "3000K", "7500K", "4000K", "K"]
        let buttonTexts2 = ["Auto", "Sunlight", "Cloudy", "Tungsten", "Shade", "Flash", "Manual"]
        
        for i in 0...6 {
            let button = buttons[i]
            button.frame = CGRect(x:0, y:0, width:69, height:42)
            button.center = CGPoint(x: (i%3)*100+50,y: (i/3)*80+40)
            if i == 6 {
                button.center.x += 100
            }
            button.backgroundColor = .clear
            self.addSubview(button)
            button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
            button.text1 = buttonTexts1[i]
            button.text2 = NSLocalizedString(buttonTexts2[i], comment: "") 
        }
        
        self.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)
        
        self.whiteBalanceMode = .auto
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        self.initViews()
    }
    
    @objc func buttonTapped(_ sender: Any) {
        let button = sender as! CameraParameterButton
        if let index = buttons.firstIndex(of: button) {
            for i in 0...6 {
                let b = buttons[i]
                b.parameterSelected = i == index
            }
            
            self.whiteBalanceMode = WhiteBalanceModes[index]
            
            self.sendActions(for: .valueChanged)
        }
    }
}
