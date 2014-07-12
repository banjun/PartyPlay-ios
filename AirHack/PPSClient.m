//
//  PPSClient.m
//  AirHack
//
//  Created by banjun on 2014/07/13.
//  Copyright (c) 2014年 banjun. All rights reserved.
//

#import "PPSClient.h"
#import "PPSSong.h"
#import <AFNetworking.h>


static NSString * const kPost = @"POST";
static NSString * const kSongsAdd = @"/songs/add";
static NSString * const kParamFile = @"file";
static NSString * const kContentTypeOctetStream = @"application/octet-stream";


@interface PPSClient ()

@property (nonatomic) NSURL *baseURL;

@property (nonatomic) NSProgress *progress;
@property (nonatomic, copy) void (^currentProgressHandler)(float progress);

@end


@implementation PPSClient

- (instancetype)initWithBaseURL:(NSURL *)url;
{
    if (self = [super init]) {
        self.baseURL = url;
    }
    return self;
}

- (void)pushSongs:(NSArray *)songs progress:(void (^)(float progress))progressHandler didPushSong:(void (^)(PPSSong *song))didPushSong completion:(void (^)())completion failure:(void (^)(NSError *error))failure; // Array<PPSSong>
{
    PPSSong *song = songs.firstObject; // TODO: process all objects
    
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:kPost URLString:[self.baseURL.absoluteString stringByAppendingString:kSongsAdd] parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:[NSData dataWithContentsOfFile:song.filePath] name:kParamFile fileName:song.filePath.lastPathComponent mimeType:kContentTypeOctetStream];
    } error:nil];
    
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    manager.responseSerializer = [[AFHTTPResponseSerializer alloc] init];
    
    NSProgress *progress = nil;
    self.currentProgressHandler = progressHandler;
    NSURLSessionUploadTask *uploadTask = [manager uploadTaskWithStreamedRequest:request progress:&progress completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        [self.progress removeObserver:self forKeyPath:@"fractionCompleted"];
        
        NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
        NSInteger status = res.statusCode;
        if (error || status != 200) {
            if (failure) {
                failure(error);
            }
        } else {
            if (didPushSong) {
                didPushSong(song); // TODO: process all songs
            }
            BOOL hasAllDone = YES; // TODO: process all songs
            if (hasAllDone) {
                completion();
            }
        }
    }];
    self.progress = progress;
    [self.progress addObserver:self forKeyPath:@"fractionCompleted" options:0 context:nil];
    [uploadTask resume];
}

#pragma mark Key-Value-Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object isKindOfClass:[NSProgress class]]) {
        if (self.currentProgressHandler) {
            self.currentProgressHandler(self.progress.fractionCompleted);
        }
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark -

@end