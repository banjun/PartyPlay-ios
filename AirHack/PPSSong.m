//
//  PPSSong.m
//  AirHack
//
//  Created by banjun on 2014/07/13.
//  Copyright (c) 2014年 banjun. All rights reserved.
//

#import "PPSSong.h"

static NSString * const kKeyTitle = @"title";
static NSString * const kKeyArtist = @"artist";
static NSString * const kKeyArtwork = @"artwork";

@implementation PPSSong

- (instancetype)initWithJSON:(NSDictionary *)json;
{
    if (![json isKindOfClass:[NSDictionary class]]) return nil;
    
    if (self = [super init]) {
        self.title = json[kKeyTitle];
        self.artist = json[kKeyArtist];
        self.artworkURL = [NSURL URLWithString:json[kKeyArtwork]];
    }
    return self;
}


- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ (%@)", [super description], self.title];
}

- (void)loadArtwork:(void (^)(UIImage *artwork))completion
{
    if (!self.artworkURL) {
        completion(nil);
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSData *data = [NSData dataWithContentsOfURL:self.artworkURL];
        completion([UIImage imageWithData:data]);
    });
}

@end
