//
//  ParseOperation.h
//  StrasPark
//
//  Created by Stéphan Mertz on 05/04/13.
//  Copyright (c) 2013 Stéphan Mertz. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *kAddParksNotif;
extern NSString *kRefreshParksNotif;
extern NSString *kParkResultsKey;
extern NSString *kRefreshDateKey;

extern NSString *kParksErrorNotif;
extern NSString *kParksMsgErrorKey;

@class Park;

@interface ParseOperation : NSOperation {
@private
    BOOL accumulatingParsedCharacterData;
    BOOL didAbortParsing;
    NSUInteger parsedParksCounter;
    NSDateFormatter *dateFormatter;
}

@property (nonatomic, strong) NSData *parkData;
@property (nonatomic, strong) NSArray *parks;
@property (nonatomic, strong) NSDictionary *cartoDict;

- (id)initWithData:(NSData *)parseData andParks:(NSArray *)parks;

@end
