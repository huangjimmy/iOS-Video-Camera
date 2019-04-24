//
//  BluetoothAndMiscSettingsView.swift
//  VideoCamera
//
//  Created by jimmy on 2019/4/24.
//  Copyright © 2019 huangsj. All rights reserved.
//

import Foundation

class BluetoothAndMiscHomeView: UIView {
    let bluetoothButton: UIButton
    let settingsButton: UIButton
    let bluetoothStatusLabel: UILabel
    
    var bluetoothTapped:(()->Void)?
    var settingsTapped:(()->Void)?
    
    init() {
        
        bluetoothButton = UIButton(type: .custom)
        settingsButton = UIButton(type: .custom)
        bluetoothStatusLabel = UILabel(frame: .zero)
        
        super.init(frame: .zero)
        
        self.initSubViews()
    }
    
    override init(frame: CGRect) {
        
        bluetoothButton = UIButton(type: .custom)
        settingsButton = UIButton(type: .custom)
        bluetoothStatusLabel = UILabel(frame: .zero)
        
        super.init(frame: frame)
        
        self.initSubViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        bluetoothButton = UIButton(type: .custom)
        settingsButton = UIButton(type: .custom)
        bluetoothStatusLabel = UILabel(frame: .zero)
        
        super.init(coder: aDecoder)
        
        self.initSubViews()
    }
    
    private func initSubViews(){
        
        self.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)
        
        self.bluetoothButton.translatesAutoresizingMaskIntoConstraints = false
        self.bluetoothStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        self.settingsButton.translatesAutoresizingMaskIntoConstraints = false
        
        self.bluetoothButton.setBackgroundImage(UIImage(named: "bluetooth"), for: .normal)
        self.settingsButton.setBackgroundImage(UIImage(named: "settings"), for: .normal)
        
        self.bluetoothButton.addTarget(self, action: #selector(bluetoothTapped(_:)), for: .touchUpInside)
        self.settingsButton.addTarget(self, action: #selector(settingsTapped(_:)), for: .touchUpInside)
        
        self.bluetoothStatusLabel.font = UIFont.systemFont(ofSize: 12)
        self.bluetoothStatusLabel.textColor = .white
        
        self.addSubview(self.bluetoothButton)
        self.addSubview(self.bluetoothStatusLabel)
        self.addSubview(self.settingsButton)
        
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-6-[bluetoothButton(20)]-6-[bluetoothStatusLabel]-6-[settingsButton(20)]-6-|", options: .init(rawValue: 0), metrics: nil, views: ["bluetoothButton":self.bluetoothButton, "bluetoothStatusLabel":self.bluetoothStatusLabel, "settingsButton":self.settingsButton]))
        
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[bluetoothButton(24)]", options: .init(rawValue: 0), metrics: nil, views: ["bluetoothButton":self.bluetoothButton]))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[bluetoothStatusLabel(20)]", options: .init(rawValue: 0), metrics: nil, views: ["bluetoothStatusLabel":self.bluetoothStatusLabel]))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[settingsButton(20)]", options: .init(rawValue: 0), metrics: nil, views: ["settingsButton":self.settingsButton]))
        
        self.addConstraint(NSLayoutConstraint(item: self.bluetoothButton, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self.bluetoothStatusLabel, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self.settingsButton, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0))
    }
    
    @objc func bluetoothTapped(_ sender: Any) {
        guard let block = self.bluetoothTapped else {
            return
        }
        block()
    }
    
    @objc func settingsTapped(_ sender: Any) {
        guard let block = self.settingsTapped else {
            return
        }
        block()
    }
}
