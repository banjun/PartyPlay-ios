//
//  PartyPlayServiceBrowser.swift
//  Multipeer
//
//  Created by BAN Jun on 8/15/15.
//  Copyright © 2015 banjun. All rights reserved.
//

import Foundation
import MultipeerConnectivity


class PartyPlayServiceBrowser: NSObject {
    private let myPeerID: MCPeerID
    private let browser: MCNearbyServiceBrowser
    
    /// 1 session per 1 server, 1 session have multiple peers
    var sessions: [MCSession] = []
    
    var onStateChange: ((Void) -> Void)?
    
    init(name: String, onStateChange: ((Void) -> Void)? = nil) {
        myPeerID = MCPeerID(displayName: PartyPlay.clientPrefix + name)
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: PartyPlay.serviceType)
        super.init()
        browser.delegate = self
        self.onStateChange = onStateChange
    }
    
    func start() {
        browser.startBrowsingForPeers()
    }
    
    func stop() {
        browser.stopBrowsingForPeers()
    }
}

// MARK: MCSessionDelegate
extension PartyPlayServiceBrowser: MCSessionDelegate {
    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        dispatch_async(dispatch_get_main_queue()) {
            NSLog("%@", "Browser: peer = \(peerID), state = \(state.rawValue). allPeers = \(self.sessions)")
            
            switch state {
            case .NotConnected:
                guard let removedIndex = self.sessions.indexOf(session) else { break }
                self.sessions.removeAtIndex(removedIndex)
            case .Connecting: break
            case .Connected: break
            }
            
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
extension PartyPlayServiceBrowser: MCNearbyServiceBrowserDelegate {
    func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        dispatch_async(dispatch_get_main_queue()) {
            if !peerID.isServer { return }
            NSLog("%@", "PartyPlayServiceBrowser found server: \(peerID). auto-connect.")
            
            let session = MCSession(peer: self.myPeerID)
            session.delegate = self
            self.sessions.append(session)
            
            browser.invitePeer(peerID, toSession: session, withContext: nil, timeout: 30)
        }
    }
    
    func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        NSLog("%@", "PartyPlayServiceBrowser lost peer: \(peerID)")
    }
    
    func browser(browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: NSError) {
        NSLog("%@", "PartyPlayServiceBrowser did not start: \(error.localizedDescription)")
    }
}
