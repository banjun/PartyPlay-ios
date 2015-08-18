//
//  ClientViewController.swift
//  PartyPlay
//
//  Created by BAN Jun on 2015/08/19.
//  Copyright © 2015年 banjun. All rights reserved.
//

import UIKit
import NorthLayout
import MultipeerConnectivity


class ClientViewController: UIViewController {
    private let client: PartyPlayClient
    
    init(client: PartyPlayClient) {
        self.client = client
        
        super.init(nibName: nil, bundle: nil)
        
        title = client.server.displayNameWithoutPrefix
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        
        edgesForExtendedLayout = .None
        view.backgroundColor = Appearance.backgroundColor
        
        client.send(("hogehoge" as NSString).dataUsingEncoding(NSUTF8StringEncoding)!)
    }
}
