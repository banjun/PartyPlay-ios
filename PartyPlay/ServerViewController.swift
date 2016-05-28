//
//  ServerViewController.swift
//  PartyPlay
//
//  Created by BAN Jun on 2015/08/18.
//  Copyright © 2015年 banjun. All rights reserved.
//

import UIKit
import NorthLayout
import AVKit
import AVFoundation


class ServerViewController: UIViewController {
    let server = PartyPlayServeriOS(name: UIDevice.currentDevice().name)
    
    private let connectionStatusLabel = UILabel()
    private let artworkView = UIImageView(frame: .zero)
    private let titleLabel = UILabel()
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        title = LocalizedString.titleServer
        server.onStateChange = onServerStateChange
        server.onReceiveResource = onReceiveResource
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        
        edgesForExtendedLayout = .None
        view.backgroundColor = Appearance.backgroundColor
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: LocalizedString.shutdown, style: .Plain, target: self, action: "shutdown:")
        
        toolbarItems = [
            UIBarButtonItem(title: "Pause", style: .Plain, target: self, action: #selector(pause)),
            UIBarButtonItem(title: "Play", style: .Plain, target: self, action: #selector(play)),
            UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Skip", style: .Plain, target: self, action: #selector(next)),
            ]
        
        connectionStatusLabel.numberOfLines = 0
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .Center
        if #available(iOS 9.0, *) {
            titleLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleTitle1)
        }
        artworkView.contentMode = .ScaleAspectFit
        
        let autolayout = view.northLayoutFormat(["p": 8], [
            "status": connectionStatusLabel,
            "artwork": artworkView,
            "title": titleLabel,
            ])
        autolayout("H:|-p-[status]-p-|")
        autolayout("H:|-p-[artwork]-p-|")
        autolayout("H:|-p-[title]-p-|")
        autolayout("V:|-p-[status]-p-[artwork]-p-[title]-p-|")
        
        titleLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: .Vertical)
        titleLabel.setContentHuggingPriority(UILayoutPriorityRequired, forAxis: .Vertical)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setToolbarHidden(false, animated: animated)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        server.start()
    }
    
    private func onServerStateChange() {
        let numberOfPeers = server.peers.reduce(0, combine: {$0 + $1.count})
        connectionStatusLabel.text = String(format: LocalizedString.nPeersCurrentlyConnected, arguments: [numberOfPeers]) + "\n \(player.items().count) songs queued."
    }
    
    private let player = AVQueuePlayer(items: [])
    
    private func onReceiveResource(localURL: NSURL) {
        player.addPeriodicTimeObserverForInterval(CMTime(seconds: 1, preferredTimescale: 600), queue: dispatch_get_main_queue()) { time in
            let metadata = self.player.currentItem?.asset.commonMetadata
            if let title = metadata?.filter({$0.commonKey == "title"}).first?.value as? String {
                self.titleLabel.text = title
            } else {
                self.titleLabel.text = "----"
            }
            if let artwork = metadata?.filter({$0.commonKey == "artwork"}).first?.value as? NSData {
                self.artworkView.image = UIImage(data: artwork)
            }
            self.onServerStateChange()
        }
        
        let item = AVPlayerItem(URL: localURL)
        player.insertItem(item, afterItem: nil)
        
        if player.rate == 0 {
            player.play()
        }
        
        onServerStateChange()
    }
    
    @objc private func play() {
        player.play()
    }
    
    @objc private func pause() {
        player.pause()
    }
    
    @objc private func next() {
        player.advanceToNextItem()
    }
    
    @IBAction private func shutdown(sender: AnyObject?) {
        let ac = UIAlertController(title: nil, message: LocalizedString.confirmShutdown, preferredStyle: .ActionSheet)
        ac.addAction(UIAlertAction(title: LocalizedString.shutdown, style: .Destructive) { _ in
            self.server.stop()
            self.dismissViewControllerAnimated(true, completion: nil)
            })
        ac.addAction(UIAlertAction(title: LocalizedString.cancel, style: .Cancel, handler: nil))
        presentViewController(ac, animated: true, completion: nil)
    }
}


import MultipeerConnectivity
class PartyPlayServeriOS: PartyPlayServer {
    var onReceiveResource: (NSURL -> Void)?
    
    override func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {
        super.session(session, didFinishReceivingResourceWithName: resourceName, fromPeer: peerID, atURL: localURL, withError: error)
        dispatch_async(dispatch_get_main_queue()) {
            let m4aURL = localURL.URLByAppendingPathExtension("m4a") // FIXME:
            let _ = try? NSFileManager.defaultManager().moveItemAtURL(localURL, toURL: m4aURL)
            self.onReceiveResource?(m4aURL)
        }
    }
}

