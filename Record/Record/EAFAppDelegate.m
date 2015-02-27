//
//  EAFAppDelegate.m
//  Record
//
//  Created by Ferme, Elizabeth - 0553 - MITLL on 4/2/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import "EAFAppDelegate.h"
#import "SSKeychain.h"
#import "EAFChapterTableViewController.h"

@implementation EAFAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    // [SSKeychain deletePasswordForService:@"mitll.proFeedback.device" account:@"userid"];
  //  [[Mint sharedInstance] initAndStartSession:@"1cad0755"];
  //  [[Mint sharedInstance] addURLToBlackList:@"np.ll.mit.edu"];
    
    NSString *retrieveuuid = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"UUID"];
    if (retrieveuuid == NULL) {
        NSString *UUID = [EAFAppDelegate GetUUID];
        [SSKeychain setPassword:UUID forService:@"mitll.proFeedback.device" account:@"UUID"];
        //NSLog(@"made UUID %@",UUID);
       // retrieveuuid = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"UUID"];
    }
    
  //  NSLog(@"version - %@",[self appNameAndVersionNumberDisplayString]);
    
   // NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    //[[NSUserDefaults standardUserDefaults] setObject:[self appNameAndVersionNumberDisplayString] forKey:@"version_preference"];
    
    return YES;
}

//- (NSString *)appNameAndVersionNumberDisplayString {
//    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
//    NSString *appDisplayName = [infoDictionary objectForKey:@"CFBundleDisplayName"];
//    NSString *majorVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
//    NSString *minorVersion = [infoDictionary objectForKey:@"CFBundleVersion"];
//    
//    return [NSString stringWithFormat:@"%@, Version %@ (%@)",
//            appDisplayName, majorVersion, minorVersion];
//}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    NSLog(@"got applicationWillResignActive --->");
    [_recoController applicationWillResignActive];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
   // [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:NULL];

    NSLog(@"got applicationDidEnterBackground --->");
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    NSLog(@"got applicationWillEnterForeground --->");
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    NSLog(@"got applicationDidBecomeActive --->");
    [_recoController viewBecameActive];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    NSLog(@"got applicationWillTerminate --->");
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

+ (NSString *)GetUUID {
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return (__bridge_transfer NSString *)string;
}

@end
