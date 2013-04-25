//
//  ParkViewController.m
//  StrasPark
//
//  Created by Stéphan Mertz on 07/04/13.
//  Copyright (c) 2013 Stéphan Mertz. All rights reserved.
//

#import <MapKit/MapKit.h>

#import "ParkViewController.h"
#import "ParkAnnotation.h"
#import "ParseOperation.h"

NSString* AnnotationIdentifier = @"AnnotationIdentifier";

@interface ParkViewController ()

@end

@implementation ParkViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.routeButton setTitle:NSLocalizedString(@"Itinéraire vers ce parking", @"") forState:UIControlStateNormal];
    self.mapView.showsUserLocation = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshPark:)
                                                 name:kRefreshParksNotif
                                               object:nil];
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

- (void)refreshDisplay
{
    self.parkName.text = self.park.nom;
    if ([self.park.infos rangeOfString:@"FERME"].length != 0) {
        self.parkPlace.text = NSLocalizedString(@"FERMÉ", @"");
        self.parkPlace.textColor = [UIColor redColor];
        self.parkUpDown.image = nil;
    } else {
        self.parkPlace.textColor = [UIColor blackColor];
        if (self.park.place <= 1) {
            self.parkPlace.text = [NSString stringWithFormat:NSLocalizedString(@"%i place libre / %i", @""), self.park.place , self.park.capacity];
        } else {
            self.parkPlace.text = [NSString stringWithFormat:NSLocalizedString(@"%i places libres / %i", @""), self.park.place, self.park.capacity];
        }

        self.parkUpDown.image = [self imageForPark:self.park];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [self refreshDisplay];
    [self.mapView setShowsUserLocation:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    MKCoordinateRegion newRegion;
    newRegion.center = CLLocationCoordinate2DMake(self.park.latitude, self.park.longitude);
    newRegion.span.latitudeDelta = 0.01;
    newRegion.span.longitudeDelta = 0.01;
    self.mapView.zoomEnabled = YES;
    [self.mapView setRegion:newRegion animated:YES];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView setShowsUserLocation:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction) directionToPark: (id)sender
{
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps://"]]) {
        UIAlertView *servicesDisabledAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Itinéraire", @"")
                                                                        message:NSLocalizedString(@"Quelle application utiliser ?", @"")
                                                                       delegate:self
                                                              cancelButtonTitle:NSLocalizedString(@"Non merci", @"")
                                                              otherButtonTitles:NSLocalizedString(@"Maps", @""), @"Google Maps", nil];
        [servicesDisabledAlert show];
    } else {
        [self alertView:nil clickedButtonAtIndex:0];
    }
}

- (void)refreshPark:(NSNotification *)notif {
    assert([NSThread isMainThread]);
    [self refreshDisplay];
}

#pragma mark -
#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 1:
        {
            NSMutableArray *items = [NSMutableArray new];
            MKMapItem *item = [[MKMapItem alloc] initWithPlacemark:[[MKPlacemark alloc] initWithCoordinate:CLLocationCoordinate2DMake(self.park.latitude, self.park.longitude)
                                                                                         addressDictionary:nil]];
            item.name = [NSString stringWithFormat:@"Parking %@", self.park.nom];
            [items addObject:item];
            //[items addObject:[MKMapItem mapItemForCurrentLocation]];
            [MKMapItem openMapsWithItems:items
                           launchOptions:[NSDictionary dictionaryWithObjectsAndKeys:MKLaunchOptionsDirectionsModeKey, MKLaunchOptionsDirectionsModeDriving, nil]];
        }
            break;
            
        case 2:
        {
            NSString *url = [NSString stringWithFormat:@"comgooglemaps://?daddr=%f,%f&zoom=17&directionsmode=driving", self.park.latitude, self.park.longitude];
            
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
        }
            break;
            
        default:
            break;
    }
}

#pragma mark -
#pragma mark MKMapViewDelegate

- (void)mapView:(MKMapView *)aMapView regionDidChangeAnimated:(BOOL)animated
{
    NSArray *annotations = [aMapView annotations];
    NSString *address = [NSString stringWithFormat:@"Parking %@", self.park.nom];
    ParkAnnotation *annotation = nil;
    
    for (int i=0; i<[annotations count] && annotation == nil; i++) {
        ParkAnnotation *otherAnnotation = [annotations objectAtIndex:i];
        
        if ([[otherAnnotation title] isEqualToString:address]) {
            annotation = otherAnnotation;
        }
    }
    
	if (annotation == nil) {
		annotation = [[ParkAnnotation alloc] init];
		annotation.coordinate = CLLocationCoordinate2DMake(self.park.latitude, self.park.longitude);
		annotation.title = address;
		annotation.subtitle = nil;
		[self.mapView addAnnotation:annotation];
	}
}

- (MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    // if it's the user location, just return nil.
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    if ([annotation isKindOfClass:[ParkAnnotation class]]) {
        MKPinAnnotationView* pinView = (MKPinAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:AnnotationIdentifier];
		
        if (!pinView) {
            MKPinAnnotationView *annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation
                                                                                  reuseIdentifier:AnnotationIdentifier];
            annotationView.animatesDrop = YES;
            annotationView.canShowCallout = YES;
			
            return annotationView;
        } else {
            pinView.annotation = annotation;
        }
		
        return pinView;
    }
    
    return nil;
}


#pragma mark -
#pragma mark ADBannerViewDelegate methods

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
    // While the banner is visible, we don't need to tie up Core Location to track the user location
    // so we turn off the map's display of the user location. We'll turn it back on when the ad is dismissed.
    return YES;
}

- (void)bannerViewActionDidFinish:(ADBannerView *)banner
{
    // Now that the banner is dismissed, we track the user's location again.
}

@end
