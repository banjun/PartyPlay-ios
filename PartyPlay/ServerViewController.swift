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
        
        let autolayout = view.northLayoutFormat(["p": 8], [
            "status": connectionStatusLabel,
            ])
        autolayout("H:|-p-[status]-p-|")
        autolayout("V:|-p-[status]")
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        server.start()
    }
    
    private func onServerStateChange() {
        let numberOfPeers = server.peers.reduce(0, combine: {$0 + $1.count})
        connectionStatusLabel.text = String(format: LocalizedString.nPeersCurrentlyConnected, arguments: [numberOfPeers])
    }
    
    private func onReceiveResource(localURL: NSURL) {
        if self !== navigationController?.topViewController {
            navigationController?.popToViewController(self, animated: false)
        }
        
        let pvc = AVPlayerViewController()
        let player = AVPlayer(URL: localURL)
        pvc.player = player
        navigationController?.pushViewController(pvc, animated: true)
        player.play()
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

