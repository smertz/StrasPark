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

NSString *kSelectParkNotif = @"SelectParkNotif";
NSString *kSelectedParkKey = @"SelectedParkKey";

@interface RootViewController ()
    @property (nonatomic, strong) NSDate *refreshDate;
@end

@implementation RootViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.parkList = [NSMutableArray array];

    self.tableView.rowHeight = 32.0;
    //if (self.banner == nil) {
    //    [self createADBannerView];
    //}

    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    
    [refreshControl addTarget:[[UIApplication sharedApplication] delegate] action:@selector(refreshControlRequest:) forControlEvents:UIControlEventValueChanged];
    [self setRefreshControl:refreshControl];

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

- (void)createADBannerView
{
	NSString *contentSize;
	if (&ADBannerContentSizeIdentifierPortrait != nil) {
		contentSize = UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? ADBannerContentSizeIdentifierPortrait : ADBannerContentSizeIdentifierLandscape;
	} else {
		// user the older sizes
		contentSize = UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? ADBannerContentSizeIdentifier320x50 : ADBannerContentSizeIdentifier480x32;
    }
	
    // Calculate the intial location for the banner.
    // We want this banner to be at the bottom of the view controller, but placed
    // offscreen to ensure that the user won't see the banner until its ready.
    // We'll be informed when we have an ad to show because -bannerViewDidLoadAd: will be called.
    CGRect frame;
    frame.size = [ADBannerView sizeFromBannerContentSizeIdentifier:contentSize];
    frame.origin = CGPointMake(0.0f, CGRectGetMaxY(self.view.bounds));
    
    // Now to create and configure the banner view
    ADBannerView *bannerView = [[ADBannerView alloc] initWithFrame:frame];
    // Set the delegate to self, so that we are notified of ad responses.
    bannerView.delegate = self;
    // Set the autoresizing mask so that the banner is pinned to the bottom
    bannerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin;
    // Since we support all orientations in this view controller, support portrait and landscape content sizes.
    // If you only supported landscape or portrait, you could remove the other from this set.
    
	bannerView.requiredContentSizeIdentifiers = (&ADBannerContentSizeIdentifierPortrait != nil) ?
        [NSSet setWithObjects:ADBannerContentSizeIdentifierPortrait, ADBannerContentSizeIdentifierLandscape, nil] :
        [NSSet setWithObjects:ADBannerContentSizeIdentifier320x50, ADBannerContentSizeIdentifier480x32, nil];
    
    // At this point the ad banner is now be visible and looking for an ad.
    [self.view addSubview:bannerView];
    self.banner = bannerView;
}

-(void)layoutForCurrentOrientation:(BOOL)animated
{
    CGFloat animationDuration = animated ? 0.2f : 0.0f;
    // by default content consumes the entire view area
    CGRect contentFrame = self.view.bounds;
    // the banner still needs to be adjusted further, but this is a reasonable starting point
    // the y value will need to be adjusted by the banner height to get the final position
	CGPoint bannerOrigin = CGPointMake(CGRectGetMinX(contentFrame), CGRectGetMaxY(contentFrame));
    CGFloat bannerHeight = 0.0f;
    
    // First, setup the banner's content size and adjustment based on the current orientation
    if(UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
		self.banner.currentContentSizeIdentifier = (&ADBannerContentSizeIdentifierLandscape != nil) ? ADBannerContentSizeIdentifierLandscape : ADBannerContentSizeIdentifier480x32;
    else
        self.banner.currentContentSizeIdentifier = (&ADBannerContentSizeIdentifierPortrait != nil) ? ADBannerContentSizeIdentifierPortrait : ADBannerContentSizeIdentifier320x50;
    bannerHeight = self.banner.bounds.size.height;
	
    // Depending on if the banner has been loaded, we adjust the content frame and banner location
    // to accomodate the ad being on or off screen.
    // This layout is for an ad at the bottom of the view.
    if(self.banner.bannerLoaded) {
        contentFrame.size.height -= bannerHeight;
		bannerOrigin.y -= bannerHeight;
    } else {
		bannerOrigin.y += bannerHeight;
    }
    
    // And finally animate the changes, running layout for the content view if required.
    [UIView animateWithDuration:animationDuration
                     animations:^{
                         self.view.frame = contentFrame;
                         [self.view layoutIfNeeded];
                         self.banner.frame = CGRectMake(bannerOrigin.x, bannerOrigin.y, self.banner.frame.size.width, self.banner.frame.size.height);
                     }];
}

#pragma mark -
#pragma mark KVO support

- (void)insertParks:(NSArray *)parks
{
    [self willChangeValueForKey:@"parkList"];
    [self.parkList addObjectsFromArray:parks];
    [self.parkList sortUsingComparator:(NSComparator)^(Park *obj1, Park *obj2){
        NSString *nom1 = [obj1 nom];
        NSString *nom2 = [obj2 nom];
        return [nom1 caseInsensitiveCompare:nom2]; }];
    [self didChangeValueForKey:@"parkList"];
}

- (void)refreshParks:(NSDate *)refreshDate
{
    self.refreshDate = refreshDate;
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

// listen for changes to the park list coming from our app delegate.
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
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
/*
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 0;
}
*/
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
        
        licenceLabel.text = @"Sources : OpenData de la Ville de Strasbourg.";
        if (self.refreshDate != nil) {
            dateLabel.text = [NSString stringWithFormat:@"Dernier rafraîchissement : %@", [self.dateFormatter stringFromDate:self.refreshDate]];
        }
    } else {
        // Each subview in the cell will be identified by a unique tag.
        static NSUInteger const kLocationLabelTag = 2;
        static NSUInteger const kPlaceLabelTag = 3;
        static NSUInteger const kTotalLabelTag = 4;
        static NSUInteger const kDeltaLabelTag = 5;
        
        //UIColor *color = (indexPath.row % 2 == 0) ? [UIColor lightGrayColor] : [UIColor whiteColor];
        
        // Declare references to the subviews which will display the park data.
        UILabel *locationLabel = nil;
        UILabel *placeLabel = nil;
        UILabel *totalLabel = nil;
        UILabel *deltaLabel = nil;
        
        static NSString *kParkCellID = @"ParkCellID";
        cell = [tableView dequeueReusableCellWithIdentifier:kParkCellID];
        if (cell == nil) {
            // No reusable cell was available, so we create a new cell and configure its subviews.
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kParkCellID];
            
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            locationLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 3, 175, 20)];
            locationLabel.tag = kLocationLabelTag;
            locationLabel.font = [UIFont fontWithName:@"Helvetica" size:16];
            [cell.contentView addSubview:locationLabel];
            
            placeLabel = [[UILabel alloc] initWithFrame:CGRectMake(180, 3, 50, 20)];
            placeLabel.tag = kPlaceLabelTag;
            placeLabel.font = [UIFont fontWithName:@"Helvetica" size:18];
            placeLabel.textAlignment = NSTextAlignmentRight;
            placeLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            [cell.contentView addSubview:placeLabel];
            
            totalLabel = [[UILabel alloc] initWithFrame:CGRectMake(235, 5, 60, 20)];
            totalLabel.tag = kTotalLabelTag;
            totalLabel.font = [UIFont fontWithName:@"Helvetica" size:10];
            totalLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            [cell.contentView addSubview:totalLabel];
            
            deltaLabel = [[UILabel alloc] initWithFrame:CGRectMake(300, 5, 20, 20)];
            deltaLabel.tag = kDeltaLabelTag;
            deltaLabel.font = [UIFont fontWithName:@"Symbol" size:18];
            deltaLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            [cell.contentView addSubview:deltaLabel];

            /*deltaImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"5.0.png"]];
             CGRect imageFrame = deltaImage.frame;
             imageFrame.origin = CGPointMake(180, 2);
             deltaImage.frame = imageFrame;
             deltaImage.tag = kDeltaImageTag;
             deltaImage.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
             [cell.contentView addSubview:deltaImage];*/
        } else {
            // A reusable cell was available, so we just need to get a reference to the subviews
            // using their tags.
            //
            locationLabel = (UILabel *)[cell.contentView viewWithTag:kLocationLabelTag];
            placeLabel = (UILabel *)[cell.contentView viewWithTag:kPlaceLabelTag];
            totalLabel = (UILabel *)[cell.contentView viewWithTag:kTotalLabelTag];
            deltaLabel = (UILabel *)[cell.contentView viewWithTag:kDeltaLabelTag];
            //deltaImage = (UIImageView *)[cell.contentView viewWithTag:kDeltaImageTag];
        }
        
        // Get the specific park for this row.
        Park *park = [self.parkList objectAtIndex:indexPath.row];
        
        // Set the relevant data for each subview in the cell.
        locationLabel.text = park.nom;
        if ([park.infos rangeOfString:@"FERME"].length != 0) {
            totalLabel.text = park.infos;
            totalLabel.textColor = [UIColor redColor];
            placeLabel.text = @"";
            deltaLabel.text = @"";
        } else {
            if (park.previousPlace != 0) {
                if (park.previousPlace > park.place) {
                    deltaLabel.textColor = [UIColor redColor];
                    deltaLabel.text = @"\u2207";
                } else if (park.previousPlace < park.place) {
                    deltaLabel.textColor = [UIColor greenColor];
                    deltaLabel.text = @"\u0394";
                } else {
                    deltaLabel.textColor = [UIColor blackColor];
                    deltaLabel.text = @"";
                }
            } else {
                deltaLabel.text = @"";
            }
            
            totalLabel.textColor = [UIColor blackColor];
            placeLabel.text = [NSString stringWithFormat:@"%i", park.place];
            if (park.place <= 1) {
                totalLabel.text = [NSString stringWithFormat:@"libre / %i", park.capacity];
            } else {
                totalLabel.text = [NSString stringWithFormat:@"libres / %i", park.capacity];
            }
        }
    }
    
    //deltaImage.image = [self imageForMagnitude:park.magnitude];
    
	return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Park *park = [self.parkList objectAtIndex:indexPath.row];

    [[NSNotificationCenter defaultCenter] postNotificationName:kSelectParkNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:park
                                                                                           forKey:kSelectedParkKey]];
}

#pragma mark ADBannerViewDelegate methods

-(void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    [self layoutForCurrentOrientation:YES];
}

-(void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    [self layoutForCurrentOrientation:YES];
}

-(BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
    return YES;
}

-(void)bannerViewActionDidFinish:(ADBannerView *)banner
{
}

@end
