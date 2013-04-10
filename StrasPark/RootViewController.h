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

extern NSString *kSourceStrasbourgDataKey;
extern NSString *kSourceStrasbourgOpenDataKey;

@interface RootViewController : UITableViewController <ADBannerViewDelegate> {
    NSDateFormatter *dateFormatter;
}

@property (nonatomic, strong) NSMutableArray *parkList;
@property (nonatomic, strong) NSString *sourceKey;
@property (nonatomic, strong) ADBannerView *banner;
@property (nonatomic, retain, readonly) NSDateFormatter *dateFormatter;

- (void)insertParks:(NSArray *)parks source:(NSString *)sourceKey;
- (void)refreshParks:(NSDate *)refreshDate source:(NSString *)sourceKey;
- (Park *)findParkForIdent:(NSNumber *)ident;

@end
