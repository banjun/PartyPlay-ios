//
//  PPSNowPlaying.h
//  AirHack
//
//  Created by banjun on 2014/07/13.
//  Copyright (c) 2014年 banjun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PPSSong.h"

@interface PPSNowPlaying : NSObject

- (instancetype)initWithJSON:(NSDictionary *)json;

@property (nonatomic) PPSSong *currentSong;
@property (nonatomic) NSArray *nextSongs;

@end
