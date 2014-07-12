//
//  PPSClient.h
//  AirHack
//
//  Created by banjun on 2014/07/13.
//  Copyright (c) 2014年 banjun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PPSSong.h"

@interface PPSClient : NSObject

@property (nonatomic, readonly) NSURL *baseURL;

- (instancetype)initWithBaseURL:(NSURL *)url;
- (void)pushSongs:(NSArray *)songs progress:(void (^)(float progress))progress didPushSong:(void (^)(PPSSong *song))didPushSong completion:(void (^)())completion failure:(void (^)(NSError *error))failure; // Array<PPSSong>
- (void)skip;

@end