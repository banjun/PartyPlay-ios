//
//  PlayingsViewController.h
//  AirHack
//
//  Created by banjun on 2014/07/13.
//  Copyright (c) 2014年 banjun. All rights reserved.
//

#import "WebViewController.h"
#import "PPSClient.h"

@interface PlayingsViewController : WebViewController

- (instancetype)initWithClient:(PPSClient *)client;

@end
