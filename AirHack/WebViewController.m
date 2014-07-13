//
//  WebViewController.m
//  AirHack
//
//  Created by banjun on 2014/07/13.
//  Copyright (c) 2014年 banjun. All rights reserved.
//

#import "WebViewController.h"
#import "NSObject+BTKUtils.h"

@interface WebViewController () <UIWebViewDelegate, UIScrollViewDelegate>

@property (nonatomic) UIWebView *webView;
@property (nonatomic) NSURL *initialURL;
@property (nonatomic) NSTimer *pollingTimer;
@property (nonatomic) BOOL statusBarHidden;

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
        v.scrollView.delegate = self;
        NSURLRequest *req = [NSURLRequest requestWithURL:self.initialURL];
        [v loadRequest:req];
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.webView.delegate = nil;
    [self.webView reload];
    
    self.pollingTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(pollingFired) userInfo:nil repeats:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.pollingTimer invalidate];
    self.pollingTimer = nil;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self.webView stopLoading];
    self.webView.delegate = nil;
}

#pragma mark - Timer

- (void)pollingFired
{
    NSString *title = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    if (title.length > 0) {
        if (self.title.length == 0 && !self.webView.scrollView.isDragging) {
            [self hideBarsWithAnimated:YES];
            [self scrollViewDidEndDecelerating:self.webView.scrollView]; // trigger status bar hidden
        }
        self.title = title;
    }
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
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error;
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Load Failed" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset NS_AVAILABLE_IOS(5_0);
{
    if (!self.navigationController.navigationBarHidden && velocity.y > 0) {
        [self hideBarsWithAnimated:YES];
    } else if (scrollView.contentOffset.y <= 0 && velocity.y < -1.0) {
        [self showBars];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView;      // called when scroll view grinds to a halt
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.statusBarHidden = self.navigationController.navigationBarHidden;
        [self setNeedsStatusBarAppearanceUpdate];
    });
}

- (void)hideBarsWithAnimated:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)showBars
{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (BOOL)prefersStatusBarHidden
{
    return self.statusBarHidden;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation NS_AVAILABLE_IOS(7_0); // Defaults to UIStatusBarAnimationFade
{
    return UIStatusBarAnimationFade;
}


@end
