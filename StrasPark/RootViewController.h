//
//  RootViewController.h
//  StrasPark
//
//  Created by Stéphan Mertz on 05/04/13.
//  Copyright (c) 2013 Stéphan Mertz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <iAd/iAd.h>
#import <MapKit/MapKit.h>
#import "GADBannerView.h"

@class Park;

extern NSString *kSelectParkNotif;
extern NSString *kSelectedParkKey;

extern NSString *kSourceStrasbourgDataKey;
extern NSString *kSourceStrasbourgOpenDataKey;

@interface RootViewController : UITableViewController <ADBannerViewDelegate, CLLocationManagerDelegate> {
    NSDateFormatter *dateFormatter;
}

@property (nonatomic, strong) IBOutlet UIBarButtonItem *parksNearMeButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *refreshButton;

@property (nonatomic, strong) ADBannerView *banner;
@property (nonatomic, strong) GADBannerView *adMobBanner;
@property (nonatomic) BOOL adBannerViewIsVisible;
@property (nonatomic) BOOL useIAD;
@property (nonatomic, strong) CLLocationManager *locationManager;

@property (nonatomic, strong) NSMutableArray *parkList;
@property (nonatomic, strong) NSString *sourceKey;
@property (nonatomic, retain, readonly) NSDateFormatter *dateFormatter;

- (IBAction) toogleButtonAction:(id)sender;
- (IBAction) refreshButtonAction:(id)sender;

- (void)insertParks:(NSArray *)parks source:(NSString *)sourceKey;
- (void)refreshParks:(NSDate *)refreshDate source:(NSString *)sourceKey;
- (Park *)findParkForIdent:(NSNumber *)ident;

@end
