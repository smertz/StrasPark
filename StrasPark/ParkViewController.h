//
//  ParkViewController.h
//  StrasPark
//
//  Created by Stéphan Mertz on 07/04/13.
//  Copyright (c) 2013 Stéphan Mertz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <iAd/iAd.h>
#import <MapKit/MapKit.h>
#import "Park.h"

@interface ParkViewController : UIViewController

@property(nonatomic, strong) Park *park;
@property(nonatomic, strong) IBOutlet MKMapView *mapView;

- (IBAction) directionToPark: (id)sender;

@end
