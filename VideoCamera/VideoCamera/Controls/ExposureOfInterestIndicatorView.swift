//
//  ExposureOfInterestIndicatorView.swift
//  VideoCamera
//
//  Created by jimmy on 2019/4/21.
//  Copyright © 2019 huangsj. All rights reserved.
//

import UIKit

class ExposureOfInterestIndicatorView: UIControl {
    
    private var lockUnockButton: UIButton?
    
    let unlockImage = UIImage(named: "lock_open_small")?.withRenderingMode(.alwaysTemplate)
    let lockImage = UIImage(named: "lock_locked_small")?.withRenderingMode(.alwaysTemplate)
    
    required init() {
        super.init(frame: .zero)
        
        initSubViews()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initSubViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initSubViews()
    }
    
    private var _locked = false
    var locked: Bool {
        get {
            return _locked
        }
        
        set {
            _locked = newValue
            if _locked {
                self.lockUnockButton!.setImage(lockImage, for: .normal)
            }
            else{
                self.lockUnockButton!.setImage(unlockImage, for: .normal)
            }
        }
    }
    
    let exposureColor = UIColor(red: 0xff/255, green: 0x3b/255, blue: 0x30/255, alpha: 0.75)
    
    private func initSubViews(){
        
        self.lockUnockButton = UIButton(type: .custom)
        self.lockUnockButton!.setImage(unlockImage, for: .normal)
        
        self.lockUnockButton!.setAttributedTitle(NSAttributedString(string: NSLocalizedString("☀", comment: ""), attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 12), NSAttributedString.Key.foregroundColor: exposureColor]), for: .normal)
        
        self.lockUnockButton!.translatesAutoresizingMaskIntoConstraints = false
        self.lockUnockButton!.tintColor = exposureColor
        self.lockUnockButton!.contentHorizontalAlignment = .left
        self.addSubview(self.lockUnockButton!)
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[v(75)]-(-60)-|", options: .init(rawValue: 0), metrics: nil, views: ["v":self.lockUnockButton!]))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[v(20)]-(-20)-|", options: .init(rawValue: 0), metrics: nil, views: ["v":self.lockUnockButton!]))
        self.lockUnockButton!.addTarget(self, action: #selector(lockUnlockTap(_:)), for: .touchUpInside)
        
        self.translatesAutoresizingMaskIntoConstraints = false
        
        self.layer.borderWidth = 2
        self.layer.borderColor = exposureColor.cgColor
        
        self.backgroundColor = .clear
        
        self.clipsToBounds = false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
       return false
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if self.lockUnockButton!.frame.contains(point) {
            return self.lockUnockButton!
        }
        if CGRect(x: 0, y: 0, width: self.width(), height: self.height()+25).contains(point) {
            return self
        }
        return super.hitTest(point, with: event)
    }
    
    //////////////////////////////////////
    @objc func lockUnlockTap(_ sender:Any){
        self.sendActions(for: .valueChanged)
    }
}
