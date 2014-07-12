//
//  PPSSong.m
//  AirHack
//
//  Created by banjun on 2014/07/13.
//  Copyright (c) 2014年 banjun. All rights reserved.
//

#import "PPSSong.h"
@import MediaPlayer;


@interface PPSSong ()

@property (nonatomic) MPMediaItem *mediaItem;
@property (nonatomic) NSString *filePath;

@end


@implementation PPSSong

- (instancetype)initWithMedia:(MPMediaItem *)mediaItem filePath:(NSString *)filePath;
{
    if (self = [super init]) {
        self.mediaItem = mediaItem;
        self.filePath = filePath;
    }
    return self;
}

- (NSString *)title
{
    return [self.mediaItem valueForProperty:MPMediaItemPropertyTitle];
}

- (NSString *)artist
{
    return [self.mediaItem valueForProperty:MPMediaItemPropertyArtist];
}

- (UIImage *)artwork
{
    MPMediaItemArtwork *artwork = [self.mediaItem valueForProperty:MPMediaItemPropertyArtwork];
    return [artwork imageWithSize:CGSizeMake(512, 512)];
}

- (NSData *)artworkJPEGData
{
    return UIImageJPEGRepresentation(self.artwork, 0.8);
}

- (void)setUploadProgress:(NSProgress *)uploadProgress
{
    [_uploadProgress removeObserver:self forKeyPath:@"fractionCompleted"];
    _uploadProgress = uploadProgress;
    [_uploadProgress addObserver:self forKeyPath:@"fractionCompleted" options:0 context:nil];
}

#pragma mark Key-Value-Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.uploadProgress) {
        if (self.onUploadProgress) {
            self.onUploadProgress(self.uploadProgress.fractionCompleted);
        }
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}


@end