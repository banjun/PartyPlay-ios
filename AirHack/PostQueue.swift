//
//  PostQueue.swift
//  AirHack
//
//  Created by BAN Jun on 2014/09/20.
//  Copyright (c) 2014年 banjun. All rights reserved.
//

import Foundation
import MediaPlayer
import AVFoundation


private var sessionManager: AFURLSessionManager! = nil


class LocalSong : Printable, Equatable {
    let mediaItem: MPMediaItem
    var exportFilePath: String?
    var postProgress: NSProgress?
    
    var status: Status
    enum Status: Printable {
        case WaitingExport
        case Exporting
        case WaitingPost
        case Posting(Float) // progress
        case Posted
        case Failed(String) // reason
        
        var description: String {
            switch self {
            case WaitingExport: return "WaitingExport"
            case Exporting: return "Exporting"
            case WaitingPost: return "WaitingPost"
            case let Posting(p): return "Sending... \(Int(round(100 * p)))%"
            case Posted: return "Posted"
            case let Failed(r): return "Failed (\(r))"
                }
        }
        
        var indeterminate: Bool {
            switch self {
            case .WaitingExport: return true
            case .Exporting: return true
            case .WaitingPost: return true
            case .Posting(_): return false
            case .Posted: return false
            case .Failed(_): return false
            }
        }
        
        var stopped: Bool {
            switch self {
            case .Posted: return true
            case .Failed(_): return true
            default: return false
            }
        }
    }
    
    init(mediaItem: MPMediaItem) {
        self.mediaItem = mediaItem
        self.status = .WaitingExport
    }
    
    deinit {
        if let f = exportFilePath {
            NSFileManager.defaultManager().removeItemAtPath(f, error: nil)
        }
    }
    
    var artwork: UIImage {
        return self.mediaItem.artwork?.imageWithSize(CGSizeMake(512, 512)) ?? stubArtwork
    }
    
    var stubArtwork: UIImage {
        UIGraphicsBeginImageContext(CGSizeMake(512, 512))
        UIColor.blackColor().setFill()
        UIRectFill(CGRectMake(0, 0, 512, 512))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    var artworkJPEGData: NSData {
        return UIImageJPEGRepresentation(self.artwork, 0.8)
    }
    
    func export(completion: (() -> Void)?) {
        self.exportFilePath = "\(NSTemporaryDirectory())/\(mediaItem.persistentID).m4a"
        self.status = .Exporting
        
        let asset = AVAsset.assetWithURL(mediaItem.assetURL) as? AVAsset
        if asset == nil {
            self.status = .Failed("content is protected or not found")
            completion?()
            return
        }
        
        NSFileManager.defaultManager().removeItemAtPath(self.exportFilePath!, error: nil)
        
        let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A)
        session.outputURL = NSURL(fileURLWithPath: self.exportFilePath!)
        session.outputFileType = session.supportedFileTypes.first as String
        session.exportAsynchronouslyWithCompletionHandler { () -> Void in
            if session.status == .Completed {
                self.status = .WaitingPost
            } else {
                println("session completed with status = \(session.status.toRaw()), error = \(session.error)")
                self.status = .Failed("\(session.status.toRaw()),\(session.error.code)")
            }
            self.status = .WaitingPost // success with failed??
            completion?()
        }
    }
    
    var description: String {
        return "LocalSong: \(self.mediaItem), \(self.mediaItem.title), \(self.status)"
    }
}

func == (l: LocalSong, r: LocalSong) -> Bool {
    return l === r
}

func == (l: LocalSong.Status, r: LocalSong.Status) -> Bool {
    switch (l, r) {
    case (.WaitingExport, .WaitingExport): return true
    case (.Exporting, .Exporting): return true
    case (.WaitingPost, .WaitingPost): return true
    case let (.Posting(lv), .Posting(rv)): return true
    case (.Posted, .Posted): return true
    case let (.Failed(lv), .Failed(rv)): return true
    default: return false
    }
}


class PostQueue: NSObject {
    var localSongs: [LocalSong] = []
    let exportQueue: dispatch_queue_t = dispatch_queue_create("export", nil)
    let postQueue: dispatch_queue_t = dispatch_queue_create("post", nil)
    let client: PPSClient
    
    init(client: PPSClient) {
        self.client = client
        super.init()
    }
    
    func addSongs(#mediaItems: [MPMediaItem]) {
        let songs = mediaItems.map{LocalSong(mediaItem: $0)}
        localSongs += songs
        exportAllSongs()
    }
    
    func exportAllSongs() {
        for s in localSongs.filter({$0.status == .WaitingExport}) {
            s.status = .Exporting
            dispatch_async(exportQueue) {
                let sem = dispatch_semaphore_create(0)
                s.export {
                    dispatch_semaphore_signal(sem)
                    self.addToPostQueue(s)
                }
                dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER)
            }
        }
    }
    
    func addToPostQueue(song: LocalSong) {
        if !(song.status == .WaitingPost) { return }
        dispatch_async(self.postQueue) {
            self.client.songsAdd(song) {
                println("post finished: \(song)")
                if (song.status == .Posted) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1.0 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
                        if let index = find(self.localSongs, song) {
                            self.localSongs.removeAtIndex(index)
                        }
                    }
                }
            }
        }
    }
    
    func clearErrors() {
        localSongs = localSongs.filter { !($0.status == .Failed("")) }
    }
    
    var hasErrors: Bool {
        return (localSongs.filter { $0.status == .Failed("") }).count > 0
    }
    
    var statusText: String {
        let failures = localSongs.filter { $0.status == .Failed("") }
        let remainings = localSongs.filter { !$0.status.stopped }
        
            if failures.count > 0 && remainings.count > 0 {
                return String(format: NSLocalizedString("Sending %d songs with %d errors...", comment: ""), remainings.count, failures.count)
            }
            
            if failures.count > 0 {
                return String(format: NSLocalizedString("%d songs failed to send", comment: ""), failures.count)
            }
        
            if remainings.count > 0 {
                return String(format: NSLocalizedString("Sending %d songs...", comment: ""), remainings.count)
            }
            
            return NSLocalizedString("Completed", comment: "")
    }
}

