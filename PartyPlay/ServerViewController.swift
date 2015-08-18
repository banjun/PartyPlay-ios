//
//  ServerViewController.swift
//  PartyPlay
//
//  Created by BAN Jun on 2015/08/18.
//  Copyright © 2015年 banjun. All rights reserved.
//

import UIKit


class ServerViewController: UIViewController {
    let server: PartyPlayServer
    
    init() {
        server = PartyPlayServer(name: UIDevice.currentDevice().name)
        
        super.init(nibName: nil, bundle: nil)
        
        title = NSLocalizedString("Party Play Server", comment: "")
        server.onStateChange = onServerStateChange
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        
        view.backgroundColor = Appearance.backgroundColor
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: LocalizedString.shutdown, style: .Plain, target: self, action: "shutdown:")
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        server.start()
    }
    
    private func onServerStateChange() {
        NSLog("%@", "server.peers = \(server.peers)")
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
