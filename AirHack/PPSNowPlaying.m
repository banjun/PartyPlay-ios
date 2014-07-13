//
//  PPSNowPlaying.m
//  AirHack
//
//  Created by banjun on 2014/07/13.
//  Copyright (c) 2014年 banjun. All rights reserved.
//

#import "PPSNowPlaying.h"
#import "Functional.h"

static NSString * const kKeyCurrent = @"current";
static NSString * const kKeyNext = @"next";

@implementation PPSNowPlaying

- (instancetype)initWithJSON:(NSDictionary *)json;
{
    if (![json isKindOfClass:[NSDictionary class]]) return nil;
    
    if (self = [super init]) {
        self.currentSong = [[PPSSong alloc] initWithJSON:json[kKeyCurrent]];
        
        NSArray *next = json[kKeyNext];
        if (![next isKindOfClass:[NSArray class]]) return nil;
        self.nextSongs = [next map:^PPSSong*(NSDictionary *j) {
            return [[PPSSong alloc] initWithJSON:j];
        }];
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ (current = %@, next %lu songs)", [super description], self.currentSong, (unsigned long)self.nextSongs.count];
}

@end
