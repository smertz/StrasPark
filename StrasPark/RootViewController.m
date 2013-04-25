//
//  RootViewController.m
//  StrasPark
//
//  Created by Stéphan Mertz on 05/04/13.
//  Copyright (c) 2013 Stéphan Mertz. All rights reserved.
//

#import "RootViewController.h"
#import "Park.h"

#import <iAd/iAd.h>
#import <MapKit/MapKit.h>

#import "GADSearchRequest.h"

NSString *kSelectParkNotif = @"SelectParkNotif";
NSString *kSelectedParkKey = @"SelectedParkKey";

NSString *kSourceStrasbourgDataKey = @"Strasbourg data & OpenData de la Ville de Strasbourg.";
NSString *kSourceStrasbourgOpenDataKey = @"OpenData de la Ville de Strasbourg.";

NSString *kNearKey = nil;
NSString *kAlphaKey = nil;

@interface RootViewController ()
    @property (nonatomic, strong) NSDate *refreshDate;
@end

@implementation RootViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.useIAD = YES;
    [self.navigationItem setTitle:NSLocalizedString(@"NavigationTitle", @"")];
    
    kNearKey = NSLocalizedString(@"Classer par proximité", @"");
    kAlphaKey = NSLocalizedString(@"Classer par ordre alphabétique", @"");
    
    self.parkList = [NSMutableArray array];
    self.parksNearMeButton.title = kNearKey;

    self.tableView.rowHeight = 32.0;
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    
    [refreshControl addTarget:[[UIApplication sharedApplication] delegate] action:@selector(refreshControlRequest:) forControlEvents:UIControlEventValueChanged];
    [self setRefreshControl:refreshControl];

    ADBannerView *adView = [[ADBannerView alloc] initWithFrame:CGRectZero];
    adView.requiredContentSizeIdentifiers = [NSSet setWithObject:ADBannerContentSizeIdentifierPortrait];
    adView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
    adView.delegate = self;
    self.banner = adView;
    
    GADBannerView *bannerView_ = [[GADBannerView alloc]
                                  initWithFrame:CGRectMake(0.0,
                                                           self.view.frame.size.height -
                                                           GAD_SIZE_320x50.height,
                                                           GAD_SIZE_320x50.width,
                                                           GAD_SIZE_320x50.height)];
    
    // Specify the ad's "unit identifier." This is your AdMob Publisher ID.
    bannerView_.adUnitID = @"a1516c76a074635";
    
    // Let the runtime know which UIViewController to restore after taking
    // the user wherever the ad goes and add it to the view hierarchy.
    bannerView_.rootViewController = self;
    
    // Initiate a generic request to load it with an ad.
    //[adRequest setQuery:@"strasbourg"];
    //[bannerView_ loadRequest:request];
    self.adMobBanner = bannerView_;
    
    [self addObserver:self forKeyPath:@"parkList" options:0 context:NULL];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    self.parkList = nil;
    
    [self removeObserver:self forKeyPath:@"parkList"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) startUpdatingLocation
{
    // Create the location manager if this object does not already have one.
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        if (nil == self.locationManager)
            self.locationManager = [[CLLocationManager alloc] init];
    
        [self.locationManager setDelegate:self];
        [self.locationManager setDesiredAccuracy:kCLLocationAccuracyHundredMeters];
        
        // Set a movement threshold for new events.
        [self.locationManager setDistanceFilter:50];
        
        [self.locationManager startUpdatingLocation];
        [self performSelector:@selector(stopUpdatingLocation:) withObject:@"Timed Out" afterDelay:20];
    } else {
        self.parksNearMeButton.enabled = NO;
    }
}

- (void) filterPark
{
    if ([self.parksNearMeButton.title isEqualToString:kAlphaKey]) {
        [self.parkList sortUsingComparator:(NSComparator)^(Park *obj1, Park *obj2){
            double dist1 = [obj1 distance];
            double dist2 = [obj2 distance];
            return dist1 > dist2; }];
    } else {
        [self.parkList sortUsingComparator:(NSComparator)^(Park *obj1, Park *obj2){
            NSString *nom1 = [obj1 nom];
            NSString *nom2 = [obj2 nom];
            return [nom1 caseInsensitiveCompare:nom2]; }];
    }
}

- (IBAction) toogleButtonAction:(id)sender
{
    if ([self.parksNearMeButton.title isEqualToString:kAlphaKey]) {
        self.parksNearMeButton.title = kNearKey;
    } else {
        self.parksNearMeButton.title = kAlphaKey;
    }
    
    [self filterPark];
    [self.tableView reloadData];
}

- (IBAction) refreshButtonAction:(id)sender;
{
}

- (Park *)findParkForIdent:(NSNumber *) ident {
    Park *park = nil;
    
    for (int i=0; i<[self.parkList count] && park == nil; i++) {
        Park *aPark = [self.parkList objectAtIndex:i];
        
        if ([aPark.ident isEqual:ident]) {
            park = aPark;
        }
    }
    
    return park;
}

#pragma mark - Location Manager Interactions

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    // If it's a relatively recent event, turn off updates to save power
    CLLocation* location = [locations lastObject];
    NSDate* eventDate = location.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    
    if (abs(howRecent) < 15.0 && location.horizontalAccuracy > 0 && location.horizontalAccuracy <= manager.desiredAccuracy) {
        [self willChangeValueForKey:@"parkList"];
        for (int i=0; i<[self.parkList count]; i++) {
            Park *aPark = [self.parkList objectAtIndex:i];
            CLLocation *loc = [[CLLocation alloc] initWithLatitude:aPark.latitude longitude:aPark.longitude];
            CLLocationDistance distance = [manager.location distanceFromLocation:loc];
            
            if (distance > 10000) {
                aPark.distance = 0;
            } else {
                aPark.distance = distance;
            }
        }
        
        [self stopUpdatingLocation:NSLocalizedString(@"Acquired Location", @"Acquired Location")];
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stopUpdatingLocation:) object:nil];
        [self didChangeValueForKey:@"parkList"];
        self.parksNearMeButton.enabled = YES;
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    // The location "unknown" error simply means the manager is currently unable to get the location.
    // We can ignore this error for the scenario of getting a single location fix, because we already have a
    // timeout that will stop the location manager to save power.
    if ([error code] != kCLErrorLocationUnknown) {
        [self stopUpdatingLocation:NSLocalizedString(@"Error", @"Error")];
    }
}

- (void)stopUpdatingLocation:(NSString *)state
{
    [self.locationManager stopUpdatingLocation];
    self.locationManager.delegate = nil;
}

#pragma mark - KVO support

- (void)insertParks:(NSArray *)parks source:(NSString *)sourceKey
{
    [self willChangeValueForKey:@"parkList"];
    self.sourceKey = sourceKey;
    [self.parkList addObjectsFromArray:parks];
    [self filterPark];
    [self startUpdatingLocation];
    [self didChangeValueForKey:@"parkList"];
    [self.refreshControl endRefreshing];
}

- (void)refreshParks:(NSDate *)refreshDate source:(NSString *)sourceKey
{
    [self willChangeValueForKey:@"parkList"];
    if (self.refreshDate != nil) {
        NSTimeInterval howRecent = [self.refreshDate timeIntervalSinceNow];
        if (abs(howRecent) > (60 * 15)) {
            for (Park *park in self.parkList) {
                park.previousPlace = -1;
            }
        }
    }
    
    self.refreshDate = refreshDate;
    self.sourceKey = sourceKey;
    [self filterPark];
    [self startUpdatingLocation];
    [self didChangeValueForKey:@"parkList"];
    [self.refreshControl endRefreshing];
    if (self.useIAD == NO) {
        GADRequest *request = [GADRequest request];
        request.testDevices = [NSArray arrayWithObjects:
                               //@"2f5a30b5de9edb8d7e284ec322945c84",
                               GAD_SIMULATOR_ID,
                               nil];
        [self.adMobBanner loadRequest:request];
    }
}

// listen for changes to the park list coming from our app delegate.
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    [self filterPark];
    [self.tableView reloadData];
}

- (NSDateFormatter *)dateFormatter {
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterFullStyle];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [dateFormatter setLocale:[NSLocale currentLocale]];
    }
    
    return dateFormatter;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.parkList count] + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    if (indexPath.row == [self.parkList count]) {
        static NSString *kLicenceCellID = @"LicenceCellID";
        static NSUInteger const kLicenceLabelTag = 2;
        static NSUInteger const kDateLabelTag = 3;
        UILabel *licenceLabel = nil;
        UILabel *dateLabel = nil;

        cell = [tableView dequeueReusableCellWithIdentifier:kLicenceCellID];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kLicenceCellID];
            
            licenceLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 3, 300, 13)];
            licenceLabel.tag = kLicenceLabelTag;
            licenceLabel.font = [UIFont fontWithName:@"Helvetica" size:10];
            licenceLabel.textAlignment = NSTextAlignmentCenter;
            [cell.contentView addSubview:licenceLabel];
            
            dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 17, 300, 13)];
            dateLabel.tag = kDateLabelTag;
            dateLabel.font = [UIFont fontWithName:@"Helvetica" size:10];
            dateLabel.textAlignment = NSTextAlignmentCenter;
            [cell.contentView addSubview:dateLabel];
        } else {
            licenceLabel = (UILabel *)[cell.contentView viewWithTag:kLicenceLabelTag];
            dateLabel = (UILabel *)[cell.contentView viewWithTag:kDateLabelTag];
        }
        
        if (self.sourceKey != nil) {
            licenceLabel.text = [NSString stringWithFormat:@"Sources : %@", self.sourceKey];
        } else {
            licenceLabel.text = NSLocalizedString(@"Chargement en cours...", @"");
        }
        
        if (self.refreshDate != nil) {
            dateLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Dernier rafraîchissement : %@", @""), [self.dateFormatter stringFromDate:self.refreshDate]];
        }
    } else {
        // Each subview in the cell will be identified by a unique tag.
        static NSUInteger const kDistanceLabelTag = 1;
        static NSUInteger const kLocationLabelTag = 2;
        static NSUInteger const kPlaceLabelTag = 3;
        static NSUInteger const kTotalLabelTag = 4;
        static NSUInteger const kClosedLabelTag = 5;
        static NSUInteger const kDeltaImageTag = 6;
        
        // Declare references to the subviews which will display the park data.
        UILabel *locationLabel = nil;
        UILabel *distanceLabel = nil;
        UILabel *placeLabel = nil;
        UILabel *totalLabel = nil;
        UILabel *closedLabel = nil;
        UIImageView *deltaImage;
        
        static NSString *kParkCellID = @"ParkCellID";
        cell = [tableView dequeueReusableCellWithIdentifier:kParkCellID];
        if (cell == nil) {
            // No reusable cell was available, so we create a new cell and configure its subviews.
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kParkCellID];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            locationLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 1, 180, 20)];
            locationLabel.tag = kLocationLabelTag;
            locationLabel.font = [UIFont fontWithName:@"Helvetica" size:16];
            locationLabel.autoresizingMask = UIViewAutoresizingNone;
            locationLabel.textAlignment = NSTextAlignmentLeft;
            [cell.contentView addSubview:locationLabel];
            
            placeLabel = [[UILabel alloc] initWithFrame:CGRectMake(180, 5.5, 50, 20)];
            placeLabel.tag = kPlaceLabelTag;
            placeLabel.font = [UIFont fontWithName:@"Helvetica" size:18];
            placeLabel.textAlignment = NSTextAlignmentRight;
            placeLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            [cell.contentView addSubview:placeLabel];
            
            distanceLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 20, 100, 10)];
            distanceLabel.tag = kDistanceLabelTag;
            distanceLabel.font = [UIFont fontWithName:@"Helvetica" size:10];
            distanceLabel.textAlignment = NSTextAlignmentLeft;
            distanceLabel.autoresizingMask = UIViewAutoresizingNone;
            [cell.contentView addSubview:distanceLabel];
            
            totalLabel = [[UILabel alloc] initWithFrame:CGRectMake(235, 7.5, 55, 20)];
            totalLabel.tag = kTotalLabelTag;
            totalLabel.font = [UIFont fontWithName:@"Helvetica" size:10];
            totalLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            [cell.contentView addSubview:totalLabel];
            
            closedLabel = [[UILabel alloc] initWithFrame:CGRectMake(190, 7.5, 95, 20)];
            closedLabel.tag = kClosedLabelTag;
            closedLabel.font = [UIFont fontWithName:@"Helvetica" size:12];
            closedLabel.textColor = [UIColor redColor];
            //closedLabel.backgroundColor = [UIColor lightGrayColor];
            closedLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            [cell.contentView addSubview:closedLabel];
            [cell.contentView sendSubviewToBack:closedLabel];
            
            deltaImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"arrow_down.png"]];
            CGRect imageFrame = deltaImage.frame;
            imageFrame.origin = CGPointMake(292, 4);
            deltaImage.frame = imageFrame;
            deltaImage.tag = kDeltaImageTag;
            deltaImage.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            [cell.contentView addSubview:deltaImage];
        } else {
            // A reusable cell was available, so we just need to get a reference to the subviews
            // using their tags.
            //
            locationLabel = (UILabel *)[cell.contentView viewWithTag:kLocationLabelTag];
            distanceLabel = (UILabel *)[cell.contentView viewWithTag:kDistanceLabelTag];
            placeLabel = (UILabel *)[cell.contentView viewWithTag:kPlaceLabelTag];
            totalLabel = (UILabel *)[cell.contentView viewWithTag:kTotalLabelTag];
            closedLabel = (UILabel *)[cell.contentView viewWithTag:kClosedLabelTag];
            deltaImage = (UIImageView *)[cell.contentView viewWithTag:kDeltaImageTag];
        }
        
        // Get the specific park for this row.
        Park *park = [self.parkList objectAtIndex:indexPath.row];
        
        // Set the relevant data for each subview in the cell.
        locationLabel.text = park.nom;
        if ([park.infos rangeOfString:@"FERME"].length != 0) {
            closedLabel.text = NSLocalizedString(@"FERMÉ", @"");
            [cell.contentView bringSubviewToFront:closedLabel];
            totalLabel.text = @"";
            placeLabel.text = @"";
            deltaImage.image = nil;
        } else {
            [cell.contentView bringSubviewToFront:placeLabel];
            [cell.contentView bringSubviewToFront:totalLabel];
            closedLabel.text = @"";
            placeLabel.text = [NSString stringWithFormat:@"%i", park.place];
            if (park.place <= 1) {
                totalLabel.text = [NSString stringWithFormat:NSLocalizedString(@"libre / %i", @""), park.capacity];
            } else {
                totalLabel.text = [NSString stringWithFormat:NSLocalizedString(@"libres / %i", @""), park.capacity];
            }
    
            deltaImage.image = [self imageForPark:park];
        }
        
        if (park.distance == -1) {
            distanceLabel.text = @"";
        } else if (park.distance > 3000) {
            distanceLabel.text = [NSString stringWithFormat:NSLocalizedString(@"à %.0f km%@", @""), park.distance/1000, (park.distance/1000 > 1 ? NSLocalizedString(@"km_pluriel", @"") : @"")];
        } else {
            distanceLabel.text = [NSString stringWithFormat:NSLocalizedString(@"à %.0f mètre%@", @""), park.distance, (park.distance > 1 ? NSLocalizedString(@"m_pluriel", @"") : @"")];
        }
    }
    
	return cell;
}

- (UIImage *)imageForPark:(Park *)park {
    if (park.previousPlace != -1) {
        if (park.previousPlace > park.place) {
            return [UIImage imageNamed:@"arrow_down.png"];
        } else if (park.previousPlace < park.place) {
            return [UIImage imageNamed:@"arrow_up.png"];
        }
    }

	return nil;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Park *park = [self.parkList objectAtIndex:indexPath.row];

    [[NSNotificationCenter defaultCenter] postNotificationName:kSelectParkNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:park
                                                                                           forKey:kSelectedParkKey]];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (self.banner.bannerLoaded && self.useIAD) {
        return self.banner;
    }
    
    return self.adMobBanner;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (self.banner.bannerLoaded && self.useIAD) {
        return [ADBannerView sizeFromBannerContentSizeIdentifier:ADBannerContentSizeIdentifierPortrait].height;
    } else if (self.useIAD == NO) {
        return GAD_SIZE_320x50.height;
    }

    
    return 0;
}

#pragma mark - ADBannerViewDelegate methods

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    [self.tableView reloadData];
}

- (void)bannerViewWillLoadAd:(ADBannerView *)banner
{
    [self.tableView reloadData];
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    [self.tableView reloadData];
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
    return YES;
}

-(void)bannerViewActionDidFinish:(ADBannerView *)banner
{
}

@end
