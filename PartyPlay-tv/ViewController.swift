//
//  ViewController.swift
//  PartyPlay-tv
//
//  Created by BAN Jun on 2015/09/10.
//  Copyright © 2015年 banjun. All rights reserved.
//

import UIKit
import AVKit


class ViewController: UIViewController {
    let player = AVQueuePlayer()
    
    let titleLabel = UILabel()
    let artistLabel = UILabel()
    let albumLabel = UILabel()
    let timePlayedLabel = UILabel()
    let timeRemainingLabel = UILabel()
    let artworkView = UIImageView(image: nil)
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        title = LocalizedString.titleServer
        
        player.addPeriodicTimeObserverForInterval(CMTime(seconds: 1, preferredTimescale: 1), queue: dispatch_get_main_queue(), usingBlock: { _ in
            self.updateTimeLabels()
        })
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
        titleLabel.adjustsFontSizeToFitWidth = true
        artistLabel.font = UIFont.systemFontOfSize(54)
        artistLabel.adjustsFontSizeToFitWidth = true
        artistLabel.numberOfLines = 2
        albumLabel.font = UIFont.systemFontOfSize(54)
        albumLabel.adjustsFontSizeToFitWidth = true
        timePlayedLabel.font = UIFont.monospacedDigitSystemFontOfSize(36, weight: UIFontWeightSemibold)
        timeRemainingLabel.font = timePlayedLabel.font
        artworkView.contentMode = .ScaleAspectFit
        
        let views: [String: UIView] = [
            "title": titleLabel,
            "artist": artistLabel,
            "album": albumLabel,
            "timePlayed": timePlayedLabel,
            "timeRemaining": timeRemainingLabel,
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
        autolayout("H:[artwork]-p-[album]-lp-|")
        autolayout("H:[artwork]-p-[timePlayed]-(>=p)-[timeRemaining]-lp-|")
        autolayout("V:|-lp-[artwork]-lp-|")
        autolayout("V:|-lp-[title]-[artist]-[album]")
        autolayout("V:[album]-(>=p)-[timePlayed]-lp-|")
        autolayout("V:[album]-(>=p)-[timeRemaining]-lp-|")
        
        view.addConstraint(NSLayoutConstraint(item: artworkView, attribute: .Width, relatedBy: .Equal, toItem: artworkView, attribute: .Height, multiplier: 1, constant: 0))
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // simulate once store a posted audio file to tmp and use it
        let dummyFileURL = URL(fileURLWithPath: NSBundle.mainBundle().pathForResource("okaeri", ofType: "m4a")!)
        let tmpFileURL = URL(fileURLWithPath: NSTemporaryDirectory() + "/audio.m4a")
        let _ = try? NSFileManager.defaultManager().copyItemAtURL(dummyFileURL, toURL: tmpFileURL)
        
        addAudioFileToPlaylist(tmpFileURL)
    }
    
    private func addAudioFileToPlaylist(file: URL) {
        player.insertItem(AVPlayerItem(URL: file), afterItem: nil)
        if player.rate == 0.0 {
            player.play()
            updateViews()
        }
    }
    
    private func updateViews() {
        if let item = player.currentItem {
            let asset = item.asset
            for metadataItem in asset.commonMetadata {
                NSLog("%@", "item[\(metadataItem.commonKey)], dataType = \(metadataItem.dataType)")
                switch metadataItem.commonKey {
                case AVMetadataCommonKeyTitle?:
                    titleLabel.text = metadataItem.stringValue
                case AVMetadataCommonKeyArtist?:
                    artistLabel.text = metadataItem.stringValue
                case AVMetadataCommonKeyAlbumName?:
                    albumLabel.text = metadataItem.stringValue
                case AVMetadataCommonKeyArtwork?:
                    if let data = metadataItem.dataValue {
                        artworkView.image = UIImage(data: data)
                    }
                default:
                    break
                }
            }
        } else {
            titleLabel.text = "No Music to Play"
            artistLabel.text = nil
            albumLabel.text = nil
            artworkView.image = nil
        }
        
        updateTimeLabels()
    }
    
    private func updateTimeLabels() {
        guard let duration = player.currentItem?.duration,
            let timePlayed = CMTime?.Some(player.currentTime()) where CMTIME_IS_NUMERIC(timePlayed) && timePlayed.seconds >= 0,
            let timeRemaining = CMTime?.Some(duration - timePlayed) where CMTIME_IS_NUMERIC(timeRemaining) && timeRemaining.seconds >= 0 else {
                self.timePlayedLabel.text = nil
                self.timeRemainingLabel.text = nil
                return
        }
        
        let minutesPlayed = Int(floor(timePlayed.seconds / 60))
        let secondsPlayed = Int(floor(timePlayed.seconds % 60))
        self.timePlayedLabel.text = String(format: "%d:%02d", arguments: [minutesPlayed, secondsPlayed])
        
        let minutesRemaining = Int(floor(timeRemaining.seconds / 60))
        let secondsRemaining = Int(floor(timeRemaining.seconds % 60))
        self.timeRemainingLabel.text = String(format: "-%d:%02d", arguments: [minutesRemaining, secondsRemaining])
    }
}

