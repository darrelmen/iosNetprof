//
//  EAFItemTableViewController.h
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 7/11/14.
//  Copyright (c) 2011-2016 Massachusetts Institute of Technology, Lincoln Laboratory
//

#import <UIKit/UIKit.h>
#import "EAFAudioCache.h"
#import "EAFRecoFlashcardController.h"

@interface EAFItemTableViewController : UITableViewController

@property BOOL hasModel;
@property NSString *currentChapter;
@property NSString *chapterTitle;
@property NSString *language;
@property NSString *unitTitle;
@property NSString *unit;
@property long user;

@property (strong, nonatomic) NSDictionary *chapterToItems;
@property (strong, nonatomic) NSArray *jsonItems;

- (void)askServerForJson;
@property NSString *url;
@property BOOL isRTL;

@end
