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


@interface PostViewController () <MPMediaPickerControllerDelegate>

@property (nonatomic) UIButton *ppsSelectButton;
@property (nonatomic) UIButton *postButton;
@property (nonatomic) UITextField *urlField;
@property (nonatomic) UITextField *titleField;

@property (nonatomic) UIButton *pickButton;
@property (nonatomic) MPMediaPickerController *picker;

@property (nonatomic) UIButton *skipButton;

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
    
    self.titleField = [[[UITextField alloc] initWithFrame:CGRectZero] btk_scope:^(UITextField *t) {
        t.enabled = NO;
    }];
    
    self.postButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.postButton setTitle:@"Push Current Song" forState:UIControlStateNormal];
    [self.postButton addTarget:self action:@selector(pushCurrentSong:) forControlEvents:UIControlEventTouchUpInside];
    
    self.pickButton = [[UIButton buttonWithType:UIButtonTypeRoundedRect] btk_scope:^(UIButton *b) {
        [b setTitle:NSLocalizedString(@"Pick iPod Songs", @"") forState:UIControlStateNormal];
        [b addTarget:self action:@selector(showPicker:) forControlEvents:UIControlEventTouchUpInside];
    }];
    
    self.skipButton = [[UIButton buttonWithType:UIButtonTypeRoundedRect] btk_scope:^(UIButton *b) {
        [b setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [b setTitle:NSLocalizedString(@"Skip", @"") forState:UIControlStateNormal];
        [b addTarget:self action:@selector(skip:) forControlEvents:UIControlEventTouchUpInside];
    }];
    
    [self loadDefaults];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_ppsSelectButton, _urlField, _titleField, _postButton, _pickButton, _skipButton);
    for (UIView *v in views.allValues) {
        v.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:v];
    }
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_ppsSelectButton]-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_urlField]-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_titleField]-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_postButton]-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_pickButton]-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_skipButton]-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-84-[_urlField]-20-[_ppsSelectButton]-20-[_titleField]-20-[_postButton]-20-[_pickButton]-20-[_skipButton]" options:0 metrics:nil views:views]];
    
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

#pragma mark - Media Picker

- (IBAction)showPicker:(id)sender
{
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
    [SVProgressHUD appearance].backgroundColor = [UIColor blackColor];
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
    [SVProgressHUD show];
    
    NSString *exportFolder = [NSTemporaryDirectory() stringByAppendingString:@"export"];
    [[NSFileManager defaultManager] removeItemAtPath:exportFolder error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:exportFolder withIntermediateDirectories:YES attributes:nil error:nil];
    
    NSMutableArray *songs = [NSMutableArray array];
    [mediaItems enumerateObjectsUsingBlock:^(MPMediaItem *item, NSUInteger idx, BOOL *stop) {
        NSString *filePath = [exportFolder stringByAppendingFormat:@"/%lu.m4a", (unsigned long)idx];
        PPSSong *song = [[PPSSong alloc] initWithMedia:item filePath:filePath];
        [songs addObject:song];
    }];
    
    NSMutableArray *sessions = [NSMutableArray array];
    
    [songs enumerateObjectsUsingBlock:^(PPSSong *song, NSUInteger idx, BOOL *stop) {
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
                NSLog(@"export session completed for song: %@", song.title);
                if (sessions.count == 0) {
                    NSLog(@"all export sessions completed.");
                    completion(songs);
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
    NSURL *url = [NSURL URLWithString:self.urlField.text];
    if (!url) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"invalid url" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    [SVProgressHUD appearance].backgroundColor = [UIColor blackColor];
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
    [SVProgressHUD show];
    
    [songs enumerateObjectsUsingBlock:^(PPSSong *song, NSUInteger idx, BOOL *stop) {
        __weak typeof(song) weakSong = song;
        song.onUploadProgress = ^(float progress) {
            __block float totalProgress = 0.0;
            [songs enumerateObjectsUsingBlock:^(PPSSong *song, NSUInteger idx, BOOL *stop) {
                totalProgress += song.uploadProgress.fractionCompleted / songs.count;
            }];
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"%@ progress = %f, total = %f", weakSong.title, progress, totalProgress);
                [SVProgressHUD showProgress:totalProgress];
            });
        };
    }];
    
    PPSClient *client = [[PPSClient alloc] initWithBaseURL:url];
    [client pushSongs:songs progress:^(float progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"progress = %f", progress);
            [SVProgressHUD showProgress:progress];
        });
    } didPushSong:^(PPSSong *song) {
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
    MPMediaItem *item = [MPMusicPlayerController iPodMusicPlayer].nowPlayingItem;
    if (!item) {
        NSLog(@"current item not found");
        return;
    }
    [self exportMediaItemsAndPush:@[item]];
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

- (IBAction)skip:(id)sender
{
    NSURL *url = [NSURL URLWithString:self.urlField.text];
    if (!url) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"invalid url" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    PPSClient *client = [[PPSClient alloc] initWithBaseURL:url];
    [client skip];
}

@end
