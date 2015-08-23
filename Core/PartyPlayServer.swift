//
//  PartyPlayServer.swift
//  Multipeer
//
//  Created by BAN Jun on 8/14/15.
//  Copyright © 2015 banjun. All rights reserved.
//

import Foundation
import MultipeerConnectivity


class PartyPlayServer: NSObject {
    private let myPeerID: MCPeerID
    private var sessions = [MCSession]()
    private let advertiser: MCNearbyServiceAdvertiser
    
    var peers: [[MCPeerID]] { return sessions.map{$0.connectedPeers} }
    var onStateChange: ((Void) -> Void)?
    
    init(name: String, onStateChange: ((Void) -> Void)? = nil) {
        myPeerID = MCPeerID(displayName: PartyPlay.serverPrefix + name)
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: PartyPlay.serviceType)
        super.init()
        advertiser.delegate = self
        self.onStateChange = onStateChange
    }
    
    func start() {
        advertiser.startAdvertisingPeer()
    }
    
    func stop() {
        advertiser.stopAdvertisingPeer()
        sessions.forEach{$0.disconnect()}
        sessions.removeAll()
    }
}


// MARK: MCSessionDelegate
extension PartyPlayServer: MCSessionDelegate {
    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        dispatch_async(dispatch_get_main_queue()) {
            if state == .NotConnected, let index = self.sessions.indexOf(session) {
                self.sessions.removeAtIndex(index)
            }
            NSLog("%@", "Server: peer = \(peerID), state = \(state.rawValue). total peers = \(self.peers)")
            self.onStateChange?()
        }
    }
    
    func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
        NSLog("%@", "received data from \(peerID.displayName): \(NSString(data: data, encoding: NSUTF8StringEncoding))")
    }
    
    func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress) {
        NSLog("%@", "didStartReceivingResourceWithName from \(peerID.displayName): \(resourceName)")
    }
    
    func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {
        NSLog("%@", "didFinishReceivingResourceWithName from \(peerID.displayName): \(localURL), error = \(error?.localizedDescription)")
    }
}


// MARK: MCNearbyServiceAdvertiserDelegate
extension PartyPlayServer: MCNearbyServiceAdvertiserDelegate {
    func advertiser(advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: NSData?, invitationHandler: (Bool, MCSession) -> Void) {
        dispatch_async(dispatch_get_main_queue()) {
            NSLog("%@", "incoming invitation request from \(peerID). auto-accept with new session.")
            
            let session = MCSession(peer: self.myPeerID)
            session.delegate = self
            self.sessions.append(session)
            invitationHandler(true, session)
        }
    }
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: NSError) {
        NSLog("%@", "cannot start Party Play Server. error = \(error.localizedDescription)")
    }
}
