//
//  Functional.h
//  asakusasatellite
//
//  Created by banjun on 2013/07/13.
//  Copyright (c) 2013年 codefirst. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (Functional)

- (NSArray *)map:(id (^)(id))f;
- (NSArray *)filter:(BOOL (^)(id))f;

- (BOOL)all:(BOOL (^)(id))f;
- (BOOL)any:(BOOL (^)(id))f;

- (NSArray *)takeWhile:(BOOL (^)(id))f;


- (NSArray *)compact;

@end


@interface NSDictionary (Functional)

- (NSDictionary *)mapValue:(id (^)(NSString *key, id value))f;


- (NSDictionary *)compact;

@end