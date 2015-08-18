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
    let server: MCPeerID
    var serverStateOnSession = MCSessionState.NotConnected
    
    init(session: MCSession, server: MCPeerID) {
        self.session = session
        self.server = server
    }
    
    func send(data: NSData) {
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
        if peerID == server {
            serverStateOnSession = state
            NSLog("%@", "server state changed to \(serverStateOnSession).")
            
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
