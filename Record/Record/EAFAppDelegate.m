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

    NSString *retrieveuuid = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"UUID"];
    if (retrieveuuid == NULL) {
        NSString *UUID = [EAFAppDelegate GetUUID];
        [SSKeychain setPassword:UUID forService:@"mitll.proFeedback.device" account:@"UUID"];
        NSLog(@"made UUID %@",UUID);
        retrieveuuid = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"UUID"];
    }
    
//    NSString *userid = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"userid"];
//    
//
//    BOOL shouldShowAnotherViewControllerAsRoot = userid == nil;
//    
//    if (shouldShowAnotherViewControllerAsRoot) {
//        UIStoryboard *storyboard = self.window.rootViewController.storyboard;
//        UIViewController *rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
//        
//        
//        
//        
//       // MainViewController *vc = [[MainViewController alloc]init];
//        
//        UINavigationController *nc = [[UINavigationController alloc]initWithRootViewController:rootViewController];
//       // self.navigationController=nc;  // I have a property on the app delegate that references the root view controller, which is my navigation controller.
//
//        
//        
//        self.window.rootViewController = nc;
//        [self.window makeKeyAndVisible];
//    }
//    else {
//        
//       NSString * language = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"language"];
//   
//        UIStoryboard *storyboard = self.window.rootViewController.storyboard;
//        EAFChapterTableViewController *rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"ChapterViewController"];
//        [rootViewController setLanguage:language];
//        
//        
//        NSString *toShow = language;
//        if ([toShow isEqualToString:@"CM"]) {
//            toShow = @"Mandarin";
//        }
//        [rootViewController setTitle:toShow];
//        
//        self.window.rootViewController = rootViewController;
//        [self.window makeKeyAndVisible];
//    //    [self.navigationController pushViewController: myController animated:YES];
//        
//
//    }
    
//    
//    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
//    
//    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main.storyboard" bundle:nil];
//    
//    UIViewController *viewController =[storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
//    
//    self.window.rootViewController = viewController;
//    [self.window makeKeyAndVisible];
//    
    
    return YES;
}

//- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions
//{
//    BOOL shouldShowAnotherViewControllerAsRoot = YES;
//    if (shouldShowAnotherViewControllerAsRoot) {
//        UIStoryboard *storyboard = self.window.rootViewController.storyboard;
//        UIViewController *rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
//        self.window.rootViewController = rootViewController;
//        [self.window makeKeyAndVisible];
//    }
//    
//    return YES;
//}

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

+ (NSString *)GetUUID {
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return (__bridge NSString *)string;
}

@end
