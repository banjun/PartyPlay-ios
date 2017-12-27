//
//  ServerViewController.swift
//  PartyPlay
//
//  Created by BAN Jun on 2015/08/18.
//  Copyright © 2015年 banjun. All rights reserved.
//

import UIKit
import NorthLayout


class ServerViewController: UIViewController {
    let server = PartyPlayServer(name: UIDevice.current.name)
    
    private let connectionStatusLabel = UILabel()
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        title = LocalizedString.titleServer
        server.onStateChange = onServerStateChange
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        
        view.backgroundColor = Appearance.backgroundColor
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: LocalizedString.shutdown, style: .plain, target: self, action: Selector(("shutdown:")))
        
        let autolayout = view.northLayoutFormat(["p": 8], [
            "status": connectionStatusLabel,
            ])
        autolayout("H:|-p-[status]-p-|")
        autolayout("V:|-p-[status]")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        server.start()
    }
    
    private func onServerStateChange() {
        let numberOfPeers = server.peers.reduce(0, {$0 + $1.count})
        connectionStatusLabel.text = String(format: LocalizedString.nPeersCurrentlyConnected, arguments: [numberOfPeers])
    }
    
    @IBAction private func shutdown(_ sender: AnyObject?) {
        let ac = UIAlertController(title: nil, message: LocalizedString.confirmShutdown, preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: LocalizedString.shutdown, style: .destructive) { _ in
            self.server.stop()
            self.dismiss(animated: true, completion: nil)
            })
        ac.addAction(UIAlertAction(title: LocalizedString.cancel, style: .cancel, handler: nil))
        present(ac, animated: true, completion: nil)
    }
}
