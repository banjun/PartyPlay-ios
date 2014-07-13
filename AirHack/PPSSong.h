//
//  PPSSong.h
//  AirHack
//
//  Created by banjun on 2014/07/13.
//  Copyright (c) 2014年 banjun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PPSSong : NSObject

- (instancetype)initWithJSON:(NSDictionary *)json;

@property (nonatomic) NSString *title;
@property (nonatomic) NSString *artist;
@property (nonatomic) NSURL *artworkURL;

@end
