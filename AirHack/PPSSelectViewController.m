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
#import "Functional.h"

@interface PPSSelectViewController () <UITextFieldDelegate>

@property (nonatomic) NSURL *initialBaseURL;
@property (nonatomic) BonjourFinder *bonjourFinder;
@property (nonatomic) NSNetService *selectedService;
@property (nonatomic) UITextField *postURLField;

@end


enum Section {
    kSectionPostURL = 0,
    kSectionBonjour,
};


static NSString * const kPostURLCellID = @"PostURLCell";
static NSString * const kCellID = @"Cell";


@interface TextFieldTableViewCell : UITableViewCell

@property (nonatomic) UITextField *textField;

@end


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
            [weakSelf.tableView reloadSections:[NSIndexSet indexSetWithIndex:kSectionBonjour] withRowAnimation:UITableViewRowAnimationNone];
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
    NSURL *url = [NSURL URLWithString:self.postURLField.text];
    if (url && self.didSelect) {
        self.didSelect(url);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)cancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setSelectedService:(NSNetService *)selectedService
{
    _selectedService = selectedService;
    self.postURLField.text = [self urlForService:selectedService].absoluteString;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2; // text + list
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch ((enum Section)section) {
        case kSectionPostURL: return 1;
        case kSectionBonjour: return self.bonjourFinder.services.count;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section;    // fixed font style. use custom view (UILabel) if you want something different
{
    switch ((enum Section)section) {
        case kSectionPostURL: return NSLocalizedString(@"Party Play Server URL", @"");
        case kSectionBonjour: return NSLocalizedString(@"Servers on near network", @"");
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section;    // fixed font style. use custom view (UILabel) if you want something different
{
    switch ((enum Section)section) {
        case kSectionPostURL: return NSLocalizedString(@"or select a server on near network", @"");
        case kSectionBonjour: return NSLocalizedString(@"Searching...", @"");
    }
}

- (NSURL *)urlForService:(NSNetService *)service
{
    NSString *urlString = [NSString stringWithFormat:@"http://%@:%ld", service.hostName, (long)service.port];
    return [NSURL URLWithString:urlString];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch ((enum Section)indexPath.section) {
        case kSectionPostURL: return [self postURLCell];
        case kSectionBonjour: return [self bonjourCellForRow:indexPath.row];
    }
}

- (UITableViewCell *)postURLCell
{
    TextFieldTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kPostURLCellID];
    if (!cell) {
        cell = [[TextFieldTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kPostURLCellID];
        self.postURLField = [cell.textField btk_scope:^(UITextField *t) {
            t.delegate = self;
            t.placeholder = NSLocalizedString(@"http://mzp-tv.local.:3000/", @"");
            t.adjustsFontSizeToFitWidth = YES;
            t.clearButtonMode = UITextFieldViewModeWhileEditing;
            [t addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        }];
    }
    
    cell.textField.text = (self.selectedService ? [self urlForService:self.selectedService].absoluteString : self.initialBaseURL.absoluteString);
    
    return cell;
}

- (UITableViewCell *)bonjourCellForRow:(NSInteger)row
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kCellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kCellID];
    }
    
    NSNetService *service = self.bonjourFinder.services[row];
    
    BOOL resolved = (service.hostName.length > 0);
    
    cell.textLabel.text = service.name;
    cell.textLabel.enabled = resolved;
    cell.detailTextLabel.text = (resolved ? [self urlForService:service].absoluteString : @"checking address...");
    cell.detailTextLabel.enabled = resolved;
    cell.selectionStyle = (resolved ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone);
    
    cell.accessoryType = (self.selectedService == service ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSNetService *service = self.bonjourFinder.services[indexPath.row];
    if (service.hostName.length <= 0) return;
    self.selectedService = service;
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kSectionBonjour] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - Text Field Delegate

- (IBAction)textFieldDidChange:(UITextField *)sender
{
    NSNetService *matchedService = [self.bonjourFinder.services findFirst:^BOOL(NSNetService *s){
        return [sender.text isEqualToString:[self urlForService:s].absoluteString];
    }];
    if (matchedService != self.selectedService) {
        self.selectedService = matchedService;
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kSectionBonjour] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField;
{
    [textField resignFirstResponder];
    return YES;
}


@end


@implementation TextFieldTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.textField = [[UITextField alloc] initWithFrame:CGRectZero];
        self.textField.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:self.textField];
        
        NSDictionary *views = NSDictionaryOfVariableBindings(_textField);
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-16-[_textField]-16-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-8-[_textField]-8-|" options:0 metrics:nil views:views]];
        
    }
    return self;
}

@end