//
//  PostViewController.m
//  AirHack
//
//  Created by banjun on 2014/07/07.
//  Copyright (c) 2014年 banjun. All rights reserved.
//

#import "PostViewController.h"
#import "BonjourFinder.h"
@import MediaPlayer;
@import AVFoundation;


@interface PostViewController ()

@property (nonatomic) UIButton *postButton;
@property (nonatomic) UITextField *urlField;
@property (nonatomic) UITextField *titleField;

@property (nonatomic) BonjourFinder *bonjourFinder;

@end


static NSString * const kPostURLKey = @"postURL";


@implementation PostViewController

- (void)loadView
{
    [super loadView];
    
    __weak typeof(self) weakSelf = self;
    
    self.bonjourFinder = [[BonjourFinder alloc] init];
    self.bonjourFinder.onServicesChange = ^{
        NSLog(@"services = %@", weakSelf.bonjourFinder.services);
    };
    [self.bonjourFinder searchForServicesOfType:@"_partyplay._tcp"];
    
    self.urlField = [[UITextField alloc] initWithFrame:CGRectZero];
    self.urlField.placeholder = @"http://mzp-tv.local.:3000/request";
    self.urlField.borderStyle = UITextBorderStyleRoundedRect;
    self.urlField.text = [[NSUserDefaults standardUserDefaults] stringForKey:kPostURLKey];
    
    self.titleField = [[UITextField alloc] initWithFrame:CGRectZero];
    
    self.postButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.postButton setTitle:@"Push Song" forState:UIControlStateNormal];
    [self.postButton addTarget:self action:@selector(retrieveCurrentMediaItem) forControlEvents:UIControlEventTouchUpInside];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_urlField, _titleField, _postButton);
    for (UIView *v in views.allValues) {
        v.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:v];
    }
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_urlField]-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_titleField]-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_postButton]-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-64-[_urlField]-20-[_titleField]-20-[_postButton]" options:0 metrics:nil views:views]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    MPMediaItem *item = [MPMusicPlayerController iPodMusicPlayer].nowPlayingItem;
    NSLog(@"item = %@", item);
    
    self.titleField.text = [item valueForProperty:MPMediaItemPropertyTitle];
}

- (void)retrieveCurrentMediaItem
{
    [[NSUserDefaults standardUserDefaults] setObject:self.urlField.text forKey:kPostURLKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    MPMediaItem *item = [MPMusicPlayerController iPodMusicPlayer].nowPlayingItem;
    NSLog(@"item = %@", item);
    
    NSURL *assetURL = [item valueForProperty:MPMediaItemPropertyAssetURL];
    NSLog(@"assetURL = %@", assetURL);
    
    AVAsset *asset = [AVAsset assetWithURL:assetURL];
    NSLog(@"asset = %@", asset);
    
    NSArray *presetNames = [AVAssetExportSession exportPresetsCompatibleWithAsset:asset];
    NSLog(@"presetNames = %@", presetNames);
    
    AVAssetExportSession *session = [AVAssetExportSession exportSessionWithAsset:asset presetName:AVAssetExportPresetAppleM4A];
    NSString *filename = [NSTemporaryDirectory() stringByAppendingPathComponent:@"export.m4a"];
    [[NSFileManager defaultManager] removeItemAtPath:filename error:nil];
    session.outputURL = [NSURL fileURLWithPath:filename];
    session.outputFileType = session.supportedFileTypes.firstObject;
    [session exportAsynchronouslyWithCompletionHandler:^{
        NSLog(@"export session completed.");
        [self pushFile:filename];
    }];
    NSLog(@"export session started: %@ (supportedFileTypes = %@)", session, session.supportedFileTypes);
}

- (void)pushFile:(NSString *)filename
{
    NSURL *url = [NSURL URLWithString:self.urlField.text];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    req.HTTPMethod = @"POST";
    req.HTTPBody = [NSData dataWithContentsOfFile:filename];
    [req addValue:[NSString stringWithFormat:@"%lu", (unsigned long)req.HTTPBody.length] forHTTPHeaderField:@"Content-Length"];
    [req addValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    
    NSLog(@"will post %lu bytes body to %@", (unsigned long)req.HTTPBody.length, req.URL);
    [NSURLConnection sendAsynchronousRequest:req queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
        NSInteger status = res.statusCode;
        NSString *message = [NSString stringWithFormat:@"finish post with status = %ld. connectionError = %@", (long)status, connectionError];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"%@", message);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Push Song" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        });
    }];
}

@end
