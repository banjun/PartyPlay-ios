//
//  PostQueueViewController.swift
//  AirHack
//
//  Created by BAN Jun on 2014/09/21.
//  Copyright (c) 2014年 banjun. All rights reserved.
//

import UIKit


class PostQueueViewController: UITableViewController {
    let queue: PostQueue
    private let kCellID = "Cell"
    private var timer: NSTimer? = nil
    var songs: [LocalSong]
    
    init(queue: PostQueue) {
        self.queue = queue
        self.songs = []
        super.init(style: .Plain)
        self.queue = queue // See below fix
    }
    
    // Need this to prevent runtime error:
    // fatal error: use of unimplemented initializer 'init(nibName:bundle:)'
    private override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: NSBundle!) {
        self.queue = PostQueue(client: PPSClient(baseURL: NSURL(string: "http://localhost/"))) // dummy
        self.songs = []
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.timer?.invalidate()
    }
    
    override func loadView() {
        super.loadView()
        
        tableView.registerClass(PostQueueTableViewCell.self, forCellReuseIdentifier: kCellID)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.timer?.invalidate()
        self.timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "updateViews", userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.timer?.invalidate()
        self.timer = nil
    }
    
    func updateViews() {
        songs = queue.localSongs // copy array
        self.tableView.reloadData()
    }
    
    // MARK: Table View
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(kCellID, forIndexPath: indexPath) as PostQueueTableViewCell
        
        let s = songs[indexPath.row]
        cell.textLabel?.text = s.mediaItem.title
        cell.detailTextLabel?.text = s.status.description
        cell.imageView?.image = s.artwork
        cell.progressView.indeterminate = s.status.indeterminate
        cell.progressView.progress = s.postProgress?.fractionCompleted ?? 0.0
        
        return cell
    }
}


class PostQueueTableViewCell : UITableViewCell {
    let progressView = CircleProgressView(frame: CGRectMake(0, 0, 44, 44))
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .Subtitle, reuseIdentifier: reuseIdentifier)
        self.accessoryView = progressView
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


class CircleProgressView : UIView {
    let shapeLayer = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        shapeLayer.strokeColor = Appearance.sharedInstance().tintColor.CGColor
        shapeLayer.fillColor = nil
        self.layer.addSublayer(shapeLayer)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        shapeLayer.frame = self.bounds
        shapeLayer.path = UIBezierPath(ovalInRect: CGRectInset(self.bounds, 4, 4)).CGPath
    }
    
    var indeterminate: Bool = false {
        didSet {
            switch (oldValue, indeterminate) {
            case (false, true):
                shapeLayer.lineWidth = 1
                shapeLayer.strokeStart = 0.1
                shapeLayer.strokeEnd = 1.0
                rotate()
            case (true, false):
                shapeLayer.lineWidth = 4
                shapeLayer.strokeStart = 0.0
                shapeLayer.strokeEnd = 0.0
                self.transform = CGAffineTransformIdentity
            default:
                break
            }
        }
    }
    
    var progress: Double = 0.0 {
        didSet {
            if !indeterminate {
                CATransaction.begin()
                CATransaction.setDisableActions(self.shapeLayer.strokeEnd >= CGFloat(self.progress))
                self.shapeLayer.strokeEnd = CGFloat(self.progress)
                CATransaction.commit()
            }
        }
    }
    
    func rotate() {
        if !self.indeterminate { return }
        
        UIView.animateWithDuration(1.0, delay: 0.0, options: UIViewAnimationOptions.CurveLinear, animations: { () -> Void in
            self.transform = CGAffineTransformRotate(self.transform, CGFloat(M_PI))
            }, completion: { (completed: Bool) in
                self.rotate()
        })
    }
}
