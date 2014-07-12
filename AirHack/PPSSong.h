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

@property (nonatomic, readonly) NSString *title;

@end