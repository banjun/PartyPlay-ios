//
//  ViewController.swift
//  PartyPlay
//
//  Created by BAN Jun on 8/15/15.
//  Copyright © 2015 banjun. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        title = kAppName
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        
        view.backgroundColor = Appearance.backgroundColor
    }
}
