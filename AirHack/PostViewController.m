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
#import <AFNetworking.h>
#import <SVProgressHUD.h>


@interface PostViewController () <MPMediaPickerControllerDelegate>

@property (nonatomic) UIButton *ppsSelectButton;
@property (nonatomic) UIButton *postButton;
@property (nonatomic) UITextField *urlField;
@property (nonatomic) UITextField *titleField;

@property (nonatomic) UIButton *pickButton;
@property (nonatomic) MPMediaPickerController *picker;

@property (nonatomic) NSProgress *progress;

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
    [self.postButton addTarget:self action:@selector(retrieveCurrentMediaItem) forControlEvents:UIControlEventTouchUpInside];
    
    self.pickButton = [[UIButton buttonWithType:UIButtonTypeRoundedRect] btk_scope:^(UIButton *b) {
        [b setTitle:NSLocalizedString(@"Pick iPod Songs", @"") forState:UIControlStateNormal];
        [b addTarget:self action:@selector(showPicker:) forControlEvents:UIControlEventTouchUpInside];
    }];
    
    [self loadDefaults];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_ppsSelectButton, _urlField, _titleField, _postButton, _pickButton);
    for (UIView *v in views.allValues) {
        v.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:v];
    }
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_ppsSelectButton]-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_urlField]-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_titleField]-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_postButton]-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_pickButton]-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-84-[_urlField]-20-[_ppsSelectButton]-20-[_titleField]-20-[_postButton]-20-[_pickButton]" options:0 metrics:nil views:views]];
    
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
    [self.picker dismissViewControllerAnimated:YES completion:^{ self.picker = nil; }];
}

- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker;
{
    [self.picker dismissViewControllerAnimated:YES completion:^{ self.picker = nil; }];
}

#pragma mark -

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
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"export session completed.");
            [self pushFile:filename];
        });
    }];
    NSLog(@"export session started: %@ (supportedFileTypes = %@)", session, session.supportedFileTypes);
}

- (void)pushFile:(NSString *)filename
{
    [SVProgressHUD appearance].backgroundColor = [UIColor blackColor];
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
    [SVProgressHUD show];
    
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:@"POST" URLString:[self.urlField.text stringByAppendingString:@"/songs/add"] parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:[NSData dataWithContentsOfFile:filename] name:@"file" fileName:filename.lastPathComponent mimeType:@"application/octet-stream"];
    } error:nil];
    
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    manager.responseSerializer = [[AFHTTPResponseSerializer alloc] init];
    
    NSProgress *progress = nil;
    NSURLSessionUploadTask *uploadTask = [manager uploadTaskWithStreamedRequest:request progress:&progress completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        [self.progress removeObserver:self forKeyPath:@"fractionCompleted"];
        
        NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
        NSInteger status = res.statusCode;
        NSString *message = [NSString stringWithFormat:@"finish post with status = %ld. connectionError = %@", (long)status, error];
        if (error || status != 200) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
                NSLog(@"%@", message);
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Push Song(s)" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
            });
        } else {
            NSLog(@"%@", response);
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showSuccessWithStatus:@"Pushed!"];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [SVProgressHUD dismiss];
                });
            });
        }
    }];
    self.progress = progress;
    [self.progress addObserver:self forKeyPath:@"fractionCompleted" options:0 context:nil];
    [uploadTask resume];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object isKindOfClass:[NSProgress class]]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"progress = %f", self.progress.fractionCompleted);
            [SVProgressHUD showProgress:self.progress.fractionCompleted];
        });
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
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
