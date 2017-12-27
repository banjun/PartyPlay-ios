//
//  MainViewController.swift
//  PartyPlay
//
//  Created by BAN Jun on 8/23/15.
//  Copyright © 2015 banjun. All rights reserved.
//

import Cocoa
import NorthLayout


class MainViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    let becomeAServerButton: NSButton = {
        let b = NSButton()
        b.bezelStyle = .regularSquare
        b.attributedTitle = NSAttributedString(string: LocalizedString.becomeAServer, attributes: [
            NSForegroundColorAttributeName: Appearance.tintColor,
            NSParagraphStyleAttributeName: {
                let p = NSMutableParagraphStyle()
                p.alignment = .center
                return p
                }(),
            ])
        return b
    }()
    
    var server: PartyPlayServer?
    
    override func loadView() {
        view = NSView()
        
        becomeAServerButton.target = self
        becomeAServerButton.action = Selector(("becomeAServer:"))
        
        let autolayout = view.northLayoutFormat(["p": 20], [
            "server": becomeAServerButton,
            ])
        autolayout("H:|-p-[server]-p-|")
        autolayout("V:[server]-p-|")
    }
    
    @IBAction private func becomeAServer(sender: AnyObject?) {
        server = PartyPlayServer(name: ProcessInfo().hostName, onStateChange: onServerStateChange)
        server?.start()
        NSLog("%@", "starting server \(server)")
        becomeAServerButton.title = "Server Started"
        becomeAServerButton.isEnabled = false
    }
    
    private func onServerStateChange() {
        if let server = server {
            becomeAServerButton.title = "\(server.peers.count) peers connected"
        } else {
            becomeAServerButton.title = LocalizedString.becomeAServer
            becomeAServerButton.isEnabled = true
        }
    }
}
