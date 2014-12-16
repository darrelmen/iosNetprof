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
#import "EAFRecoFlashcardController.h"

@interface EAFItemTableViewController : UITableViewController<NSURLConnectionDelegate>

@property BOOL hasModel;

-(void) setChapter:(NSString *)chapter;
-(void) setChapterTitle:(NSString *)chapter;
@property NSString *language;
@property NSString *unitTitle;
@property NSString *unit;

@property (strong, nonatomic) NSDictionary *chapterToItems;
@property (strong, nonatomic) NSArray *jsonItems;

@property EAFAudioCache *audioCache;

@property (strong, nonatomic) NSMutableData *responseData;


@property NSArray *scores;

@property NSDictionary *exToEnglish;

@property NSDictionary *exToScore;
@property NSDictionary *exToHistory;
@property NSMutableArray *exList;

@property long user;

@property EAFRecoFlashcardController *notifyFlashcardController;

- (void)askServerForJson;

@end
