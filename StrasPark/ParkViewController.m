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

NSString* AnnotationIdentifier = @"AnnotationIdentifier";

@interface ParkViewController ()

@end

@implementation ParkViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.mapView.showsUserLocation = YES;
    //[self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(self.park.latitude, self.park.longitude) animated:YES];
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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction) directionToPark: (id)sender
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
