//
//  RootViewController.h
//  StrasPark
//
//  Created by Stéphan Mertz on 05/04/13.
//  Copyright (c) 2013 Stéphan Mertz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <iAd/iAd.h>

@class Park;

extern NSString *kSelectParkNotif;
extern NSString *kSelectedParkKey;

@interface RootViewController : UITableViewController <ADBannerViewDelegate> {
    NSDateFormatter *dateFormatter;
}

@property (nonatomic, strong) NSMutableArray *parkList;
@property (nonatomic, strong) ADBannerView *banner;
@property (nonatomic, retain, readonly) NSDateFormatter *dateFormatter;

- (void)insertParks:(NSArray *)parks;
- (void)refreshParks:(NSDate *)refreshDate;
- (Park *)findParkForIdent:(NSNumber *)ident;

@end
