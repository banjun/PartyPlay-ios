//
//  ClientViewController.swift
//  PartyPlay
//
//  Created by BAN Jun on 2015/08/19.
//  Copyright © 2015年 banjun. All rights reserved.
//

import UIKit
import NorthLayout
import MultipeerConnectivity
import MediaPlayer
import AVKit


class ClientViewController: UIViewController {
    private let client: PartyPlayClient
    
    private lazy var postButton: UIButton = {
        let b = Appearance.createButton()
        b.setTitle(LocalizedString.postSongs, forState: .Normal)
        b.addTarget(self, action: "post:", forControlEvents: .TouchUpInside)
        return b
    }()
    
    init(client: PartyPlayClient) {
        self.client = client
        
        super.init(nibName: nil, bundle: nil)
        
        title = client.server.displayNameWithoutPrefix
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        
        edgesForExtendedLayout = .None
        view.backgroundColor = Appearance.backgroundColor
        
        let autolayout = view.northLayoutFormat(["p": 20], [
            "post": postButton
            ])
        autolayout("H:|-p-[post]-p-|")
        autolayout("V:|-p-[post]")
    }
    
    @IBAction private func post(sender: AnyObject?) {
        let player = MPMusicPlayerController.systemMusicPlayer()
        if  let mediaItem = player.nowPlayingItem,
            let assetURL = mediaItem.assetURL,
            let session = AVAssetExportSession(asset: AVAsset(URL: assetURL), presetName: AVAssetExportPresetAppleM4A),
            let fileType = session.supportedFileTypes.first {
                session.outputFileType = fileType
                let tmpFileURL = NSURL(fileURLWithPath: "\(NSTemporaryDirectory())/export.m4a")
                do { try NSFileManager.defaultManager().removeItemAtURL(tmpFileURL) } catch _ {}
                session.outputURL = tmpFileURL
                session.exportAsynchronouslyWithCompletionHandler {
                    NSLog("%@", "session completed with status = \(session.status.rawValue), error = \(session.error)")
                    self.client.sendSong(tmpFileURL, name: mediaItem.title ?? "unknown")
                }
        }
    }
}
