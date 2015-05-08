//
//  NSObject+BTKUtils.m
//  BTKCommons
//
//  Created by Tomohisa Ota on 3/20/14.
//
//

#import "NSObject+BTKUtils.h"

@implementation NSObject (BTKUtils)

- (instancetype) btk_scope:(void (^)(id obj))scopedBlock
{
    if(scopedBlock){
        scopedBlock(self);
    }
    return self;
}

@end