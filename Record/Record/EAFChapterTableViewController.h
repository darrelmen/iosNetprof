//
//  EAFChapterTableViewController.h
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 7/11/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EAFChapterTableViewController : UITableViewController<NSURLConnectionDelegate>

@property NSString *chapterName;
@property NSString *currentChapter;
@property NSArray *chapters;
@property NSArray *jsonContentArray;
@property (strong, nonatomic) NSMutableData *responseData;
@property NSString *language;
@property BOOL hasModel;

@end
