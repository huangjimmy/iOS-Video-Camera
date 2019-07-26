//
//  VideoLibraryManager.swift
//  VideoCamera
//
//  Created by jimmy on 2019/7/25.
//  Copyright © 2019 huangsj. All rights reserved.
//

import Foundation
import AVFoundation
import SQLite
/**
 
 Video Library is organized as follows
 
 \Documents\
     1.mov
     2.mov
 ...
     thumb.db
 
 
 thumb.db is a sqlite database
 with 2 tables
 1. video_info(id,filename, width, height, resolution, fps, length, creationDate)
 2. frame_thumbnail(id, seq, image)
 */

class VideoLibraryManager {
    
    let fileManager = FileManager.default
        
    func documentsURL() -> URL {
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
    }
    
    class var shared : VideoLibraryManager {
        struct Singleton {
            static let manager = VideoLibraryManager()
        }
        return Singleton.manager;
    }
    
    func videoFiles() -> [MovFile]  {
        var files = [MovFile]()
        var filePaths = [URL]()
        // Get contents
        do  {
            filePaths = try self.fileManager.contentsOfDirectory(at: self.documentsURL(), includingPropertiesForKeys: [], options: [.skipsHiddenFiles])
        } catch {
            return files
        }
        // Parse
        for filePath in filePaths {
            let file = MovFile(filePath: filePath)
            if file.fileExtension.compare("mov") != .orderedSame || file.isDirectory {
                continue
            }

            files.append(file)
        }
        return files.sorted { (mov1, mov2) -> Bool in
            return mov1.creationDate!.timeIntervalSince1970 > mov2.creationDate!.timeIntervalSince1970
        }
    }
    
    func isMovIndexed(fileURL: URL) -> Bool{
        if let db = self.db {
            let video_info = Table("video_info")
            let file_name = Expression<String>("filename")
            let filePath = fileURL.lastPathComponent
            let video_info_exists:Bool = {
                do{
                    let count = try db.scalar(video_info.count.filter(file_name == filePath))
                    return count > 0
                }
                catch { return false }
            }()
            
            return video_info_exists
        }
        return false
    }
    
    func movThumbnailExists(movFile: MovFile) -> Bool {
        let filePath = movFile.filePath.lastPathComponent
        let video_info = Table("video_info")
        let id = Expression<Int64>("id")
        let file_name = Expression<String>("filename")
        
        let mov_id:Int64 = {
            do {
                if let mov_id = try db.pluck(video_info.select(id).where(file_name == filePath)) {
                    return try mov_id.get(id)
                }
                return -1
            }
            catch { return -1 }
        }()
        
        if mov_id <= 0 {
            return false
        }
        
        let frame_thumbnail = Table("frame_thumbnail")
        
        let count:Int = {
            do{
                let count = try db.scalar(frame_thumbnail.count.filter(id == mov_id))
                return count
            }
            catch { return 0 }
        }()
        
        return count >= 6
    }
    
    func thumbnailsFromCache(movFile: MovFile) -> [UIImage] {
        let filePath = movFile.filePath.lastPathComponent
        let video_info = Table("video_info")
        let file_name = Expression<String>("filename")
        let id = Expression<Int64>("id")
        
        let mov_id:Int64 = {
            do {
                if let mov_id = try db.pluck(video_info.select(id).where(file_name == filePath)) {
                    return try mov_id.get(id)
                }
                return -1
            }
            catch { return -1 }
        }()
        
        if mov_id <= 0 {
            return []
        }
        
        let frame_thumbnail = Table("frame_thumbnail")
        let image = Expression<Blob>("image")
        
        var images:[UIImage] = []
        
        do {
            for row in try db.prepare(frame_thumbnail.select(image).where(id == mov_id)){
                let data = try Data(row.get(image).bytes)
                images.append(UIImage(data: data)!)
            }
        }catch { }
        
        return images
    }
    
    func recreateThumbnail(fileURL: URL) {
        let video_info = Table("video_info")
        let file_name = Expression<String>("filename")
        let id = Expression<Int64>("id")
        
        let filename = fileURL.lastPathComponent
        
        let mov_id:Int64 = {
            do {
                if let mov_id = try db.pluck(video_info.select(id).where(file_name == filename)) {
                    return try mov_id.get(id)
                }
                return -1
            }
            catch { return -1 }
        }()
        
        if mov_id <= 0 {
            return
        }
        
        let frame_thumbnail = Table("frame_thumbnail")
        
        do {
            try db.run(frame_thumbnail.where(id == mov_id).delete())
        }catch { }
        
        genThumbnail(mov_id: mov_id, fileURL: fileURL)
    }
    
    func refreshFromCache(movFile: MovFile){
        if isMovIndexed(fileURL: movFile.filePath) {
            if let db = self.db {
                let video_info = Table("video_info")
                let file_name = Expression<String>("filename")
                let fps = Expression<Int>("fps")
                
                do{
                    let row = try db.pluck(video_info.select(fps).where(file_name == movFile.filePath.lastPathComponent))
                    if let fps = try row?.get(fps) {
                        movFile.fps = fps
                    }
                }catch { }
            }
        }
    }
    
    func indexMov(fileURL:URL, fps:Int, resolution:String){
        if let db = self.db {
            let filename = fileURL.lastPathComponent
            let video_info = Table("video_info")
            let file_name = Expression<String>("filename")
            let id = Expression<Int64>("id")
            
            let video_info_exists:Bool = {
                do{
                    let count = try db.scalar(video_info.count.filter(file_name == filename))
                    return count > 0
                }
                catch { return false }
            }()
            
            if video_info_exists == false {
                let mov = MovFile(filePath: fileURL)
                
                do {
                    try db.run(video_info.insert(file_name <- filename, Expression<Int>("width") <- mov.width,
                                         Expression<Int>("height") <- mov.height, Expression<String>("resolution") <- resolution,
                                         Expression<Int>("fps") <- fps, Expression<Int>("length") <- mov.length, Expression<Date>("creationDate") <- mov.creationDate!))
                }catch { }
            }
            
            let mov_id:Int64 = {
                do {
                    if let mov_id = try db.pluck(video_info.select(id).where(file_name == filename)) {
                        return try mov_id.get(id)
                    }
                    return -1
                }
                catch { return -1 }
            }()
            
            genThumbnail(mov_id: mov_id, fileURL: fileURL)
        }
    }
    
    func genThumbnail(mov_id: Int64, fileURL:URL){
        if let db = self.db {
            if mov_id > 0 {
                let mov = MovFile(filePath: fileURL)
                let frame_thumbnail = Table("frame_thumbnail")
                let id = Expression<Int64>("id")
                let seq = Expression<Int64>("seq")
                let image = Expression<Blob>("image")
                //update thumbnail
                for i in 0..<mov.thumbnails.count {
                    if let imageBlob = mov.thumbnails[i].jpegData(compressionQuality: 1.0) {
                        let exists:Bool = {
                            do{
                                let count = try db.scalar(frame_thumbnail.count.where(id == mov_id && seq == Int64(i)))
                                return count > 0
                            } catch { return false }
                        }()
                        
                        if exists {
                            do{
                                try db.run(frame_thumbnail.filter(id == mov_id && seq == Int64(i)).update(image <- imageBlob.datatypeValue))
                            }catch {}
                        }
                        else{
                            do {
                                try db.run(frame_thumbnail.insert(id <- mov_id, seq <- Int64(i), image <- imageBlob.datatypeValue))
                            }catch{}
                        }
                    }
                }
            }
        }
    }
    
    func delete(fileURL:URL) {
        if let db = self.db {
            let video_info = Table("video_info")
            let file_name = Expression<String>("filename")
            let id = Expression<Int64>("id")
            
            let filePath = fileURL.lastPathComponent
            
            let mov_id:Int64 = {
                do {
                    if let mov_id = try db.pluck(video_info.select(id).where(file_name == filePath)) {
                        let val = try mov_id.get(id)
                        do {
                            try db.run(video_info.where(id == val).delete())
                        }catch { }
                        return val
                    }
                    return -1
                }
                catch { return -1 }
            }()
            
            if mov_id > 0 {
                let frame_thumbnail = Table("frame_thumbnail")
                do {
                    try db.run(frame_thumbnail.where(id == mov_id).delete())
                }catch { }
            }
        }
        
        do{
            try self.fileManager.removeItem(at: fileURL)
        }catch { }
    }
    
    lazy var db:Connection! = {
          do{
            let db = try Connection("\(self.documentsURL().appendingPathComponent("thumb.db").path)")
            
//            #if DEBUG
//                db.trace { print($0) }
//            #endif
            
            let type = Expression<String>("type")
            let tbl_name = Expression<String>("tbl_name")
            let video_info_exists:Bool = {
                do {
                    if let _ = try db.pluck(Table("sqlite_master").select([type]).filter(type == "table" && tbl_name == "video_info")) {
                        //table exists
                        let columns:[Expressible] = [Expression<Int64>("id"), Expression<String>("filename"), Expression<Int>("width"),
                        Expression<Int>("height"), Expression<String>("resolution"), Expression<Int>("fps"),
                        Expression<Int>("length"), Expression<Date>("creationDate")]
                        do {
                            let _ = try db.pluck(Table("video_info").select(columns).limit(1))
                            return true
                        }
                        catch {
                            //drop table and recreate
                            do { try db.run(Table("video_info").drop())} catch {}
                            return false
                        }
                    }
                    else{
                        //create table
                        return false
                    }
                }
                catch { return true }
            }()
            
            if video_info_exists == false {
                do {
                    try db.run(Table("video_info").create(block: { (t) in
                        t.column(Expression<Int64>("id"), primaryKey: .autoincrement)
                        t.column(Expression<String>("filename"), unique: true)
                        t.column(Expression<Int>("width"))
                        t.column(Expression<Int>("height"))
                        t.column(Expression<String>("resolution"))
                        t.column(Expression<Int>("fps"))
                        t.column(Expression<Int>("length"))
                        t.column(Expression<Date>("creationDate"))
                    }))
                }catch {}
            }
            
            let frame_thumbnail_exists:Bool = {
                do {
                    if let _ = try db.pluck(Table("sqlite_master").select([type]).filter(type == "table" && tbl_name == "frame_thumbnail")) {
                        //table exists
                        let columns:[Expressible] = [Expression<Int64>("id"), Expression<Int64>("seq"), Expression<Blob>("image")]
                        do {
                            let _ = try db.pluck(Table("frame_thumbnail").select(columns).limit(1))
                            return true
                        }
                        catch {
                            //drop table and recreate
                            do { try db.run(Table("frame_thumbnail").drop())} catch {}
                            return false
                        }
                    }
                    else{
                        //create table
                        return false
                    }
                }
                catch { return true }
            }()
            
            if frame_thumbnail_exists == false {
                do {
                    try db.run(Table("frame_thumbnail").create(block: { (t) in
                        t.column(Expression<Int64>("id"))
                        t.column(Expression<Int64>("seq"))
                        t.column(Expression<Blob>("image"))
                        t.primaryKey(Expression<Int64>("id"), Expression<Int64>("seq"))
                    }))
                }catch {}
            }
            
            return db
           }catch {return nil}
        }()
}
