//
//  PPSSelectViewController.h
//  AirHack
//
//  Created by banjun on 2014/07/12.
//  Copyright (c) 2014年 banjun. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PPSSelectViewController : UITableViewController

- (instancetype)initWithCurrentBaseURL:(NSURL *)currentBaseURL;

@property (nonatomic, copy) void (^didSelect)(NSURL *rootURL);

@end
