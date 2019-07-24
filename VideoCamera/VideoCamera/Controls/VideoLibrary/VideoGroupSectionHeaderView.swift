//
//  VideoGroupSectionHeaderView.swift
//  VideoCamera
//
//  Created by jimmy on 2019/7/24.
//  Copyright © 2019 huangsj. All rights reserved.
//

import UIKit

class VideoGroupSectionHeaderView: UICollectionReusableView {
    
    static let identifier = "VideoGroupSectionHeaderView"
    
    let label:UILabel
    
    required init?(coder: NSCoder) {
        label = UILabel()
        super.init(coder: coder)
        self.createSubviews()
    }
    
    override init(frame: CGRect) {
         label = UILabel()
        super.init(frame: frame)
        self.createSubviews()
    }
    
    func createSubviews(){
        self.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[v]-|", options: .init(), metrics: nil, views: ["v":label]))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[v]-0-|", options: .init(), metrics: nil, views: ["v":label]))
        
        self.backgroundColor = .clear
        self.label.backgroundColor = .clear
        self.label.textColor = .white
        self.label.font = UIFont.systemFont(ofSize: 16)
    }
}
