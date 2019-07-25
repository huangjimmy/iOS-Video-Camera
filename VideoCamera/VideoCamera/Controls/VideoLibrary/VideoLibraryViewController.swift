//
//  VideoLibraryViewController.swift
//  VideoCamera
//
//  Created by jimmy on 2019/7/24.
//  Copyright © 2019 huangsj. All rights reserved.
//

import UIKit
import AVFoundation
import QuickLook
import Photos

@objc class VideoLibraryViewController: UIViewController {
    
    let videoLibrary = VideoLibraryManager.shared
    
    var movFiles:[MovFile] = []
    var movFileGroups:[MovFileGroup] = []
    var selectedMovs:Set<URL> = Set()
    /*  Controls declaration  */
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet var toolbarButtons: [UIBarButtonItem]!
    
    
    let dateFormat = DateFormatter()
    let timeFormat = DateFormatter()
    
    override var isEditing:Bool {
        get {
            return super.isEditing
        }
        set{
            super.isEditing = newValue
            
            switch newValue {
            case true:
                self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Select All", comment: ""), style: .plain, target: self, action: #selector(selectAll(_:)))
                self.navigationItem.title = "";
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Cancel", comment: ""), style: .plain, target: self, action: #selector(toggleEditing))
            default:
                self.selectedMovs.removeAll()
                self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Go Back", comment: ""), style: .plain, target: self, action: #selector(closeViewController))
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Select", comment: ""), style: .plain, target: self, action: #selector(toggleEditing))
                self.navigationItem.title = "";
            }
            self.toolbar.isHidden = !newValue
            self.collectionView.reloadData()
            self.reloadMenu()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.isEditing = false
        self.collectionView.allowsSelection = true
        self.collectionView.allowsMultipleSelection = true
        
        dateFormat.dateStyle = .full
        dateFormat.timeStyle = .none
        
        timeFormat.dateStyle = .none
        timeFormat.timeStyle = .short
        timeFormat.setLocalizedDateFormatFromTemplate("hh:mm")

        var group:MovFileGroup? = nil
        let files = videoLibrary.videoFiles()
        self.movFiles = files
        for file in files {
            
            if !videoLibrary.isMovIndexed(fileURL: file.filePath) {
                videoLibrary.indexMov(fileURL: file.filePath, fps: file.fps, resolution: file.resolution)
            }
            else{
                videoLibrary.refreshFromCache(movFile: file)
            }
            
            if let group = group, group.groupName.compare(file.dateShot!) == .orderedSame {
                group.files.append(file)
            }
            else{
                group = MovFileGroup(groupName: file.dateShot!, files: [file])
                self.movFileGroups.append(group!)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.reloadMenu()
        self.collectionView.reloadData()
    }
    
    @objc func closeViewController(){
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func toggleEditing(){
        self.isEditing = !self.isEditing
    }
    
    override func selectAll(_ sender: Any?) {
        
        if self.selectedMovs.count == self.movFiles.count{
            self.selectedMovs.removeAll()
            for i in 0..<self.movFileGroups.count {
                let group = self.movFileGroups[i]
                for j in 0..<group.files.count {
                    self.collectionView.deselectItem(at: IndexPath(item: j, section: i), animated: false)
                }
            }
            reloadMenu()
            return
        }
        
        self.movFiles.forEach { (file) in
            self.selectedMovs.insert(file.filePath)
        }
        for i in 0..<self.movFileGroups.count {
            let group = self.movFileGroups[i]
            for j in 0..<group.files.count {
                self.collectionView.selectItem(at: IndexPath(item: j, section: i), animated: false, scrollPosition: .centeredHorizontally)
            }
        }
        reloadMenu()
    }
    
    @objc func reloadMenu(){
        switch self.isEditing {
        case true:
            if self.selectedMovs.count == 0{
                self.navigationItem.title = NSLocalizedString("Select video", comment: "");
                self.navigationItem.leftBarButtonItem?.title = NSLocalizedString("Select All", comment: "")
                self.toolbarButtons.forEach { (item) in
                    item.isEnabled = false
                }
            }
            else{
                self.toolbarButtons.forEach { (item) in
                    item.isEnabled = true
                }
                if self.selectedMovs.count == self.movFiles.count {
                    self.navigationItem.leftBarButtonItem?.title = NSLocalizedString("Select None", comment: "")
                }
                else{
                    self.navigationItem.leftBarButtonItem?.title = NSLocalizedString("Select All", comment: "")
                }
                self.navigationItem.title = String(format: NSLocalizedString("%d selected", comment: ""), self.selectedMovs.count);
            }
            
        default:
            self.navigationItem.title = String(format: NSLocalizedString("%d videos", comment: ""), self.movFiles.count);
        }
    }
    
    
    @objc var saveSelectedErrors:[NSError] = []
    @IBAction func saveSelected(_ sender: Any) {
        self.toolbarButtons.forEach { (item) in
            item.isEnabled = false
        }
        saveSelectedErrors.removeAll()
        
        if PHPhotoLibrary.authorizationStatus() == .denied {
            SVProgressHUD.showError(withStatus: NSLocalizedString("You have explicitly deny access to photo library", comment: ""))
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(3000)) {
                SVProgressHUD.dismiss()
            }
            return
        }
        
        self.selectedMovs.forEach { (url) in
            UISaveVideoAtPathToSavedPhotosAlbum(url.path, self, Selector(("video:didFinishSavingWithError:contextInfo:")), nil)
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(300)) {
            if self.saveSelectedErrors.count == 0{
                SVProgressHUD.showSuccess(withStatus: String(format: NSLocalizedString("%d videos saved", comment: ""), self.selectedMovs.count - self.saveSelectedErrors.count))
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(3000)) {
                    SVProgressHUD.dismiss()
                    self.reloadMenu()
                }
            }
            else{
                SVProgressHUD.showError(withStatus: String(format:"%@ %@", self.saveSelectedErrors[0].localizedDescription, self.saveSelectedErrors[0].localizedRecoverySuggestion ?? ""))
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(3000)) {
                    SVProgressHUD.dismiss()
                    self.reloadMenu()
                    let alertVC = UIAlertController(title: NSLocalizedString("Open Settings", comment: ""), message: NSLocalizedString("Open Settings and authorize", comment: ""), preferredStyle: .alert)
                    alertVC.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { (action) in
                        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsURL, options:[:], completionHandler: nil)
                        }
                    }))
                    alertVC.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
                    self.present(alertVC, animated: true, completion: nil)
                }
            }
        }
        
    }
    
    @IBAction func trashSelected(_ sender: Any) {
    }
    
    @IBAction func shareSelected(_ sender: Any) {
        
        let activityVC = UIActivityViewController(activityItems: self.selectedMovs.map({ (url) -> URL in
            return url
        }), applicationActivities: nil)
        self.present(activityVC, animated: true, completion: nil)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
}


extension VideoLibraryViewController : UICollectionViewDataSource, UICollectionViewDelegate,UICollectionViewDelegateFlowLayout{
    
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        self.collectionView.collectionViewLayout.invalidateLayout()
    }
    
    /* UICollectionViewDelegateFlowLayout */
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 34)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellSize = CGSize(width: collectionView.bounds.width, height: 86)
        //
        return cellSize
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 6
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 6
    }
    
    /* UICollectionViewDataSource */
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.movFileGroups.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = self.movFileGroups[section].files.count
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell:UICollectionViewVideoInfoCell = collectionView.dequeueReusableCell(withReuseIdentifier: UICollectionViewVideoInfoCell.identifier, for: indexPath) as! UICollectionViewVideoInfoCell
        cell.movFile = self.movFileGroups[indexPath.section].files[indexPath.item]
        cell.isSelected = self.selectedMovs.contains(cell.movFile.filePath)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: VideoGroupSectionHeaderView.identifier, for: indexPath) as! VideoGroupSectionHeaderView
            header.label.text = dateFormat.string(from: self.movFileGroups[indexPath.section].files[0].creationDate!)
            return header
        default:
            assert(false, "Invalid element type")
        }
    }
    
    /* UICollectionViewDelegate */
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.isEditing {
            let url = self.movFileGroups[indexPath.section].files[indexPath.item].filePath
            if self.selectedMovs.contains(url) {
                self.selectedMovs.remove(url)
            }
            else{
                self.selectedMovs.insert(url)
            }
            collectionView.cellForItem(at: indexPath)?.isSelected = true
            self.reloadMenu()
            return
        }
        PreviewManager.shared.movFile = self.movFileGroups[indexPath.section].files[indexPath.item]
        let quickLookPreviewController = QLPreviewController(nibName: nil, bundle: nil)
        quickLookPreviewController.dataSource = PreviewManager.shared
        self.navigationController?.pushViewController(quickLookPreviewController, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if self.isEditing {
            let url = self.movFileGroups[indexPath.section].files[indexPath.item].filePath
            if self.selectedMovs.contains(url) {
                self.selectedMovs.remove(url)
            }
            else{
                self.selectedMovs.insert(url)
            }
            collectionView.cellForItem(at: indexPath)?.isSelected = false
            self.reloadMenu()
            return
        }
    }
}
