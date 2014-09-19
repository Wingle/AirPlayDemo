//
//  ViewController.m
//  AirPlayDemo
//
//  Created by Wingle Wong on 7/24/14.
//  Copyright (c) 2014 Koudai. All rights reserved.
//

#import "ViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <arpa/inet.h>

//#define kWebServiceType @"_http._tcp"
//#define kWebServiceType @"_rc._tcp"
#define kWebServiceType @"_kdrc._tcp"
//#define kWebServiceType @"_airplay._tcp"
#define kInitialDomain  @"local"

@interface ViewController () <NSNetServiceBrowserDelegate, NSNetServiceDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) MPVolumeView *airplayButton;
@property (nonatomic, strong) NSNetServiceBrowser *nBrowser;
@property (nonatomic, strong) NSNetService *nService;

@property (nonatomic, strong) NSMutableArray *prints;
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor grayColor];
    self.prints = [NSMutableArray new];
    
    self.airplayButton = [[MPVolumeView alloc] initWithFrame:CGRectMake(320.f/2 - 60.f/2, 120.f, 60.f, 60.f)];
    [self.airplayButton setShowsVolumeSlider:NO];
    [self.view addSubview:self.airplayButton];
    
    self.nBrowser = [[NSNetServiceBrowser alloc] init];
    self.nBrowser.delegate = self;
    [self.nBrowser searchForServicesOfType:kWebServiceType inDomain:kInitialDomain];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 20.f, 320.f, 300.f) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString *)getStringFromAddressData:(NSData *)dataIn {
    //Function to parse address from NSData
    struct sockaddr_in  *socketAddress = nil;
    NSString            *ipString = nil;
    
    socketAddress = (struct sockaddr_in *)[dataIn bytes];
    ipString = [NSString stringWithFormat: @"%s",inet_ntoa(socketAddress->sin_addr)];  ///problem here
    return ipString;
}




#pragma mark - NSNetServiceBrowserDelegate Methods

/* Sent to the NSNetServiceBrowser instance's delegate before the instance begins a search. The delegate will not receive this message if the instance is unable to begin a search. Instead, the delegate will receive the -netServiceBrowser:didNotSearch: message.
 */
- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)aNetServiceBrowser {
    NSLog(@"netServiceBrowserWillSearch = %@", aNetServiceBrowser);
}

/* Sent to the NSNetServiceBrowser instance's delegate when the instance's previous running search request has stopped.
 */
- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)aNetServiceBrowser {
    NSLog(@"netServiceBrowserDidStopSearch = %@", aNetServiceBrowser);
}

/* Sent to the NSNetServiceBrowser instance's delegate when an error in searching for domains or services has occurred. The error dictionary will contain two key/value pairs representing the error domain and code (see the NSNetServicesError enumeration above for error code constants). It is possible for an error to occur after a search has been started successfully.
 */
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didNotSearch:(NSDictionary *)errorDict {
    NSLog(@"didNotSearch = %@, Error = %@", aNetServiceBrowser, errorDict);
}

/* Sent to the NSNetServiceBrowser instance's delegate for each domain discovered. If there are more domains, moreComing will be YES. If for some reason handling discovered domains requires significant processing, accumulating domains until moreComing is NO and then doing the processing in bulk fashion may be desirable.
 */
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindDomain:(NSString *)domainString moreComing:(BOOL)moreComing {
    NSLog(@"didFindDomain = %@, domainString = %@", aNetServiceBrowser, domainString);
}

/* Sent to the NSNetServiceBrowser instance's delegate for each service discovered. If there are more services, moreComing will be YES. If for some reason handling discovered services requires significant processing, accumulating services until moreComing is NO and then doing the processing in bulk fashion may be desirable.
 */
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {

//    NSLog(@"didFindService name = %@, hostName = %@, port = %d, count = %d", aNetService.name, aNetService.hostName, (short)aNetService.port, [aNetService.addresses count]);
    [self.prints addObject:aNetService];
    aNetService.delegate=self;
    [aNetService resolveWithTimeout:5.0];
    
}

/* Sent to the NSNetServiceBrowser instance's delegate when a previously discovered domain is no longer available.
 */
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveDomain:(NSString *)domainString moreComing:(BOOL)moreComing {
    NSLog(@"didRemoveDomain = %@, domainString = %@", aNetServiceBrowser, domainString);
}

/* Sent to the NSNetServiceBrowser instance's delegate when a previously discovered service is no longer published.
 */
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
    NSLog(@"didRemoveService = %@, aNetService = %@", aNetServiceBrowser, aNetService.hostName);
}

#pragma mark - NSNetServiceDelegate
- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
    if ([sender.addresses count] == 0) {
        return;
    }
    //delegate of NSNetService resolution process
    NSLog(@"IP = %@, Port = %d, name = %@, hostname = %@", [self getStringFromAddressData:[sender.addresses objectAtIndex:0]], (int)sender.port, sender.name, sender.hostName);
    
    [self.tableView reloadData];
}

#pragma mark - Tableview delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.prints count];
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *IDCell = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:IDCell];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:IDCell];
    }
    NSInteger row = [indexPath row];
    NSNetService *sender = self.prints[row];
    cell.textLabel.text = sender.name;
    cell.detailTextLabel.text = [self getStringFromAddressData:[sender.addresses objectAtIndex:0]];
    return cell;
}

@end
