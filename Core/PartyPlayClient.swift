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
    var serverStateOnSession = MCSessionState.notConnected
    
    init(session: MCSession, server: MCPeerID) {
        self.session = session
        self.server = server
    }
    
    func send(data: Data) {
        do {
            try session.send(data, toPeers: [server], with: .reliable)
        } catch let error as NSError {
            NSLog("cannot send data to peer \(server): \(error.localizedDescription)")
        }
    }
    
    func sendSong(fileURL: URL, name: String) -> Progress? {
        return session.sendResource(at: fileURL, withName: name, toPeer: server) { error in
            if let error = error {
                NSLog("%@", "sendSong(fileURL:_) error: \(error.localizedDescription)")
            } else {
                NSLog("%@", "sendSong(fileURL:_) completed")
            }
        }
    }
}

// MARK: MCSessionDelegate
extension PartyPlayClient: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        if peerID == server {
            serverStateOnSession = state
            NSLog("%@", "server state changed to \(serverStateOnSession).")
            
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
}
