//
//  NSObject+BTKUtils.h
//  BTKCommons
//
//  Created by Tomohisa Ota on 3/20/14.
//
//

#import <Foundation/Foundation.h>

@interface NSObject (BTKUtils)

- (instancetype) btk_scope:(void (^)(id obj))scopedBlock;

@end