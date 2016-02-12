//
//  EAFChapterTableViewController.h
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 7/11/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EAFGetSites.h"

@interface EAFChapterTableViewController : UITableViewController<SitesNotification>

@property NSString *chapterName;
@property NSString *currentChapter;

@property NSString *unitTitle;
@property NSString *unit;

@property NSArray *chapters;
@property NSString *language;

@end
