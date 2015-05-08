//
//  Appearance.h
//  AirHack
//
//  Created by banjun on 2014/07/13.
//  Copyright (c) 2014年 banjun. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Appearance : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic, readonly) UIColor *tintColor;

@end
