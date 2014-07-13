//
//  Appearance.m
//  AirHack
//
//  Created by banjun on 2014/07/13.
//  Copyright (c) 2014年 banjun. All rights reserved.
//

#import "Appearance.h"

#define RGB(r, g, b) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0]
#define HSB(h, s, b) [UIColor colorWithHue:h/360.0 saturation:s/100.0 brightness:b/100.0 alpha:1.0]

@implementation Appearance

+ (instancetype)sharedInstance;
{
    static Appearance *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.honokaOrange = RGB(255, 146, 40); // == HSB(30, 84, 100)
        self.honokaOrangeBlack = HSB(30, 84, 25);
        
        [UINavigationBar appearance].barTintColor = self.honokaOrange;
        [UINavigationBar appearance].tintColor = [UIColor whiteColor];
        [UINavigationBar appearance].titleTextAttributes = @{NSForegroundColorAttributeName: self.honokaOrangeBlack};
        
        [UITabBar appearance].tintColor = self.honokaOrange;
    }
    return self;
}

@end
