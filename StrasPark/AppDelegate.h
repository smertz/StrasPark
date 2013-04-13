//
//  AppDelegate.h
//  StrasPark
//
//  Created by Stéphan Mertz on 05/04/13.
//  Copyright (c) 2013 Stéphan Mertz. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Park, RootViewController, ParkViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate, NSXMLParserDelegate> {
    BOOL modeRefrech;
}

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) IBOutlet UINavigationController *navigationController;
@property (nonatomic, strong) IBOutlet RootViewController *rootViewController;
@property (nonatomic, strong) IBOutlet ParkViewController *parkViewController;

@property (nonatomic, strong) NSString *effectiveDataURL;

@end
