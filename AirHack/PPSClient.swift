//
//  PPSClient.swift
//  AirHack
//
//  Created by BAN Jun on 2014/09/21.
//  Copyright (c) 2014年 banjun. All rights reserved.
//

import Foundation
import MediaPlayer

let PPSClientNowPlayingDidChangeNotification: NSString = "PPSClientNowPlayingDidChangeNotification"

private let kPost = "POST"
private let kSongsAdd = "/songs/add"
private let kSongsSkip = "/songs/skip"
private let kSongsIndexHTML = "/songs/index.html"
private let kSongsIndexJSON = "/songs/index.json"
private let kParamFile = "file"
private let kParamTitle = "title"
private let kParamArtist = "artist"
private let kParamArtwork = "artwork"
private let kContentTypeOctetStream = "application/octet-stream"
private let kContentTypeJpeg = "image/jpeg"
private let kNSProgressCompletedKey = "fractionCompleted"


class PPSClient : NSObject {
    let baseURL: NSURL
    var nowPlaying: PPSNowPlaying? {
        didSet {
            NSNotificationCenter.defaultCenter().postNotificationName(PPSClient.nowPlayingDidChangeNotificationName, object: self)
        }
    }
    let sessionManager: AFURLSessionManager
    var songIDToProgressMap: [(LocalSong, NSProgress)] = []
    
    class var nowPlayingDidChangeNotificationName : String { return "PPSClientNowPlayingDidChangeNotification" }
    
    var songsIndexHTMLURL: NSURL {
        return baseURL.URLByAppendingPathComponent(kSongsIndexHTML)
    }
    
    init(baseURL: NSURL) {
        let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        sessionConfiguration.HTTPMaximumConnectionsPerHost = 1
        sessionManager = AFURLSessionManager(sessionConfiguration: sessionConfiguration)
        sessionManager.responseSerializer = AFHTTPResponseSerializer()
        self.baseURL = baseURL
    }
    
    func songsAdd(song: LocalSong, completion: (() -> Void)?) {
        if song.exportFilePath == nil { completion?(); return; }
        let filePath = song.exportFilePath!
        
        song.status = .Posting(0)
        
        let serializer = AFHTTPRequestSerializer()
        let request = serializer.multipartFormRequestWithMethod(kPost, URLString: baseURL.URLByAppendingPathComponent(kSongsAdd).absoluteString, parameters: nil, constructingBodyWithBlock: { (formData: AFMultipartFormData!) -> Void in
            // song file content
            formData.appendPartWithFileData(NSData(contentsOfFile: filePath), name: kParamFile, fileName: filePath.lastPathComponent, mimeType: kContentTypeOctetStream)
            
            // metadata
            func addText(key: String, value: String) -> Void {
                formData.appendPartWithFormData(value.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)?.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true),
                    name: key.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding))
            }
            addText(kParamTitle, song.mediaItem.title ?? "no title")
            addText(kParamArtist, song.mediaItem.artist ?? "unknown artist")
            formData.appendPartWithFileData(song.artworkJPEGData, name: kParamArtwork, fileName: kParamArtwork, mimeType: kContentTypeJpeg)
            }, error: nil)
        
        var progress: NSProgress? = nil
        let uploadTask = sessionManager.uploadTaskWithStreamedRequest(request, progress: &progress) {
            (response: NSURLResponse!, responseObject: AnyObject!, error: NSError!) -> Void in
            let status = (response as? NSHTTPURLResponse)?.statusCode ?? 0
            if error != nil || status != 200 {
                song.status = .Failed("Send: \(error)")
            } else {
                song.status = .Posted
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                if let p = progress {
                    p.removeObserver(self, forKeyPath: kNSProgressCompletedKey)
                    for i in 0...self.songIDToProgressMap.count {
                        if self.songIDToProgressMap[i].0 === song {
                            self.songIDToProgressMap.removeAtIndex(i)
                            break
                        }
                    }
                }
                completion?()
            }
        }
        if let p = progress {
            p.addObserver(self, forKeyPath: kNSProgressCompletedKey, options: NSKeyValueObservingOptions.allZeros, context: nil)
            songIDToProgressMap += [(song, p)]
        }
        
        uploadTask.resume()
    }
    
    override func observeValueForKeyPath(keyPath: String!, ofObject object: AnyObject!, change: [NSObject : AnyObject]!, context: UnsafeMutablePointer<Void>) {
        if object is NSProgress {
            for (song, progress) in songIDToProgressMap {
                if progress === object {
//                    println("progress: \(progress.fractionCompleted) for \(song)")
                    song.status = .Posting(Float(progress.fractionCompleted))
                    return
                }
            }
            return
        }
        super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
    }
    
    func loadNowPlaying() {        
        let manager = AFHTTPRequestOperationManager()
        manager.responseSerializer = AFJSONResponseSerializer()
        manager.GET(baseURL.URLByAppendingPathComponent(kSongsIndexJSON).absoluteString, parameters: nil, success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) -> Void in
            if let np = PPSNowPlaying(JSON: responseObject as? Dictionary) as PPSNowPlaying? {
                self.nowPlaying = np
            } else {
                println("cannot get nowPlaying from json: \(responseObject)")
            }
        }, failure: { (_:AFHTTPRequestOperation!, error:NSError!) -> Void in
            println("\(kSongsIndexJSON) failed: \(error)")
        })
    }
    
    func skip() {
        let manager = AFHTTPRequestOperationManager()
        manager.responseSerializer = AFJSONResponseSerializer()
        manager.POST(baseURL.URLByAppendingPathComponent(kSongsSkip).absoluteString, parameters: nil,
            success: {(_: AFHTTPRequestOperation!, _: AnyObject!) in },
            failure: {(_:AFHTTPRequestOperation!, _:NSError!) in })
    }
}