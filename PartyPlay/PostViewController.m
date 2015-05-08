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
#import "PPSNowPlaying.h"
#import <PromiseKit.h>
#import "PlayingsViewController.h"
#import "UIImage+ImageEffects.h"
#import <Haneke.h>
#import "CenteringView.h"
#import "Appearance.h"
#import "PartyPlay-Swift.h"
#import "PPSLocalSong.h"

@interface PostViewController () <MPMediaPickerControllerDelegate>

@property (nonatomic) MPMusicPlayerController *iPodController;
@property (nonatomic) MPMediaItem *nowPlayingItem;
@property (nonatomic) NSString *serverURLString;

@property (nonatomic) PPSClient *client;

@property (nonatomic) UILabel *serverLabel;
@property (nonatomic) UIImageView *iPodArtworkView;
@property (nonatomic) UIButton *postButton;
@property (nonatomic) UIButton *pickButton;
@property (nonatomic) MPMediaPickerController *picker;
@property (nonatomic) UIImageView *nowPlayingImageView;
@property (nonatomic) UIButton *postQueueButton;
@property (nonatomic) NSArray *postQueueButtonShowConstraints;
@property (nonatomic) NSArray *postQueueButtonHideConstraints;

@property (nonatomic) NSTimer *pollingTimer;

@property (nonatomic) PostQueue *postQueue;
@property (nonatomic) NSTimer *postQueueTimer;

@end


static NSString * const kPostURLKey = @"PostURL";


@implementation PostViewController

- (void)loadView
{
    [super loadView];
    
    self.title = NSLocalizedString(@"Party Play", @"");
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.nowPlayingImageView = [[[UIImageView alloc] initWithImage:nil] btk_scope:^(UIImageView *v) {
        v.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        v.contentMode = UIViewContentModeScaleAspectFill;
        v.frame = self.view.bounds;
        v.alpha = 0.5;
        v.hnk_cacheFormat = [[[HNKCacheFormat alloc] initWithName:@"FullScreenBlur"] btk_scope:^(HNKCacheFormat *f) {
            f.size = [UIScreen mainScreen].bounds.size;
            f.scaleMode = HNKScaleModeAspectFill;
            f.compressionQuality = 0.5;
            f.diskCapacity = 1 * 1024 * 1024; // 1MB
            f.preloadPolicy = HNKPreloadPolicyNone;
            f.postResizeBlock = ^(NSString *key, UIImage *image) {
                return [image applyBlurWithRadius:15 tintColor:nil saturationDeltaFactor:2.0 maskImage:nil];
            };
        }];
        [self.view addSubview:v];
    }];
    
    self.serverLabel = [[[UILabel alloc] initWithFrame:CGRectZero] btk_scope:^(UILabel *l) {
        l.font = [UIFont systemFontOfSize:14.0];
        l.textColor = [UIColor colorWithWhite:0 alpha:0.9];
    }];
    
    self.iPodArtworkView = [[[UIImageView alloc] initWithImage:nil] btk_scope:^(UIImageView *v) {
        v.contentMode = UIViewContentModeScaleAspectFit;
        [v setContentCompressionResistancePriority:UILayoutPriorityFittingSizeLevel forAxis:UILayoutConstraintAxisHorizontal];
        [v setContentCompressionResistancePriority:UILayoutPriorityFittingSizeLevel forAxis:UILayoutConstraintAxisVertical];
    }];
    CenteringView *iPodArtworkCenteringView = [[CenteringView alloc] initWithFrame:CGRectZero contentView:self.iPodArtworkView];
    
    void (^applyButtonAppearance)(UIButton *) = ^(UIButton *b) {
        b.backgroundColor = [[Appearance sharedInstance].tintColor colorWithAlphaComponent:0.9];
        [b setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [b setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
        b.titleLabel.font = [UIFont boldSystemFontOfSize:16.0];
        b.layer.cornerRadius = 4.0;
        b.contentEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8);
        
        [b setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    };
    
    self.postButton = [[UIButton buttonWithType:UIButtonTypeSystem] btk_scope:^(UIButton *b) {
        [b addTarget:self action:@selector(pushCurrentSong:) forControlEvents:UIControlEventTouchUpInside];
        applyButtonAppearance(b);
    }];
    [self iPodNowPlayingChanged:nil]; // update title and enabled
    
    self.pickButton = [[UIButton buttonWithType:UIButtonTypeSystem] btk_scope:^(UIButton *b) {
        [b setTitle:NSLocalizedString(@"Choose Other Songs", @"") forState:UIControlStateNormal];
        [b addTarget:self action:@selector(showPicker:) forControlEvents:UIControlEventTouchUpInside];
        applyButtonAppearance(b);
    }];
    
    self.postQueueButton = [[UIButton buttonWithType:UIButtonTypeSystem] btk_scope:^(UIButton *b) {
        [b addTarget:self action:@selector(showPostQueue:) forControlEvents:UIControlEventTouchUpInside];
        applyButtonAppearance(b);
        b.layer.cornerRadius = 0.0;
    }];
    
    [self loadDefaults];
    
    UIView *buttonSpacerLeft = [AutoLayoutMinView spacer];
    UIView *buttonSpacerRight = [AutoLayoutMinView spacer];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_serverLabel, iPodArtworkCenteringView, _postButton, _pickButton, _postQueueButton, buttonSpacerLeft, buttonSpacerRight);
    for (UIView *v in views.allValues) {
        v.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:v];
    }
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_serverLabel]-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[iPodArtworkCenteringView]-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-8-[buttonSpacerLeft][_postButton][buttonSpacerRight(==buttonSpacerLeft)]-8-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-8-[buttonSpacerLeft][_pickButton][buttonSpacerRight]-8-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_postQueueButton]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-84-[_serverLabel]-20-[iPodArtworkCenteringView(<=128)]-8-[_postButton]-40-[_pickButton]-(>=20)-|" options:0 metrics:nil views:views]];
    
    self.postQueueButtonShowConstraints = @[[NSLayoutConstraint constraintWithItem:self.postQueueButton
                                                                         attribute:NSLayoutAttributeBottom
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.view
                                                                         attribute:NSLayoutAttributeBottom
                                                                        multiplier:1
                                                                          constant:0]];
    self.postQueueButtonHideConstraints = @[[NSLayoutConstraint constraintWithItem:self.postQueueButton
                                                                         attribute:NSLayoutAttributeTop
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.view
                                                                         attribute:NSLayoutAttributeBottom
                                                                        multiplier:1
                                                                          constant:0]];
    [self hidePostQueueButtonAnimated:NO];
    
    
    self.iPodController = [[MPMusicPlayerController iPodMusicPlayer] btk_scope:^(MPMusicPlayerController *c) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(iPodNowPlayingChanged:) name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification object:c];
        [c beginGeneratingPlaybackNotifications];
    }];
    
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Settings", @"") style:UIBarButtonItemStylePlain target:self action:@selector(showSettings:)] btk_scope:^(UIBarButtonItem *b) {
        [b setTitleTextAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:16.0]} forState:UIControlStateNormal];
    }];
    
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Now Playing", @"") style:UIBarButtonItemStylePlain target:self action:@selector(showNowPlaying:)] btk_scope:^(UIBarButtonItem *b) {
        [b setTitleTextAttributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:16.0]} forState:UIControlStateNormal];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ppsClientNowPlayingChanged:) name:PPSClient.nowPlayingDidChangeNotificationName object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.client loadNowPlaying];
    
    [self.pollingTimer invalidate];
    self.pollingTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(pollingFired) userInfo:nil repeats:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.pollingTimer invalidate];
    self.pollingTimer = nil;
}

- (void)pollingFired
{
    [self.client loadNowPlaying];
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
    self.postQueue = [[PostQueue alloc] initWithClient:self.client];
    [self.client loadNowPlaying];
    return self.client;
}

#pragma mark - PPSClient

- (void)ppsClientNowPlayingChanged:(NSNotification *)notification
{
//    NSLog(@"nowPlaying = %@", self.client.nowPlaying);
    [self.nowPlayingImageView hnk_setImageFromURL:self.client.nowPlaying.currentSong.artworkURL];
}

#pragma mark - Music Player

- (void)iPodNowPlayingChanged:(NSNotification *)notification
{
    self.nowPlayingItem = [MPMusicPlayerController iPodMusicPlayer].nowPlayingItem;
    NSString *title = @"iPod Stopped";
    if (self.nowPlayingItem) {
        title = [NSString stringWithFormat:@"Push %@", [self.nowPlayingItem valueForProperty:MPMediaItemPropertyTitle]];
        self.iPodArtworkView.image = [[self.nowPlayingItem valueForProperty:MPMediaItemPropertyArtwork] imageWithSize:CGSizeMake(256, 256)];
    } else {
        self.iPodArtworkView.image = nil;
    }
    [self.postButton setTitle:title forState:UIControlStateNormal];
    self.postButton.enabled = (self.nowPlayingItem != nil);
    self.postButton.alpha = (self.nowPlayingItem != nil ? 1.0 : 0.5);
}

#pragma mark - Media Picker

- (IBAction)showPicker:(id)sender
{
    if ([self showInvalidURLAlertIfNeeded]) return;
    
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
                [self addMediaItemsToPostQueue:mediaItemCollection.items];
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

- (void)addMediaItemsToPostQueue:(NSArray *)mediaItems
{
    [self.postQueue addSongsWithMediaItems:mediaItems];
    if (self.postQueueTimer) {
        [self.postQueueTimer invalidate];
    }
    self.postQueueTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updatePostQueueButton) userInfo:nil repeats:YES];
    [self updatePostQueueButton];
}

- (IBAction)pushCurrentSong:(id)sender
{
    if ([self showInvalidURLAlertIfNeeded]) return;
    
    if (!self.nowPlayingItem) {
        NSLog(@"current item not found");
        return;
    }
    
    [self addMediaItemsToPostQueue:@[self.nowPlayingItem]];
}

- (IBAction)showPostQueue:(id)sender
{
    [self.navigationController pushViewController:[[PostQueueViewController alloc] initWithQueue:self.postQueue] animated:YES];
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

- (BOOL)showInvalidURLAlertIfNeeded
{
    if (!self.client) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"Cannot connect to the server.", @"") delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
        [alert show];
        return YES;
    }
    return NO;
}

- (IBAction)showNowPlaying:(id)sender
{
    if ([self showInvalidURLAlertIfNeeded]) return;
    
    PlayingsViewController *vc = [[PlayingsViewController alloc] initWithClient:self.client];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)updatePostQueueButton
{
    if (self.postQueue.localSongs.count == 0) {
        [self.postQueueTimer invalidate];
        self.postQueueTimer = nil;
        [self hidePostQueueButtonAnimated:YES];
        return;
    }
    
    [self.postQueueButton setTitle:self.postQueue.statusText forState:UIControlStateNormal];
    if (self.postQueueButton.hidden) [self showPostQueueButtonAnimated:YES];
}

- (void)showPostQueueButtonAnimated:(BOOL)animated
{
    [self.view removeConstraints:self.postQueueButtonHideConstraints];
    [self.view addConstraints:self.postQueueButtonShowConstraints];
    self.postQueueButton.hidden = NO;
    if (animated) {
        [UIView animateWithDuration:0.2 animations:^{
            [self.view layoutIfNeeded];
        }];
    }
}
- (void)hidePostQueueButtonAnimated:(BOOL)animated
{
    [self.view removeConstraints:self.postQueueButtonShowConstraints];
    [self.view addConstraints:self.postQueueButtonHideConstraints];
    if (animated) {
        [UIView animateWithDuration:0.2 animations:^{
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            self.postQueueButton.hidden = YES;
        }];
    } else {
        self.postQueueButton.hidden = YES;
    }
}

@end
