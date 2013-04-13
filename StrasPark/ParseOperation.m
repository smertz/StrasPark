//
//  ParseOperation.m
//  StrasPark
//
//  Created by Stéphan Mertz on 05/04/13.
//  Copyright (c) 2013 Stéphan Mertz. All rights reserved.
//

#import "ParseOperation.h"
#import "Park.h"

// NSNotification name for sending Park data back to the app delegate
NSString *kAddParksNotif = @"AddParksNotif";

// NSNotification name for sending Park data back to the app delegate
NSString *kRefreshParksNotif = @"RefreshParksNotif";

// NSNotification userInfo key for obtaining the Park data
NSString *kParkResultsKey = @"ParkResultsKey";
NSString *kRefreshDateKey = @"RefreshDateKey";

// NSNotification name for reporting errors
NSString *kParksErrorNotif = @"ParkErrorNotif";

// NSNotification userInfo key for obtaining the error message
NSString *kParksMsgErrorKey = @"ParksMsgErrorKey";


@interface ParseOperation () <NSXMLParserDelegate>
    @property (nonatomic, strong) Park *currentParkObject;
    @property (nonatomic, strong) NSMutableArray *currentParseBatch;
    @property (nonatomic, strong) NSMutableString *currentParsedCharacterData;
    @property (nonatomic, strong) NSDate *refreshDate;
@end

@implementation ParseOperation

- (id)initWithData:(NSData *)parseData andParks:(NSArray *)parks
{
    if (self = [super init]) {
        self.parkData = [parseData copy];
        self.parks = parks;
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale:[NSLocale currentLocale]];
        [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];

    	NSString *path = [[NSBundle mainBundle] pathForResource:@"carto" ofType:@"plist"];
        
        self.cartoDict = [[NSDictionary alloc] initWithContentsOfFile:path];
}
    return self;
}

- (void)addParksToList:(NSArray *)parks {
    assert([NSThread isMainThread]);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kAddParksNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:parks
                                                                                           forKey:kParkResultsKey]];
}

- (void)refreshParks:(NSDate *)refreshDate {
    assert([NSThread isMainThread]);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kRefreshParksNotif
                                                        object:self
                                                      userInfo:refreshDate != nil ? [NSDictionary dictionaryWithObject:refreshDate forKey:kRefreshDateKey] : nil];
}

- (Park *)findParkForIdent:(NSNumber *)ident {
    Park *park = nil;
    
    for (int i=0; i<[self.parks count] && park == nil; i++) {
        Park *aPark = [self.parks objectAtIndex:i];
        
        if ([aPark.ident isEqual:ident]) {
            park = aPark;
        }
    }
    
    return park;
}

// the main function for this NSOperation, to start the parsing
- (void)main {
    self.currentParseBatch = [NSMutableArray array];
    self.currentParsedCharacterData = [NSMutableString string];
    
    // It's also possible to have NSXMLParser download the data, by passing it a URL, but this is
    // not desirable because it gives less control over the network, particularly in responding to
    // connection errors.
    //
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:self.parkData];
    [parser setDelegate:self];
    [parser parse];
    
    // depending on the total number of Parks parsed, the last batch might not have been a
    // "full" batch, and thus not been part of the regular batch transfer. So, we check the count of
    // the array and, if necessary, send it to the main thread.
    //
    if ([self.currentParseBatch count] > 0 && [self.parks count] == 0) {
        [self performSelectorOnMainThread:@selector(addParksToList:)
                               withObject:self.currentParseBatch
                            waitUntilDone:NO];
    } else {
        [self performSelectorOnMainThread:@selector(refreshParks:)
                               withObject:self.refreshDate
                            waitUntilDone:NO];
    }
    
    self.currentParseBatch = nil;
    self.currentParkObject = nil;
    self.currentParsedCharacterData = nil;
    //self.refreshDate = nil;
}


#pragma mark -
#pragma mark Parser constants

// Limit the number of parsed Parks to 50
// (a given day may have more than 50 Parks around the world, so we only take the first 50)
//
static const NSUInteger kMaximumNumberOfParksToParse = 50;

// When an Park object has been fully constructed, it must be passed to the main thread and
// the table view in RootViewController must be reloaded to display it. It is not efficient to do
// this for every Park object - the overhead in communicating between the threads and reloading
// the table exceed the benefit to the user. Instead, we pass the objects in batches, sized by the
// constant below. In your application, the optimal batch size will vary
// depending on the amount of data in the object and other factors, as appropriate.
//
static NSUInteger const kSizeOfParkBatch = 10;

// Reduce potential parsing errors by using string constants declared in a single place.
static NSString * const kDataElementName = @"donnees";
static NSString * const kPRKElementName = @"PRK";
static NSString * const kPElementName = @"p";


#pragma mark -
#pragma mark NSXMLParser delegate methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
    attributes:(NSDictionary *)attributeDict {
    // If the number of parsed Parks is greater than
    // kMaximumNumberOfParksToParse, abort the parse.
    //
    if (parsedParksCounter >= kMaximumNumberOfParksToParse) {
        // Use the flag didAbortParsing to distinguish between this deliberate stop
        // and other parser errors.
        //
        didAbortParsing = YES;
        [parser abortParsing];
    }
    
    if ([elementName isEqualToString:kDataElementName]) {
        NSString *dateStr = [attributeDict valueForKey:@"ts"];
        
        if (dateStr != nil && [dateStr rangeOfString:@"."].length != 0) {
            dateStr = [dateStr substringToIndex:[dateStr rangeOfString:@"."].location];
            self.refreshDate = [dateFormatter dateFromString:dateStr];
        }
    } else if ([elementName isEqualToString:kPRKElementName] || [elementName isEqualToString:kPElementName]) {
        NSNumber *ident = [attributeDict valueForKey:@"Ident"];
        
        if ([elementName isEqualToString:kPElementName]) {
            ident = [attributeDict valueForKey:@"id"];
        }
        
        Park *park = [self findParkForIdent:ident];
        
        if (park == nil && [elementName isEqualToString:kPRKElementName] && [attributeDict valueForKey:@"Nom"] != nil) {
            park = [[Park alloc] init];
            park.ident = ident;
            park.nom = [attributeDict valueForKey:@"Nom"];
            park.nomCourt = [attributeDict valueForKey:@"NomCourt"];
            park.distance = -1;
            park.previousPlace = -1;

            NSDictionary *coords = [self.cartoDict objectForKey:ident];
            NSScanner *scanner = [NSScanner scannerWithString:[coords valueForKey:@"latitude"]];
            double latitude, longitude;
            
            [scanner scanDouble:&latitude];
            scanner = [NSScanner scannerWithString:[coords valueForKey:@"longitude"]];
            [scanner scanDouble:&longitude];
            park.latitude = latitude;
            park.longitude = longitude;
            
        } else if (park != nil && [elementName isEqualToString:kPElementName]) {
            NSScanner *scanner = [NSScanner scannerWithString:[attributeDict valueForKey:@"x"]];
            double latitude, longitude;
            
            [scanner scanDouble:&longitude];
            scanner = [NSScanner scannerWithString:[attributeDict valueForKey:@"y"]];
            [scanner scanDouble:&latitude];
            park.longitude = longitude;
            park.latitude = latitude;
        } else if (park != nil) {
            if (park.place == 0) {
                park.place = [[attributeDict valueForKey:@"Libre"] integerValue];
            } else {
                if (park.previousPlace == -1) {
                    park.previousPlace = park.place;
                } else {
                    park.previousPlace = (park.previousPlace + park.place) / 2;
                }
                
                park.place = [[attributeDict valueForKey:@"Libre"] integerValue];
            }
            
            park.capacity = [[attributeDict valueForKey:@"Total"] integerValue];
            park.etat = [[attributeDict valueForKey:@"Etat"] integerValue];
            park.infos = [attributeDict valueForKey:@"InfoUsager"];
        }
        
        self.currentParkObject = park;
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName {
    if ([elementName isEqualToString:kPRKElementName]) {
        if ([self.parks count] == 0 && self.currentParkObject != nil) {
            [self.currentParseBatch addObject:self.currentParkObject];
            parsedParksCounter++;
            if ([self.currentParseBatch count] >= kMaximumNumberOfParksToParse) {
                [self performSelectorOnMainThread:@selector(addParksToList:)
                                       withObject:self.currentParseBatch
                                    waitUntilDone:NO];
                self.currentParseBatch = [NSMutableArray array];
            }
        }
    }
    
    // Stop accumulating parsed character data. We won't start again until specific elements begin.
    accumulatingParsedCharacterData = NO;
}

// This method is called by the parser when it find parsed character data ("PCDATA") in an element.
// The parser is not guaranteed to deliver all of the parsed character data for an element in a single
// invocation, so it is necessary to accumulate character data until the end of the element is reached.
//
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (accumulatingParsedCharacterData) {
        // If the current element is one whose content we care about, append 'string'
        // to the property that holds the content of the current element.
        //
        [self.currentParsedCharacterData appendString:string];
    }
}

// an error occurred while parsing the Park data,
// post the error as an NSNotification to our app delegate.
//
- (void)handleParksError:(NSError *)parseError {
    [[NSNotificationCenter defaultCenter] postNotificationName:kParksErrorNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:parseError
                                                                                           forKey:kParksMsgErrorKey]];
}

// an error occurred while parsing the Park data,
// pass the error to the main thread for handling.
// (note: don't report an error if we aborted the parse due to a max limit of Parks)
//
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    if ([parseError code] != NSXMLParserDelegateAbortedParseError && !didAbortParsing)
    {
        [self performSelectorOnMainThread:@selector(handleParksError:)
                               withObject:parseError
                            waitUntilDone:NO];
    }
}

@end
