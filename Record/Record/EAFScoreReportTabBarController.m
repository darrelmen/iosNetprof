/*
 * DISTRIBUTION STATEMENT C. Distribution authorized to U.S. Government Agencies
 * and their contractors; 2015. Other request for this document shall be referred
 * to DLIFLC.
 *
 * WARNING: This document may contain technical data whose export is restricted
 * by the Arms Export Control Act (AECA) or the Export Administration Act (EAA).
 * Transfer of this data by any means to a non-US person who is not eligible to
 * obtain export-controlled data is prohibited. By accepting this data, the consignee
 * agrees to honor the requirements of the AECA and EAA. DESTRUCTION NOTICE: For
 * unclassified, limited distribution documents, destroy by any method that will
 * prevent disclosure of the contents or reconstruction of the document.
 *
 * This material is based upon work supported under Air Force Contract No.
 * FA8721-05-C-0002 and/or FA8702-15-D-0001. Any opinions, findings, conclusions
 * or recommendations expressed in this material are those of the author(s) and
 * do not necessarily reflect the views of the U.S. Air Force.
 *
 * © 2015 Massachusetts Institute of Technology.
 *
 * The software/firmware is provided to you on an As-Is basis
 *
 * Delivered to the US Government with Unlimited Rights, as defined in DFARS
 * Part 252.227-7013 or 7014 (Feb 2014). Notwithstanding any copyright notice,
 * U.S. Government rights in this work are defined by DFARS 252.227-7013 or
 * DFARS 252.227-7014 as detailed above. Use of this work other than as specifically
 * authorized by the U.S. Government may violate any copyrights that exist in this work.
 *
 */

//
//  EAFScoreReportTabBarController.m
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 11/4/14.
//  Copyright (c) 2011-2016 Massachusetts Institute of Technology, Lincoln Laboratory
//

#import <Foundation/Foundation.h>

#import "EAFScoreReportTabBarController.h"
#import "EAFEventPoster.h"
#import "EAFGetSites.h"

@interface EAFScoreReportTabBarController ()

@property EAFGetSites *siteGetter;

@end


@implementation EAFScoreReportTabBarController


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.delegate = self;
    
//    _siteGetter = [EAFGetSites new];
//    [_siteGetter getSites];

    //[self askServerForJson];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

// this is OK - I just go looking for the method
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
   // NSLog(@"tabBarController got selection event %@",viewController);
    
//    EAFEventPoster *poster = [[EAFEventPoster alloc] initWithURL:_url];
//    [poster postEvent:NSStringFromClass([viewController class]) exid:@"n/a" widget:@"Choice" widgetType:@"Button"];
    
    if ( [viewController respondsToSelector:@selector(setCurrentTitle)] )
    {
        [viewController performSelector:@selector(setCurrentTitle)];
    }
}

//- (EAFEventPoster*)getPoster {
//    return [[EAFEventPoster alloc] initWithURL:_url projid:[_siteGetter.nameToProjectID objectForKey:_language]];
//}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
@end
