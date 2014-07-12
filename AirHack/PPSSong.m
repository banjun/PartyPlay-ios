//
//  PPSSong.m
//  AirHack
//
//  Created by banjun on 2014/07/13.
//  Copyright (c) 2014年 banjun. All rights reserved.
//

#import "PPSSong.h"


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

@end