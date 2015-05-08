//
//  BonjourFinder.m
//  AirHack
//
//  Created by banjun on 2014/07/12.
//  Copyright (c) 2014年 banjun. All rights reserved.
//

#import "BonjourFinder.h"

@interface BonjourFinder () <NSNetServiceBrowserDelegate, NSNetServiceDelegate>

@property (nonatomic) NSNetServiceBrowser *netServiceBrowser;
@property (nonatomic) NSMutableArray *services;

@end

@implementation BonjourFinder

- (void)searchForServicesOfType:(NSString *)type // ex. @"_servicename._tcp"
{
    [self.netServiceBrowser stop];
    self.services = [NSMutableArray array];
    
    self.netServiceBrowser = [[NSNetServiceBrowser alloc] init];
    self.netServiceBrowser.delegate = self;
    self.netServiceBrowser.includesPeerToPeer = YES;
    
    [self.netServiceBrowser searchForServicesOfType:type inDomain:@"local"];
}

- (void)stop
{
    [self.netServiceBrowser stop];
}

#pragma mark NSNetServiceBrowser Delegate

- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)aNetServiceBrowser;
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)aNetServiceBrowser;
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didNotSearch:(NSDictionary *)errorDict;
{
    NSLog(@"%s: %@", __PRETTY_FUNCTION__, errorDict);
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveDomain:(NSString *)domainString moreComing:(BOOL)moreComing;
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing;
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.services removeObject:aNetService];
    
    if (self.onServicesChange) {
        self.onServicesChange();
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser*)aNetServiceBrowser didFindService:(NSNetService*)service moreComing:(BOOL)moreComing
{
    NSLog(@"found service (moreComing = %d): %@ (%@ at %@)", moreComing, service, service.name, service.hostName);
    service.delegate = self;
    service.includesPeerToPeer = YES;
    [self.services addObject:service];
    [service resolveWithTimeout:0];
    
    [self notifyServicesChange];
}

- (void)notifyServicesChange
{
    if (self.onServicesChange) {
        self.onServicesChange();
    }
}

#pragma NSNetService Delegate

- (void)netServiceWillResolve:(NSNetService *)sender;
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
    NSLog(@"resolve service: %@ (%@:%ld)", sender, sender.hostName, (long)sender.port);
    [self notifyServicesChange];
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
    NSLog(@"%s: %@", __PRETTY_FUNCTION__, errorDict);
    [self.services removeObject:sender];
    [self notifyServicesChange];
}

- (void)netServiceDidStop:(NSNetService *)sender;
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.services removeObject:sender];
    [self notifyServicesChange];
}

- (void)netService:(NSNetService *)sender didUpdateTXTRecordData:(NSData *)data;
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

@end
