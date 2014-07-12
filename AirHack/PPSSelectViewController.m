//
//  PPSSelectViewController.m
//  AirHack
//
//  Created by banjun on 2014/07/12.
//  Copyright (c) 2014年 banjun. All rights reserved.
//

#import "PPSSelectViewController.h"
#import "NSObject+BTKUtils.h"
#import "BonjourFinder.h"

@interface PPSSelectViewController ()

@property (nonatomic) BonjourFinder *bonjourFinder;

@end


static NSString * const kCellID = @"Cell";


@implementation PPSSelectViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.view.backgroundColor = [UIColor whiteColor];
        
        __weak typeof(self) weakSelf = self;
        
        self.bonjourFinder = [[BonjourFinder alloc] init];
        self.bonjourFinder.onServicesChange = ^{
            [weakSelf.tableView reloadData];
        };
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.bonjourFinder searchForServicesOfType:@"_partyplay._tcp"];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self.bonjourFinder stop];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.bonjourFinder.services.count;
}

- (NSURL *)urlForService:(NSNetService *)service
{
    NSString *urlString = [NSString stringWithFormat:@"http://%@:%ld", service.hostName, (long)service.port];
    return [NSURL URLWithString:urlString];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kCellID];
    }
    
    NSNetService *service = self.bonjourFinder.services[indexPath.row];
    
    cell.textLabel.text = service.name;
    cell.detailTextLabel.text = [self urlForService:service].absoluteString;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (self.didSelect) {
        NSNetService *service = self.bonjourFinder.services[indexPath.row];
        self.didSelect([self urlForService:service]);
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

@end
