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

@property (nonatomic) NSURL *initialBaseURL;
@property (nonatomic) BonjourFinder *bonjourFinder;
@property (nonatomic) NSNetService *selectedService;

@end


static NSString * const kCellID = @"Cell";


@implementation PPSSelectViewController

- (instancetype)initWithCurrentBaseURL:(NSURL *)currentBaseURL
{
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
        self.title = NSLocalizedString(@"Settings", @"");
        self.view.backgroundColor = [UIColor whiteColor];
        
        __weak typeof(self) weakSelf = self;
        
        self.initialBaseURL = currentBaseURL;
        
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
    
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"") style:UIBarButtonItemStylePlain target:self action:@selector(cancel:)] btk_scope:^(UIBarButtonItem *b) {
    }];
    
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)] btk_scope:^(UIBarButtonItem *b) {
    }];
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

- (IBAction)done:(id)sender
{
    if (self.selectedService && self.didSelect) {
        self.didSelect([self urlForService:self.selectedService]);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)cancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.bonjourFinder.services.count;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section;    // fixed font style. use custom view (UILabel) if you want something different
{
    return NSLocalizedString(@"Searching Party Play Servers on near network", @"");
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
    
    BOOL resolved = (service.hostName.length > 0);
    
    cell.textLabel.text = service.name;
    cell.textLabel.enabled = resolved;
    cell.detailTextLabel.text = (resolved ? [self urlForService:service].absoluteString : @"checking address...");
    cell.detailTextLabel.enabled = resolved;
    cell.selectionStyle = (resolved ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone);
    
    if (!self.selectedService && [self.initialBaseURL.absoluteString isEqualToString:[self urlForService:service].absoluteString]) {
        self.selectedService = service;
    }
    cell.accessoryType = (self.selectedService == service ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSNetService *service = self.bonjourFinder.services[indexPath.row];
    if (service.hostName.length <= 0) return;
    self.selectedService = service;
    [tableView reloadData];
}

@end
