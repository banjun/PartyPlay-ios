//
//  Functional.m
//  asakusasatellite
//
//  Created by banjun on 2013/07/13.
//  Copyright (c) 2013年 codefirst. All rights reserved.
//

#import "Functional.h"

@implementation NSArray (Functional)

- (NSArray *)map:(id (^)(id))f
{
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:self.count];
    for (id obj in self) {
        [result addObject:f(obj)];
    }
    return [NSArray arrayWithArray:result];
}
- (NSArray *)filter:(BOOL (^)(id))f
{
    return [self filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return f(evaluatedObject);
    }]];
}

- (id)findFirst:(BOOL (^)(id))f;
{
    for (id obj in self) {
        if(f(obj)) return obj;
    }
    return nil;
}

- (BOOL)all:(BOOL (^)(id))f
{
    for (id obj in self) {
        if (!f(obj)) return NO;
    }
    return YES;
}
- (BOOL)any:(BOOL (^)(id))f
{
    for (id obj in self) {
        if (f(obj)) return YES;
    }
    return NO;
}

- (NSArray *)takeWhile:(BOOL (^)(id))f
{
    int length = 0;
    for (id obj in self) {
        if (f(obj)) ++length;
        else break;
    }
    return [self subarrayWithRange:NSMakeRange(0, length)];
}


- (NSArray *)compact
{
    return [[self map:^id(id obj) {
        if ([obj isKindOfClass:[NSArray class]]) {
            return [(NSArray *)obj compact];
        } else if ([obj isKindOfClass:[NSDictionary class]]) {
            return [(NSDictionary *)obj compact];
        } else {
            return obj;
        }
    }] filter:^BOOL(id obj) {
        return (obj != [NSNull null]);
    }];
}

@end


@implementation NSDictionary (Functional)

- (NSDictionary *)mapValue:(id (^)(NSString *key, id value))f
{
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    [self.allKeys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
        d[key] = f(key, self[key]);
    }];
    return d;
}

- (NSDictionary *)filter:(BOOL (^)(NSString *key, id value))f
{
    return [self dictionaryWithValuesForKeys:[self.allKeys filter:^BOOL(NSString *key) {
        return f(key, self[key]);
    }]];
}

- (NSDictionary *)compact
{
    return [[self mapValue:^id(NSString *key, id value) {
        if ([value isKindOfClass:[NSArray class]]) {
            return [(NSArray *)value compact];
        } else if ([value isKindOfClass:[NSDictionary class]]) {
            return [(NSDictionary *)value compact];
        } else {
            return value;
        }
    }] filter:^BOOL(NSString *key, id value) {
        return (value != [NSNull null]);
    }];
}

@end
