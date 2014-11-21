//
//  EAFItemTableViewController.h
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 7/11/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SplunkMint-iOS/SplunkMint-iOS.h>
#import "EAFAudioCache.h"

@interface EAFItemTableViewController : UITableViewController<NSURLConnectionDelegate>

@property NSMutableArray *paths;
@property NSMutableArray *rawPaths;
@property BOOL hasModel;

-(void) setChapter:(NSString *)chapter;
-(void) setChapterTitle:(NSString *)chapter;
@property (strong, nonatomic) NSDictionary *chapterToItems;
@property (strong, nonatomic) NSArray *jsonItems;
//@property NSString *language;

//@property NSMutableData *mp3Audio;
@property int itemIndex;
@property EAFAudioCache *audioCache;

@property (strong, nonatomic) NSMutableData *responseData;
//@property NSArray *jsonContentArray;

@property NSString *language;

//@property NSString *chapterName;
//@property NSString *unitName;
//@property NSString *unitSelection;
//@property NSString *chapterSelection;
@property NSArray *scores;

//@property NSDictionary *exToFL;
@property NSDictionary *exToEnglish;

@property NSDictionary *exToScore;
@property NSDictionary *exToHistory;
@property NSMutableArray *exList;
//@property NSString *currentTitle;

@property long user;

@end
