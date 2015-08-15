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
    private let session: MCSession
    private let advertiser: MCNearbyServiceAdvertiser
    
    var peers: [MCPeerID] { return session.connectedPeers }
    var onStateChange: ((Void) -> Void)?
    
    init(name: String, onStateChange: ((Void) -> Void)? = nil) {
        session = MCSession(peer: MCPeerID(displayName: PartyPlay.serverPrefix + name))
        advertiser = MCNearbyServiceAdvertiser(peer: session.myPeerID, discoveryInfo: nil, serviceType: PartyPlay.serviceType)
        super.init()
        session.delegate = self
        advertiser.delegate = self
        self.onStateChange = onStateChange
    }
    
    func start() {
        advertiser.startAdvertisingPeer()
    }
}


// MARK: MCSessionDelegate
extension PartyPlayServer: MCSessionDelegate {
    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        dispatch_async(dispatch_get_main_queue()) {
            NSLog("%@", "Server: peer = \(peerID), state = \(state.rawValue). total peers = \(self.peers.count)")
            self.onStateChange?()
        }
    }
    
    func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
        NSLog("%@", "received data from \(peerID.displayName): \(NSString(data: data, encoding: NSUTF8StringEncoding))")
    }
    
    func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress) {
        
    }
    
    func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {
        
    }
}


// MARK: MCNearbyServiceAdvertiserDelegate
extension PartyPlayServer: MCNearbyServiceAdvertiserDelegate {
    func advertiser(advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: NSData?, invitationHandler: (Bool, MCSession) -> Void) {
        NSLog("%@", "incoming invitation request from \(peerID). auto-accept.")
        invitationHandler(true, session)
    }
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: NSError) {
        NSLog("%@", "cannot start Party Play Server. error = \(error.localizedDescription)")
    }
}
