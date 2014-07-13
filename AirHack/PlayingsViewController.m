//
//  PlayingsViewController.m
//  AirHack
//
//  Created by banjun on 2014/07/13.
//  Copyright (c) 2014年 banjun. All rights reserved.
//

#import "PlayingsViewController.h"
#import "NSObject+BTKUtils.h"
#import <PromiseKit.h>

@interface PlayingsViewController ()

@property (nonatomic) PPSClient *client;

@end

@implementation PlayingsViewController

- (instancetype)initWithClient:(PPSClient *)client
{
    if (self = [super initWithURL:client.songsIndexHTMLURL]) {
        self.client = client;
    }
    return self;
}

- (void)loadView
{
    [super loadView];
    
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Skip", @"") style:UIBarButtonItemStylePlain target:self action:@selector(skip:)] btk_scope:^(UIBarButtonItem *b) {
        b.tintColor = [UIColor redColor];
    }];
}

- (IBAction)skip:(id)sender
{
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:nil cancelButtonTitle:NSLocalizedString(@"Cancel", @"") destructiveButtonTitle:NSLocalizedString(@"Skip", @"") otherButtonTitles:nil];
    [sheet promiseInView:self.webView].then(^(NSNumber *index){
        if (index.intValue == sheet.destructiveButtonIndex) {
            [self.client skip];
        }
    });
}

@end
