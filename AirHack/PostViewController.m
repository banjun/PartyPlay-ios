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
#import <SVProgressHUD.h>
#import "PPSClient.h"
#import <PromiseKit.h>
#import "PlayingsViewController.h"


@interface PostViewController () <MPMediaPickerControllerDelegate>

@property (nonatomic) MPMusicPlayerController *iPodController;
@property (nonatomic) MPMediaItem *nowPlayingItem;
@property (nonatomic) NSString *serverURLString;

@property (nonatomic) PPSClient *client;

@property (nonatomic) UILabel *serverLabel;
@property (nonatomic) UIButton *postButton;
@property (nonatomic) UIButton *pickButton;
@property (nonatomic) MPMediaPickerController *picker;

@end


static NSString * const kPostURLKey = @"PostURL";


@implementation PostViewController

- (void)loadView
{
    [super loadView];
    
    self.title = NSLocalizedString(@"Party Play", @"");
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.serverLabel = [[[UILabel alloc] initWithFrame:CGRectZero] btk_scope:^(UILabel *l) {
    }];
    
    self.postButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.postButton setTitle:@"Push Current Song" forState:UIControlStateNormal];
    [self.postButton addTarget:self action:@selector(pushCurrentSong:) forControlEvents:UIControlEventTouchUpInside];
    
    self.pickButton = [[UIButton buttonWithType:UIButtonTypeRoundedRect] btk_scope:^(UIButton *b) {
        [b setTitle:NSLocalizedString(@"Pick iPod Songs", @"") forState:UIControlStateNormal];
        [b addTarget:self action:@selector(showPicker:) forControlEvents:UIControlEventTouchUpInside];
    }];
    
    [self loadDefaults];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_serverLabel, _postButton, _pickButton);
    for (UIView *v in views.allValues) {
        v.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:v];
    }
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_serverLabel]-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_postButton]-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_pickButton]-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-84-[_serverLabel]-20-[_postButton]-20-[_pickButton]" options:0 metrics:nil views:views]];
    
    self.iPodController = [[MPMusicPlayerController iPodMusicPlayer] btk_scope:^(MPMusicPlayerController *c) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nowPlayingChanged:) name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification object:c];
        [c beginGeneratingPlaybackNotifications];
    }];
    
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Settings", @"") style:UIBarButtonItemStylePlain target:self action:@selector(showSettings:)] btk_scope:^(UIBarButtonItem *b) {
        b.tintColor = [UIColor grayColor];
    }];
    
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Now Playing", @"") style:UIBarButtonItemStylePlain target:self action:@selector(showNowPlaying:)] btk_scope:^(UIBarButtonItem *b) {
        b.tintColor = [UIColor colorWithRed:0 green:160/255.0 blue:0 alpha:1.0];
    }];
}

- (void)loadDefaults
{
    self.serverURLString = [[NSUserDefaults standardUserDefaults] stringForKey:kPostURLKey];
}

- (void)saveDefaults
{
    if (self.serverURLString.length > 0) {
        [[NSUserDefaults standardUserDefaults] setObject:self.serverURLString forKey:kPostURLKey];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setServerURLString:(NSString *)serverURLString
{
    _serverURLString = serverURLString;
    self.serverLabel.text = (serverURLString.length > 0 ? serverURLString : NSLocalizedString(@"Settings Required", @""));
    [self setupPPSClient];
}

- (PPSClient *)setupPPSClient
{
    NSURL *url = [NSURL URLWithString:self.serverURLString];
    self.client = (url ? [[PPSClient alloc] initWithBaseURL:url] : nil);
    return self.client;
}

#pragma mark - Music Player

- (void)nowPlayingChanged:(NSNotification *)notification
{
    self.nowPlayingItem = [MPMusicPlayerController iPodMusicPlayer].nowPlayingItem;
    NSString *title = @"iPod Stopped";
    if (self.nowPlayingItem) {
        title = [NSString stringWithFormat:@"Push %@", [self.nowPlayingItem valueForProperty:MPMediaItemPropertyTitle]];
    }
    [self.postButton setTitle:title forState:UIControlStateNormal];
    self.postButton.enabled = (self.nowPlayingItem != nil);
}

#pragma mark - Media Picker

- (IBAction)showPicker:(id)sender
{
    if (!self.client) {
        [self showInvalidURLAlert];
        return;
    }
    
    self.picker = [[[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeAny] btk_scope:^(MPMediaPickerController *p) {
        p.delegate = self;
        p.allowsPickingMultipleItems = YES;
        p.showsCloudItems = NO; // cannot export iCloud Items currently
    }];
    [self presentViewController:self.picker animated:YES completion:nil];
}

- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection;
{
    NSLog(@"picked %lu items", (unsigned long)mediaItemCollection.count);
    
    [self.picker dismissViewControllerAnimated:YES completion:^{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Push %lu Songs", (unsigned long)mediaItemCollection.count]
                                                        message:nil delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Push", nil];
        alert.promise.then(^(NSNumber *buttonIndex) {
            if (buttonIndex.intValue != alert.cancelButtonIndex) {
                [self exportMediaItemsAndPush:mediaItemCollection.items];
            }
        });
        
        self.picker = nil;
    }];
}

- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker;
{
    [self.picker dismissViewControllerAnimated:YES completion:^{ self.picker = nil; }];
}

#pragma mark -

- (void)exportMediaItems:(NSArray *)mediaItems completion:(void (^)(NSArray *songs))completion failure:(void (^)(void))failure
{
    if (!self.client) {
        [self showInvalidURLAlert];
        return;
    }
    
    [SVProgressHUD appearance].backgroundColor = [UIColor blackColor];
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
    [SVProgressHUD show];
    
    NSString *exportFolder = [NSTemporaryDirectory() stringByAppendingString:@"export"];
    [[NSFileManager defaultManager] removeItemAtPath:exportFolder error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:exportFolder withIntermediateDirectories:YES attributes:nil error:nil];
    
    NSMutableArray *songs = [NSMutableArray array];
    [mediaItems enumerateObjectsUsingBlock:^(MPMediaItem *item, NSUInteger idx, BOOL *stop) {
        NSString *filePath = [exportFolder stringByAppendingFormat:@"/%lu.m4a", (unsigned long)idx];
        PPSLocalSong *song = [[PPSLocalSong alloc] initWithMedia:item filePath:filePath];
        [songs addObject:song];
    }];
    
    NSMutableArray *sessions = [NSMutableArray array];
    
    [songs enumerateObjectsUsingBlock:^(PPSLocalSong *song, NSUInteger idx, BOOL *stop) {
        NSURL *assetURL = [song.mediaItem valueForProperty:MPMediaItemPropertyAssetURL];
        AVAsset *asset = [AVAsset assetWithURL:assetURL];
        
        AVAssetExportSession *session = [AVAssetExportSession exportSessionWithAsset:asset presetName:AVAssetExportPresetAppleM4A];
        if (!session) {
            [sessions enumerateObjectsUsingBlock:^(AVAssetExportSession *s, NSUInteger idx, BOOL *stop) {
                [s cancelExport];
            }];
            failure();
            *stop = YES;
            return;
        }
        session.outputURL = [NSURL fileURLWithPath:song.filePath];
        session.outputFileType = session.supportedFileTypes.firstObject;
        
        [sessions addObject:session];
        [session exportAsynchronouslyWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [sessions removeObject:session];
                
                NSUInteger length = [(NSData *)[NSData dataWithContentsOfFile:song.filePath] length];
                
                if (session.error || length == 0) {
                    NSLog(@"export session failed for song: %@ (%lu bytes): %@", song.title, (unsigned long)length, session.error);
                    [sessions enumerateObjectsUsingBlock:^(AVAssetExportSession *s, NSUInteger idx, BOOL *stop) {
                        [s cancelExport];
                    }];
                    failure();
                    *stop = YES;
                    return;
                } else {
                    NSLog(@"export session completed for song: %@ (%lu bytes)", song.title, (unsigned long)length);
                    if (sessions.count == 0) {
                        NSLog(@"all export sessions completed.");
                        completion(songs);
                    }
                }
            });
        }];
    }];
}

- (void)exportMediaItemsAndPush:(NSArray *)mediaItems
{
    [self exportMediaItems:mediaItems completion:^(NSArray *songs) {
        [self pushSongs:songs];
    } failure:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            NSLog(@"song export failed at some songs.");
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Export Song(s)" message:@"song export failed at some songs." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        });
    }];
}

- (void)pushSongs:(NSArray *)songs
{
    if (!self.client) {
        [self showInvalidURLAlert];
        return;
    }
    
    [SVProgressHUD appearance].backgroundColor = [UIColor blackColor];
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
    [SVProgressHUD show];
    
    [songs enumerateObjectsUsingBlock:^(PPSLocalSong *song, NSUInteger idx, BOOL *stop) {
        __weak typeof(song) weakSong = song;
        song.onUploadProgress = ^(float progress) {
            __block float totalProgress = 0.0;
            [songs enumerateObjectsUsingBlock:^(PPSLocalSong *song, NSUInteger idx, BOOL *stop) {
                totalProgress += song.uploadProgress.fractionCompleted / songs.count;
            }];
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"%@ progress = %f, total = %f", weakSong.title, progress, totalProgress);
                [SVProgressHUD showProgress:totalProgress];
            });
        };
    }];
    
    [self.client pushSongs:songs progress:^(float progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"progress = %f", progress);
            [SVProgressHUD showProgress:progress];
        });
    } didPushSong:^(PPSLocalSong *song) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"pushed %@", song.title);
        });
    } completion:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"pushed all request songs");
            [SVProgressHUD showSuccessWithStatus:@"Pushed!"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
            });
        });
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            NSLog(@"push failed at some songs: %@", error);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Push Song(s)" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        });
    }];
}

- (IBAction)pushCurrentSong:(id)sender
{
    if (!self.nowPlayingItem) {
        NSLog(@"current item not found");
        return;
    }
    [self exportMediaItemsAndPush:@[self.nowPlayingItem]];
}

- (IBAction)showSettings:(id)sender
{
    __weak typeof(self) weakSelf = self;
    
    PPSSelectViewController *vc = [[PPSSelectViewController alloc] initWithCurrentBaseURL:[NSURL URLWithString:self.serverURLString]];
    vc.didSelect = ^(NSURL *baseURL){
        NSLog(@"baseURL = %@", baseURL);
        weakSelf.serverURLString = baseURL.absoluteString;
        [weakSelf saveDefaults];
    };
    
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nc animated:YES completion:nil];
}

- (void)showInvalidURLAlert
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"Cannot connect to the server.", @"") delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
    [alert show];
}

- (IBAction)showNowPlaying:(id)sender
{
    if (!self.client) {
        [self showInvalidURLAlert];
        return;
    }
    
    PlayingsViewController *vc = [[PlayingsViewController alloc] initWithClient:self.client];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
