//
//  PPSClient.m
//  AirHack
//
//  Created by banjun on 2014/07/13.
//  Copyright (c) 2014年 banjun. All rights reserved.
//

#import "PPSClient.h"
#import "PPSLocalSong.h"
#import <AFNetworking.h>
#import "Functional.h"


static NSString * const kPost = @"POST";
static NSString * const kSongsAdd = @"/songs/add";
static NSString * const kSongsSkip = @"/songs/skip";
static NSString * const kSongsIndexHTML = @"/songs/index.html";
static NSString * const kParamFile = @"file";
static NSString * const kParamTitle = @"title";
static NSString * const kParamArtist = @"artist";
static NSString * const kParamArtwork = @"artwork";
static NSString * const kContentTypeOctetStream = @"application/octet-stream";
static NSString * const kContentTypeJpeg = @"image/jpeg";


@interface PPSClient ()

@property (nonatomic) NSURL *baseURL;

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

- (void)pushSongs:(NSArray *)songs progress:(void (^)(float progress))progressHandler didPushSong:(void (^)(PPSLocalSong *song))didPushSong completion:(void (^)())completion failure:(void (^)(NSError *error))failure; // Array<PPSSong>
{
    self.currentProgressHandler = progressHandler;
    
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    manager.responseSerializer = [[AFHTTPResponseSerializer alloc] init];
    
    for (PPSLocalSong *song in songs) {
        NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:kPost URLString:[self.baseURL.absoluteString stringByAppendingString:kSongsAdd] parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            // song file content
            [formData appendPartWithFileData:[NSData dataWithContentsOfFile:song.filePath] name:kParamFile fileName:song.filePath.lastPathComponent mimeType:kContentTypeOctetStream];
            
            // metadata
            void (^addText)(NSString *, NSString *) = ^(NSString *key, NSString *value) {
                [formData appendPartWithFormData:[[value stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] dataUsingEncoding:NSUTF8StringEncoding]
                                            name:[key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            };
            addText(kParamTitle, song.title);
            addText(kParamArtist, song.artist);
            [formData appendPartWithFileData:song.artworkJPEGData name:kParamArtwork fileName:kParamArtwork mimeType:kContentTypeJpeg];
        } error:nil];
        
        NSProgress *progress = nil;
        NSURLSessionUploadTask *uploadTask = [manager uploadTaskWithStreamedRequest:request progress:&progress completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
            
            NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
            NSInteger status = res.statusCode;
            if (error || status != 200) {
                if (failure) {
                    failure(error);
                }
            } else {
                song.uploadCompleted = YES;
                if (didPushSong) {
                    didPushSong(song);
                }
                BOOL hasAllDone = [songs all:^BOOL(PPSLocalSong *s){ return s.uploadCompleted; }];
                if (hasAllDone && completion) {
                    completion();
                }
            }
        }];
        song.uploadProgress = progress;
        [uploadTask resume];
    }
}

- (void)skip
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [[AFHTTPResponseSerializer alloc] init];
    [manager POST:[self.baseURL.absoluteString stringByAppendingString:kSongsSkip] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"skip succeeded");
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"skip failed: %@", error);
    }];
}

- (NSURL *)songsIndexHTMLURL
{
    return [NSURL URLWithString:kSongsIndexHTML relativeToURL:self.baseURL];
}

@end