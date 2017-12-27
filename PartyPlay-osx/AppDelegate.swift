//
//  AppDelegate.swift
//  PartyPlay-osx
//
//  Created by BAN Jun on 8/15/15.
//  Copyright © 2015 banjun. All rights reserved.
//

import Cocoa
import NorthLayout


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    let mainViewController = MainViewController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let cv = window.contentView {
            let autolayout = cv.northLayoutFormat([:],[
            "main": mainViewController.view
                ])
            autolayout("H:|[main]|")
            autolayout("V:|[main]|")
        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
}

