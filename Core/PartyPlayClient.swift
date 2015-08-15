//
//  PartyPlayClient.swift
//  Multipeer
//
//  Created by BAN Jun on 8/15/15.
//  Copyright © 2015 banjun. All rights reserved.
//

import Foundation
import MultipeerConnectivity


class PartyPlayClient: NSObject {
    private let session: MCSession
    private let browser: MCNearbyServiceBrowser
    
    var peers: [MCPeerID] { return session.connectedPeers }
    var servers: [MCPeerID] { return peers.filter{$0.isServer} }
    var clients: [MCPeerID] { return peers.filter{$0.isClient} }
    var onStateChange: ((Void) -> Void)?
    
    init(name: String, onStateChange: ((Void) -> Void)? = nil) {
        session = MCSession(peer: MCPeerID(displayName: PartyPlay.clientPrefix + name))
        browser = MCNearbyServiceBrowser(peer: session.myPeerID, serviceType: PartyPlay.serviceType)
        super.init()
        session.delegate = self
        browser.delegate = self
        self.onStateChange = onStateChange
    }
    
    func start() {
        browser.startBrowsingForPeers()
    }
    
    func send(data: NSData) {
        guard let server = peers.filter({$0.displayName.hasPrefix(PartyPlay.serverPrefix)}).first else { return }
        do {
            try session.sendData(data, toPeers: [server], withMode: .Reliable)
        } catch let error as NSError {
            NSLog("cannot send data to peer \(server): \(error.localizedDescription)")
        }
    }
}

// MARK: MCSessionDelegate
extension PartyPlayClient: MCSessionDelegate {
    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        dispatch_async(dispatch_get_main_queue()) {
            NSLog("%@", "Browser: peer = \(peerID), state = \(state.rawValue). total peers = \(self.peers.count)")
            self.onStateChange?()
        }
    }
    
    func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress) {
        
    }
    
    func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {
        
    }
}


// MARK: MCNearbyServiceBrowserDelegate
extension PartyPlayClient: MCNearbyServiceBrowserDelegate {
    func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        NSLog("%@", "PartyPlayClient found peer: \(peerID). auto-connect.")
        
        browser.invitePeer(peerID, toSession: session, withContext: nil, timeout: 30)
    }
    
    func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        NSLog("%@", "PartyPlayClient lost peer: \(peerID)")
    }
    
    func browser(browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: NSError) {
        NSLog("%@", "PartyPlayClient did not start: \(error.localizedDescription)")
    }
}