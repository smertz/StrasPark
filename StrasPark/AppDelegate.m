//
//  AppDelegate.m
//  StrasPark
//
//  Created by Stéphan Mertz on 05/04/13.
//  Copyright (c) 2013 Stéphan Mertz. All rights reserved.
//

#import "AppDelegate.h"
#import "RootViewController.h"
#import "ParkViewController.h"
#import "Park.h"
#import "ParseOperation.h"
#import <CFNetwork/CFNetwork.h>


#pragma mark AppDelegate ()

// forward declarations
@interface AppDelegate ()

@property (nonatomic, strong) NSURLConnection *parkFeedConnection;
@property (nonatomic, strong) NSMutableData *parkData;
@property (nonatomic, strong) NSOperationQueue *parseQueue;

- (void)addParksToList:(NSArray *)parks;
- (void)handleError:(NSError *)error;
@end


#pragma mark -
#pragma mark AppDelegate

@implementation AppDelegate

static NSString *strassdataURLString = @"http://parkings.api.strasbourg-data.fr/parkings";
static NSString *configURLString = @"http://jadyn.strasbourg.eu/jadyn/config.xml";
static NSString *dataURLString = @"http://jadyn.strasbourg.eu/jadyn/dynn.xml";
//static NSString *cartoURLString = @"http://carto.strasmap.eu/store/data/module/parking_position.xml";

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Add the navigation view controller to the window.
    [self.window setRootViewController:self.navigationController];
    
    // Use NSURLConnection to asynchronously download the data. This means the main thread will not
    // be blocked - the application will remain responsive to the user.
    //
    // IMPORTANT! The main thread of the application should never be blocked!
    // Also, avoid synchronous network access on any thread.
    //
    
    modeRefrech = NO;
    NSURLRequest *parkURLRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:configURLString]];
    self.parkFeedConnection = [[NSURLConnection alloc] initWithRequest:parkURLRequest delegate:self];
    
    // Test the validity of the connection object. The most likely reason for the connection object
    // to be nil is a malformed URL, which is a programmatic error easily detected during development.
    // If the URL is more dynamic, then you should implement a more flexible validation technique,
    // and be able to both recover from errors and communicate problems to the user in an
    // unobtrusive manner.
    NSAssert(self.parkFeedConnection != nil, @"Failure to create URL connection.");
    
    // Start the status bar network activity indicator. We'll turn it off when the connection
    // finishes or experiences an error.
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    self.parseQueue = [NSOperationQueue new];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(addParks:)
                                                 name:kAddParksNotif
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshParks:)
                                                 name:kRefreshParksNotif
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(parksError:)
                                                 name:kParksErrorNotif
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(selectPark:)
                                                 name:kSelectParkNotif
                                               object:nil];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if ([[self.rootViewController parkList] count] != 0) {
        NSURLRequest *parkURLRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:dataURLString]];
        self.parkFeedConnection = [[NSURLConnection alloc] initWithRequest:parkURLRequest delegate:self];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)refreshControlRequest:(id)sender
{
    NSURLRequest *parkURLRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:dataURLString]];

    modeRefrech = YES;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    self.parkFeedConnection = [[NSURLConnection alloc] initWithRequest:parkURLRequest delegate:self];
}

#pragma mark -
#pragma mark NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    if ((([httpResponse statusCode]/100) == 2)
        && ([[response MIMEType] isEqual:@"text/xml"]
            || [[response MIMEType] isEqual:@"application/xml"]
            || [[response MIMEType] isEqual:@"application/json"])
        ) {
        self.parkData = [NSMutableData data];
    } else {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:
                                  NSLocalizedString(@"HTTP Error",
                                                    @"Error message displayed when receving a connection error.")
                                                             forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:@"HTTP" code:[httpResponse statusCode] userInfo:userInfo];
        [self handleError:error];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.parkData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    if ([error code] == kCFURLErrorNotConnectedToInternet) {
        // if we can identify the error, we can present a more precise message to the user.
        NSDictionary *userInfo =
        [NSDictionary dictionaryWithObject:
         NSLocalizedString(@"No Connection Error",
                           @"Error message displayed when not connected to the Internet.")
                                    forKey:NSLocalizedDescriptionKey];
        NSError *noConnectionError = [NSError errorWithDomain:NSCocoaErrorDomain
                                                         code:kCFURLErrorNotConnectedToInternet
                                                     userInfo:userInfo];
        [self handleError:noConnectionError];
    } else {
        // otherwise handle the error generically
        [self handleError:error];
    }
    self.parkFeedConnection = nil;
    if (modeRefrech) {
        [self.rootViewController.refreshControl endRefreshing];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    self.parkFeedConnection = nil;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    if (self.parkData == nil) return;
    
    // Spawn an NSOperation to parse the park data so that the UI is not blocked while the
    // application parses the XML data.
    //
    // IMPORTANT! - Don't access or affect UIKit objects on secondary threads.
    //
    if ([[[[connection originalRequest] URL] absoluteString] isEqualToString:strassdataURLString]) {
        NSError *jsonParsingError = nil;
        NSArray *parks = [NSJSONSerialization JSONObjectWithData:self.parkData options:0 error:&jsonParsingError];
        NSMutableArray *parkList = [NSMutableArray new];
        
        for (int i=0; i<parks.count; i++) {
            NSDictionary *parkInfos = [parks objectAtIndex:i];
            Park *park = [self.rootViewController findParkForIdent:[parkInfos valueForKey:@"id"]];
            
            if (park == nil) {
                park = [[Park alloc] init];
                park.ident = [parkInfos valueForKey:@"id"];
            }
            
            park.nom = [parkInfos valueForKey:@"name"];
            park.nomCourt = [parkInfos valueForKey:@"short_name"];
            park.capacity = [[parkInfos valueForKey:@"total"] integerValue];
            park.etat = [[parkInfos valueForKey:@"state"] integerValue];
            park.infos = [parkInfos valueForKey:@"user_information"];
            park.latitude = [[parkInfos valueForKey:@"latitude"] doubleValue];
            park.longitude = [[parkInfos valueForKey:@"longitude"] doubleValue];
            if (park.place == 0) {
                park.place = [[parkInfos valueForKey:@"available"] integerValue];
            } else {
                if (park.previousPlace == 0) {
                    park.previousPlace = park.place;
                } else {
                    park.previousPlace = (park.previousPlace + park.place) / 2;
                }
                
                park.place = [[parkInfos valueForKey:@"available"] integerValue];
            }

            [parkList addObject:park];
        }
        
        if (modeRefrech == NO) {
            [self.rootViewController insertParks:parkList];
        } else {
            [self.rootViewController refreshParks:[NSDate date]];
        }
    } else {
        ParseOperation *parseOperation = [[ParseOperation alloc] initWithData:self.parkData andParks:self.rootViewController.parkList];
        [self.parseQueue addOperation:parseOperation];
    }
    
    // parkData will be retained by the NSOperation until it has finished executing,
    // so we no longer need a reference to it in the main thread.
    self.parkData = nil;
    if ([[[[connection originalRequest] URL] absoluteString] isEqualToString:configURLString]) {
        NSURLRequest *parkURLRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:dataURLString]];
        self.parkFeedConnection = [[NSURLConnection alloc] initWithRequest:parkURLRequest delegate:self];
    }
}

// Handle errors in the download by showing an alert to the user. This is a very
// simple way of handling the error, partly because this application does not have any offline
// functionality for the user. Most real applications should handle the error in a less obtrusive
// way and provide offline functionality to the user.
//
- (void)handleError:(NSError *)error {
    NSString *errorMessage = [error localizedDescription];
    UIAlertView *alertView =
    [[UIAlertView alloc] initWithTitle:
     NSLocalizedString(@"Error Title",
                       @"Title for alert displayed when download or parse error occurs.")
                               message:errorMessage
                              delegate:nil
                     cancelButtonTitle:@"OK"
                     otherButtonTitles:nil];
    [alertView show];
}

// Our NSNotification callback from the running NSOperation to add the parks
//
- (void)addParks:(NSNotification *)notif {
    assert([NSThread isMainThread]);
    
    [self addParksToList:[[notif userInfo] valueForKey:kParkResultsKey]];
}

- (void)refreshParks:(NSNotification *)notif {
    assert([NSThread isMainThread]);
    
    [self.rootViewController refreshParks:[[notif userInfo] valueForKey:kRefreshDateKey]];
}

// Our NSNotification callback from the running NSOperation when a parsing error has occurred
//
- (void)parksError:(NSNotification *)notif {
    assert([NSThread isMainThread]);
    
    [self handleError:[[notif userInfo] valueForKey:kParksMsgErrorKey]];
}

// The NSOperation "ParseOperation" calls addParks: via NSNotification, on the main thread
// which in turn calls this method, with batches of parsed objects.
// The batch size is set via the kSizeOfParkBatch constant.
//
- (void)addParksToList:(NSArray *)parks {
    
    // insert the parks into our rootViewController's data source (for KVO purposes)
    [self.rootViewController insertParks:parks];
}

- (void)selectPark:(NSNotification *)notif {
    assert([NSThread isMainThread]);

    Park *park = [[notif userInfo] valueForKey:kSelectedParkKey];
    
    if (park != nil) {
        self.parkViewController.park = park;
        self.parkViewController.title = park.nom;
        [self.navigationController pushViewController:self.parkViewController animated:YES];
    }
}

@end
