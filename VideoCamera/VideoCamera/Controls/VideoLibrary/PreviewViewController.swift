//
//  PreviewViewController.swift
//  VideoCamera
//
//  Created by jimmy on 2019/7/24.
//  Copyright © 2019 huangsj. All rights reserved.
//

import UIKit
import QuickLook

class PreviewManager : QLPreviewControllerDataSource{
    
    class var shared : PreviewManager {
        struct Singleton {
            static let pm = PreviewManager()
        }
        return Singleton.pm;
    }
    
    var movFile:MovFile!
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        let item = PreviewItem()
        item.filePath = self.movFile.filePath
        return item
    }
}

class PreviewViewController: UIViewController {
    
    init(movFile:MovFile) {
    
        PreviewManager.shared.movFile = movFile
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let quickLookPreviewController = QLPreviewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addChild(quickLookPreviewController)
        self.view.addSubview(quickLookPreviewController.view)
        
        quickLookPreviewController.view.frame = self.view.bounds
        quickLookPreviewController.didMove(toParent: self)
        self.quickLookPreviewController.dataSource = PreviewManager.shared
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

class PreviewItem: NSObject, QLPreviewItem {
    
    /*!
     * @abstract The URL of the item to preview.
     * @discussion The URL must be a file URL.
     */
    
    var filePath: URL?
    public var previewItemURL: URL? {
        if let filePath = filePath {
            return filePath
        }
        return nil
    }
    
}
