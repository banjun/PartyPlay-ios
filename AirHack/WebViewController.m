//
//  WebViewController.m
//  AirHack
//
//  Created by banjun on 2014/07/13.
//  Copyright (c) 2014年 banjun. All rights reserved.
//

#import "WebViewController.h"
#import "NSObject+BTKUtils.h"

@interface WebViewController () <UIWebViewDelegate>

@property (nonatomic) UIWebView *webView;
@property (nonatomic) NSURL *initialURL;

@end

@implementation WebViewController

- (id)initWithURL:(NSURL *)url
{
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.initialURL = url;
    }
    return self;
}

- (void)loadView
{
    [super loadView];
    
    self.webView = [[[UIWebView alloc] initWithFrame:self.view.bounds] btk_scope:^(UIWebView *v) {
        v.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.view addSubview:v];
        
        v.delegate = self;
        NSURLRequest *req = [NSURLRequest requestWithURL:self.initialURL];
        [v loadRequest:req];
    }];
}

#pragma mark - WebView Delegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;
{
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView;
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = webView.loading;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView;
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = webView.loading;
    
    NSString *title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    if (title.length > 0) {
        self.title = title;
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error;
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Load Failed" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

@end
