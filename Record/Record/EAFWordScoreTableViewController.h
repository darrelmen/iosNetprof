//
//  EAFLanguageTableViewController.h
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 7/16/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SplunkMint-iOS/SplunkMint-iOS.h>

@interface EAFWordScoreTableViewController : UITableViewController<NSURLConnectionDelegate>

@property (strong, nonatomic) NSMutableData *responseData;
@property NSArray *jsonContentArray;

@property NSString *language;

@property NSString *chapterName;
//@property NSString *unitName;
//@property NSString *unitSelection;
@property NSString *chapterSelection;
@property NSArray *scores;

@property NSDictionary *exToFL;
@property NSDictionary *exToEnglish;

@property NSDictionary *exToScore;
@property NSDictionary *exToHistory;
@property NSMutableArray *exList;

@property long user;

@end
