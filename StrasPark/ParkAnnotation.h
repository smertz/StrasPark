//
//  ParkAnnotation.h
//  StrasPark
//
//  Created by Stéphan Mertz on 07/04/13.
//  Copyright (c) 2013 Stéphan Mertz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface ParkAnnotation : NSObject <MKAnnotation> {
}

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *subtitle;

@end
