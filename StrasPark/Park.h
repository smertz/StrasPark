//
//  Park.h
//  StrasPark
//
//  Created by Stéphan Mertz on 05/04/13.
//  Copyright (c) 2013 Stéphan Mertz. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Park : NSObject

@property (nonatomic, strong) NSNumber *ident;
@property (nonatomic, strong) NSString *nom;
@property (nonatomic, strong) NSString *nomCourt;
@property (nonatomic, strong) NSString *infos;
@property (nonatomic, assign) int place;
@property (nonatomic, assign) int previousPlace;
@property (nonatomic, assign) int capacity;
@property (nonatomic, assign) int etat;
@property (nonatomic, assign) double latitude;
@property (nonatomic, assign) double longitude;
@property (nonatomic, assign) double distance;

@end
