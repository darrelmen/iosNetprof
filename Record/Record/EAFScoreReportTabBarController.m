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
    NSLog(@"Got score report viewDidLoad!!! ");
    
    

    //[self askServerForJson];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    
    NSLog(@"Got score report segue!!! ");

    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    //    EAFChapterTableViewController *chapterController = [segue destinationViewController];
    
    //  NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    //  NSString *tappedItem = [languages objectAtIndex:indexPath.row];
    
    //  [chapterController setLanguage:tappedItem];
    //  if ([tappedItem isEqualToString:@"CM"]) {
    //      tappedItem = @"Mandarin";
    //  }
    // [chapterController setTitle:tappedItem];
}


@end