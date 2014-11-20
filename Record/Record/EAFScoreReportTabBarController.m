//
//  EAFScoreReportTabBarController.m
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 11/4/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EAFScoreReportTabBarController.h"

@interface EAFScoreReportTabBarController ()

@end

@implementation EAFScoreReportTabBarController


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.delegate = self;

    //[self askServerForJson];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

// this is OK - I just go looking for the method
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
   // NSLog(@"got selection event %@",viewController);
    
    if ( [viewController respondsToSelector:@selector(setCurrentTitle)] )
    {
        [viewController performSelector:@selector(setCurrentTitle)];
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{

    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}


@end