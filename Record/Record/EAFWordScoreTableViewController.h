//
//  EAFLanguageTableViewController.h
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 7/16/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SplunkMint-iOS/SplunkMint-iOS.h>
#import "EAFAudioPlayer.h"
//#import "BButton.h"

@interface EAFWordScoreTableViewController : UITableViewController<NSURLConnectionDelegate,AudioPlayerNotification>

@property (strong, nonatomic) NSMutableData *responseData;

@property NSString *language;

@property NSString *chapterName;
@property NSString *chapterSelection;

@property NSString *unitName;
@property NSString *unitSelection;

@property NSArray *scores;

@property NSDictionary *exToFL;
@property NSDictionary *exToEnglish;

@property NSDictionary *exToScore;
@property NSDictionary *exToHistory;
@property NSMutableArray *exList;
@property NSArray *jsonItems;

@property long user;

-(void)setCurrentTitle;
@property EAFAudioPlayer *audioPlayer;
@property NSString *url;
//@property (strong, nonatomic) IBOutlet UIButton *playingIcon;

@end
