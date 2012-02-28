//
//  AppDelegate.m
//  KaptureCache
//
//  Created by Alexander Smith on 2/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    NSMutableSet *set = [[NSMutableSet alloc] init];
    [set addObject:[NSString stringWithString:@"harrow"]];
    if ([set containsObject:[NSString stringWithString:@"harrow1"]]) {
        NSLog(@"YES");
    } else {
        NSLog(@"No");
    }
    KaptureCacheManager *cacheManager = [[KaptureCacheManager alloc] init];
    NSURL *testURL = [NSURL URLWithString:@"http://www.google.com"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:testURL];
    [cacheManager asyncRequest:request success:^(NSData *data, NSURLResponse *response) {
        NSLog(@"Success");
    } failure:^(NSData *data, NSError *error){
        
    } forceReload:NO];
    [cacheManager asyncRequest:request success:^(NSData *data, NSURLResponse *response) {
        NSLog(@"success 2");
    } failure:^(NSData *data, NSError *error) {
    } forceReload:NO];
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
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
