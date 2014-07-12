//
//  PPSSong.h
//  AirHack
//
//  Created by banjun on 2014/07/13.
//  Copyright (c) 2014年 banjun. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MPMediaItem;

@interface PPSSong : NSObject

- (instancetype)initWithMedia:(MPMediaItem *)mediaItem filePath:(NSString *)filePath;

@property (nonatomic, readonly) MPMediaItem *mediaItem;
@property (nonatomic, readonly) NSString *filePath;

@property (nonatomic) NSProgress *uploadProgress;
@property (nonatomic, copy) void (^onUploadProgress)(float progress);
@property (nonatomic) BOOL uploadCompleted;
@property (nonatomic) BOOL uploadCanceled;

@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *artist;
@property (nonatomic, readonly) UIImage *artwork;
@property (nonatomic, readonly) NSData *artworkJPEGData;

@end