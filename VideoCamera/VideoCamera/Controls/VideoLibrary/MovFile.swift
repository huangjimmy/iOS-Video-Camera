//
//  MovFile.swift
//  VideoCamera
//
//  Created by jimmy on 2019/7/24.
//  Copyright © 2019 huangsj. All rights reserved.
//

import AVFoundation

class MovFile: Hashable, Equatable {
    
    /// Resolution of this mov
    public let resolution:String?
    /// FPS of this mov
    public let fps:String?
    /// Date when this mov is shot
    public let dateShot:String?
    /// Time of date when this mov is shot
    public let timeShot:String?
    /// Length of this mov, in mm:ss format
    public let videoLength:String?
    /// File extension.
    public let fileExtension: String
    /// File attributes (including size, creation date etc).
    public let fileAttributes: [FileAttributeKey:Any]
    /// NSURL file path.
    public let filePath: URL
    /// creationDate
    public let creationDate: Date?
    /// thumbnails of 6 frames
    public lazy var thumbnails:[UIImage] = {
        let asset = AVAsset(url: filePath)
        
        let duration = asset.duration
        let durationTime = CMTimeGetSeconds(duration)
        
        var thumbnails:[UIImage] = []
        
        let gen = AVAssetImageGenerator(asset: asset)
        gen.maximumSize = CGSize(width: 256, height: 0)
        
        for ts in stride(from: 0.0, to: durationTime, by: durationTime/6){
            var time = CMTime(seconds: ts*100, preferredTimescale: 100)
            do{
                let cgImage = try gen.copyCGImage(at: time, actualTime: nil)
                let thumbnail = UIImage(cgImage: cgImage)
                thumbnails.append(thumbnail)
            } catch {}
        }
        
        return thumbnails
    }()
    
    init(filePath:URL) {
        self.filePath = filePath
        self.fileExtension = filePath.pathExtension
        do {
            self.fileAttributes = try FileManager.default.attributesOfItem(atPath: filePath.path)
        } catch {
            self.fileAttributes = [:]
        }
        if let _creationDate = self.fileAttributes[.creationDate] {
            creationDate = (_creationDate as! Date)
            let calendar = Calendar(identifier: .gregorian)
            let dateComps = calendar.dateComponents(Set([Calendar.Component.year, Calendar.Component.month, Calendar.Component.day, Calendar.Component.hour, Calendar.Component.minute, Calendar.Component.second]), from: creationDate!)
            dateShot = String(format: "%4ld-%02ld-%02ld", dateComps.year!, dateComps.month!, dateComps.day!)
            timeShot = String(format:"%02ld:%02ld:%02ld", dateComps.hour!, dateComps.minute!, dateComps.second!)
        }
        else{
            creationDate = nil
            dateShot = nil
            timeShot = nil
        }
        
        let asset = AVAsset(url: filePath)
        
        let duration = asset.duration
        let durationTime = CMTimeGetSeconds(duration)
        if durationTime >= 3600 {
            self.videoLength = String(format:"%02ld:%02ld:%02ld", Int(durationTime)/3600, (Int(durationTime)%3600)/60, Int(durationTime)%60)
        }
        else{
            self.videoLength = String(format:"%02ld:%02ld", Int(durationTime/60), Int(durationTime)%60)
        }
        
        let videoTracks = asset.tracks(withMediaType: .video)
        if videoTracks.count > 0 {
            let dimension = videoTracks[0].naturalSize
            if dimension.width == 3840 || dimension.width == 4096 {
                resolution = "4K"
            }
            else if dimension.width == 1920 {
                resolution = "1080p"
            }
            else if dimension.width == 1280 {
                resolution = "720p"
            }
            else{
                resolution = ""
            }
            
            let frameRate = Int(videoTracks[0].nominalFrameRate)
            fps = "\(frameRate) FPS"
        }
        else{
            resolution = ""
            fps = ""
        }
    }
    
    func hash(into hasher: inout Hasher) {
        filePath.hash(into: &hasher)
    }
    
    static func == (lhs: MovFile, rhs: MovFile) -> Bool {
        return lhs.filePath == rhs.filePath
    }
}

class MovFileGroup{
    let groupName:String
    var files:[MovFile]
    
    init(groupName:String, files:[MovFile]) {
        self.groupName = groupName
        self.files = files
    }
}

