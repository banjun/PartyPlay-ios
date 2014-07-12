//
//  PostViewController.m
//  AirHack
//
//  Created by banjun on 2014/07/07.
//  Copyright (c) 2014年 banjun. All rights reserved.
//

#import "PostViewController.h"
@import MediaPlayer;
@import AVFoundation;
#import "PPSSelectViewController.h"
#import "NSObject+BTKUtils.h"


@interface PostViewController ()

@property (nonatomic) UIButton *ppsSelectButton;
@property (nonatomic) UIButton *postButton;
@property (nonatomic) UITextField *urlField;
@property (nonatomic) UITextField *titleField;

@end


static NSString * const kPostURLKey = @"PostURL";


@implementation PostViewController

- (void)loadView
{
    [super loadView];
    
    self.title = NSLocalizedString(@"Party Play", @"");
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.ppsSelectButton = [[UIButton buttonWithType:UIButtonTypeRoundedRect] btk_scope:^(UIButton *b) {
        [b setTitle:@"Select Party Play Server" forState:UIControlStateNormal];
        [b addTarget:self action:@selector(showPPSSelectViewController:) forControlEvents:UIControlEventTouchUpInside];
    }];
    
    self.urlField = [[[UITextField alloc] initWithFrame:CGRectZero] btk_scope:^(UITextField *t) {
        t.placeholder = @"http://mzp-tv.local.:3000/";
        t.borderStyle = UITextBorderStyleRoundedRect;
    }];
    
    self.titleField = [[UITextField alloc] initWithFrame:CGRectZero];
    
    self.postButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.postButton setTitle:@"Push Song" forState:UIControlStateNormal];
    [self.postButton addTarget:self action:@selector(retrieveCurrentMediaItem) forControlEvents:UIControlEventTouchUpInside];
    
    [self loadDefaults];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_ppsSelectButton, _urlField, _titleField, _postButton);
    for (UIView *v in views.allValues) {
        v.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:v];
    }
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_ppsSelectButton]-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_urlField]-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_titleField]-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_postButton]-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-84-[_urlField]-20-[_ppsSelectButton]-20-[_titleField]-20-[_postButton]" options:0 metrics:nil views:views]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)loadDefaults
{
    self.urlField.text = [[NSUserDefaults standardUserDefaults] stringForKey:kPostURLKey];
}

- (void)saveDefaults
{
    if (self.urlField.text.length > 0) {
        [[NSUserDefaults standardUserDefaults] setObject:self.urlField.text forKey:kPostURLKey];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    MPMediaItem *item = [MPMusicPlayerController iPodMusicPlayer].nowPlayingItem;
    NSLog(@"item = %@", item);
    
    self.titleField.text = [item valueForProperty:MPMediaItemPropertyTitle];
}

- (void)retrieveCurrentMediaItem
{
    
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
    NSURL *url = [NSURL URLWithString:@"/songs/add" relativeToURL:[NSURL URLWithString:self.urlField.text]];
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

- (IBAction)showPPSSelectViewController:(id)sender
{
    __weak typeof(self) weakSelf = self;
    
    PPSSelectViewController *vc = [[PPSSelectViewController alloc] initWithStyle:UITableViewStyleGrouped];
    vc.didSelect = ^(NSURL *rootURL){
        NSLog(@"rootURL = %@", rootURL);
        weakSelf.urlField.text = rootURL.absoluteString;
        [weakSelf saveDefaults];
    };
    [self.navigationController pushViewController:vc animated:YES];
}

@end
