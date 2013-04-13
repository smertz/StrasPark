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

@property (nonatomic, strong) IBOutlet UILabel *parkName;
@property (nonatomic, strong) IBOutlet UILabel *parkPlace;
@property (nonatomic, strong) IBOutlet UIImageView *parkUpDown;
@property(nonatomic, strong) IBOutlet MKMapView *mapView;
@property(nonatomic, strong) IBOutlet UIButton *routeButton;

@property(nonatomic, strong) Park *park;

- (IBAction) directionToPark: (id)sender;

@end
