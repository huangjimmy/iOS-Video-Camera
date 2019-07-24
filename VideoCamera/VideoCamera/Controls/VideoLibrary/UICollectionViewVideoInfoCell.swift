//
//  UICollectionViewVideoInfoCell.swift
//  VideoCamera
//
//  Created by jimmy on 2019/7/22.
//  Copyright © 2019 huangsj. All rights reserved.
//

import UIKit

class UICollectionViewVideoInfoCell: UICollectionViewCell, UICollectionViewDataSource {
    
    static let identifier = "UICollectionViewVideoInfoCell"
    
    let dateFormat = DateFormatter()
    let timeFormat = DateFormatter()
    
    private var _movFile:MovFile!
    
    var movFile:MovFile! {
        get{
            return _movFile
        }
        set{
            _movFile = newValue
            self.collectionView.reloadData()
        }
    }
    
    override var isSelected: Bool {
        get {
            return super.isSelected
        }
        set{
            super.isSelected = newValue
            if newValue {
                self.backgroundColor = UIColor(red: 0x66/255.0, green: 0x66/255.0, blue: 0x66/255.0, alpha: 1)
            }
            else{
                self.backgroundColor = UIColor(red: 0x33/255.0, green: 0x33/255.0, blue: 0x33/255.0, alpha: 1)
            }
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //n*86+12+(n-1)*6 = self.width
        //n*92+6 = self.width
        if self.movFile == nil {
            return 0
        }
        return 2 + self.movFile.thumbnails.count//Int(self.frame.width-6)/92
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch(indexPath.row){
        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UIVideoResolutionFPSCellView", for: indexPath) as! UIVideoResolutionFPSCellView
            cell.resolutionLabel.text = self.movFile.resolution
            cell.fpsLabel.text = self.movFile.fps
            cell.backgroundColor = .clear
            return cell
        case 1:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UIVideInfoLengthAndTimeCellView", for: indexPath) as! UIVideInfoLengthAndTimeCellView
            cell.timeShotLabel.text = timeFormat.string(from: self.movFile.creationDate!)
            cell.lengthLabel.text = movFile.videoLength
            cell.backgroundColor = .clear
            return cell
        default:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UIVideoFrameCellView", for: indexPath) as! UIVideoFrameCellView
            cell.imageView.image = self.movFile.thumbnails[indexPath.item-2]
            cell.backgroundColor = .clear
            return cell
        }
        
    }
    
    var collectionView: UICollectionView! = nil
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        createSubViews()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        createSubViews()
    }
    
    init() {
        super.init(frame: CGRect())
        createSubViews()
    }
    
    func createSubViews(){
        
        dateFormat.dateStyle = .long
        dateFormat.timeStyle = .none
        
        timeFormat.dateStyle = .none
        timeFormat.timeStyle = .short
        timeFormat.setLocalizedDateFormatFromTemplate("hh:mm")
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 86, height: 86)
        layout.minimumLineSpacing = 6
        layout.minimumInteritemSpacing = 6
        
        layout.scrollDirection = .horizontal
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView?.register(UIVideoResolutionFPSCellView.self, forCellWithReuseIdentifier: "UIVideoResolutionFPSCellView")
        collectionView?.register(UIVideInfoLengthAndTimeCellView.self, forCellWithReuseIdentifier: "UIVideInfoLengthAndTimeCellView")
        collectionView?.register(UIVideoFrameCellView.self, forCellWithReuseIdentifier: "UIVideoFrameCellView")
        collectionView?.translatesAutoresizingMaskIntoConstraints = false
        collectionView?.dataSource = self
        
        self.addSubview(collectionView!)
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-6-[v]-6-|", options: .init(), metrics: nil, views: ["v":collectionView!]))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[v]-0-|", options: .init(), metrics: nil, views: ["v":collectionView!]))
        self.isSelected = false
        self.collectionView.backgroundColor = .clear
        
        self.collectionView.isUserInteractionEnabled = false
    }
    
    override func prepareForReuse() {
        self.movFile = nil
        self.isSelected = false
    }
}
