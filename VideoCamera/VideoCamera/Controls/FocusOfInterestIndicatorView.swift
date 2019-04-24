//
//  FocusOfInterestIndicatorView.swift
//  VideoCamera
//
//  Created by jimmy on 2019/4/19.
//  Copyright © 2019 huangsj. All rights reserved.
//

import UIKit

class FocusOfInterestIndicatorView: UIControl {
    
    private var centerFocus:UIView?
    private var lockUnockButton: UIButton?
    
    let unlockImage = UIImage(named: "lock_open_small")?.withRenderingMode(.alwaysTemplate)
    let lockImage = UIImage(named: "lock_locked_small")?.withRenderingMode(.alwaysTemplate)
    
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
    
    
    private func initSubViews(){
        
        let focusColor = UIColor(red: 0xff/255, green: 0xcc/255, blue: 0, alpha: 0.75)
        
        self.lockUnockButton = UIButton(type: .custom)
        self.lockUnockButton!.setImage(unlockImage, for: .normal)
        
        self.lockUnockButton!.setAttributedTitle(NSAttributedString(string: NSLocalizedString("°", comment: ""), attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 12), NSAttributedString.Key.foregroundColor: focusColor]), for: .normal)
        
        self.lockUnockButton!.translatesAutoresizingMaskIntoConstraints = false
        self.lockUnockButton!.tintColor = focusColor
        self.lockUnockButton!.contentHorizontalAlignment = .left
        self.addSubview(self.lockUnockButton!)
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(-15)-[v(60)]", options: .init(rawValue: 0), metrics: nil, views: ["v":self.lockUnockButton!]))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[v(20)]-(-20)-|", options: .init(rawValue: 0), metrics: nil, views: ["v":self.lockUnockButton!]))
        self.lockUnockButton!.addTarget(self, action: #selector(lockUnlockTap(_:)), for: .touchUpInside)
        
        self.translatesAutoresizingMaskIntoConstraints = false
        
        self.centerFocus = UIView()
        self.centerFocus?.translatesAutoresizingMaskIntoConstraints = false
        self.centerFocus?.backgroundColor = UIColor(red: 0xff/255, green: 0xcc/255, blue: 0, alpha: 0.75)
        
        self.addSubview(centerFocus!)
        
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[v(9)]", options: .init(rawValue: 0), metrics: nil, views: ["v":self.centerFocus!]))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[v(9)]", options: .init(rawValue: 0), metrics: nil, views: ["v":self.centerFocus!]))
        
        self.centerFocus!.layer.borderWidth = 2
        self.centerFocus!.layer.borderColor = UIColor(red: 0xff/255, green: 0xcc/255, blue: 0, alpha: 0.75).cgColor
        self.centerFocus!.backgroundColor = UIColor.clear
      
        self.addConstraint(NSLayoutConstraint(item: self.centerFocus!, attribute: .centerX, relatedBy: .equal, toItem: self, attribute:.centerX, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self.centerFocus!, attribute: .centerY, relatedBy: .equal, toItem: self, attribute:.centerY, multiplier: 1, constant: 0))
        
        self.layer.borderWidth = 2
        self.layer.borderColor = focusColor.cgColor
        
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
