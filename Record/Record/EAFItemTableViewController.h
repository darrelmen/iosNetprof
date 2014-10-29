//
//  EAFItemTableViewController.h
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 7/11/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EAFItemTableViewController : UITableViewController<NSURLConnectionDelegate>

@property NSMutableArray *paths;
@property NSMutableArray *rawPaths;
@property BOOL hasModel;

-(void) setChapter:(NSString *)chapter;
-(void) setChapterTitle:(NSString *)chapter;
@property (strong, nonatomic) NSDictionary *chapterToItems;
@property (strong, nonatomic) NSArray *jsonItems;
@property NSString *language;

@property NSMutableData *mp3Audio;
@property int itemIndex;

@end
