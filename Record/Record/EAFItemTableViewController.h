//
//  EAFItemTableViewController.h
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 7/11/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EAFItemTableViewController : UITableViewController

@property NSMutableArray *items;
@property NSMutableArray *englishPhrases;
@property NSMutableArray *paths;

-(void) setChapter:(NSString *)chapter;
@property (strong, nonatomic) NSDictionary *chapterToItems;
@property NSString *language;

@end
