//
//  ViewController.swift
//  PartyPlay-tv
//
//  Created by BAN Jun on 2015/09/10.
//  Copyright © 2015年 banjun. All rights reserved.
//

import UIKit
import AVKit
import MediaPlayer


class ViewController: UIViewController {
    let player = AVQueuePlayer()
    
    let titleLabel = UILabel()
    let artistLabel = UILabel()
    let artworkView = UIImageView(image: nil)
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        title = LocalizedString.titleServer
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        
        edgesForExtendedLayout = .None
//        view.backgroundColor = Appearance.backgroundColor
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: LocalizedString.shutdown, style: .Plain, target: self, action: "shutdown:")
        
        titleLabel.font = UIFont.boldSystemFontOfSize(72)
        titleLabel.adjustsFontSizeToFitWidth = true  // not work in Xcode 7.1b1
        artistLabel.font = UIFont.systemFontOfSize(72)
        artistLabel.adjustsFontSizeToFitWidth = true // not work in Xcode 7.1b1
        artistLabel.numberOfLines = 2
        artworkView.contentMode = .ScaleAspectFit
        
        let views: [String: UIView] = [
            "title": titleLabel,
            "artist": artistLabel,
            "artwork": artworkView,
        ]
        for (_, v) in views {
            v.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(v)
        }
        let metrics: [String: AnyObject] = ["p": 32, "lp": 64]
        let autolayout =  { (format: String) -> Void in
            self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(format, options: [], metrics: metrics, views: views))
        }
        
        autolayout("H:|-lp-[artwork]")
        autolayout("H:[artwork]-p-[title]-lp-|")
        autolayout("H:[artwork]-p-[artist]-lp-|")
        autolayout("V:|-lp-[artwork]-lp-|")
        autolayout("V:|-lp-[title]-[artist]-(>=lp)-|")
        
        view.addConstraint(NSLayoutConstraint(item: artworkView, attribute: .Width, relatedBy: .Equal, toItem: artworkView, attribute: .Height, multiplier: 1, constant: 0))
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        
        
        // simulate once store a posted audio file to tmp and use it
        let dummyFileURL = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("okaeri", ofType: "m4a")!)
        let tmpFileURL = NSURL(fileURLWithPath: NSTemporaryDirectory() + "/audio.m4a")
        let _ = try? NSFileManager.defaultManager().copyItemAtURL(dummyFileURL, toURL: tmpFileURL)
        
        let asset = AVAsset(URL: dummyFileURL)
        for item in asset.commonMetadata {
            NSLog("%@", "item[\(item.commonKey)], dataType = \(item.dataType)")
            switch item.commonKey {
            case AVMetadataCommonKeyTitle?:
                titleLabel.text = item.stringValue
            case AVMetadataCommonKeyArtist?:
                artistLabel.text = item.stringValue
            case AVMetadataCommonKeyArtwork?:
                if let data = item.dataValue {
                    artworkView.image = UIImage(data: data)
                }
            default:
                break
            }
        }
        
        
        player.insertItem(AVPlayerItem(URL: tmpFileURL), afterItem: nil)
        
//        let pc = AVPlayerViewController()
//        pc.player = player
//        navigationController?.pushViewController(pc, animated: true)
        
        player.play()
    }
}

