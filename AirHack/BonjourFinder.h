//
//  BonjourFinder.h
//  AirHack
//
//  Created by banjun on 2014/07/12.
//  Copyright (c) 2014年 banjun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BonjourFinder : NSObject

@property (nonatomic, readonly) NSMutableArray *services;
@property (nonatomic, copy) void (^onServicesChange)();
- (void)searchForServicesOfType:(NSString *)type; // @"_servicename._tcp"
- (void)stop;

@end
