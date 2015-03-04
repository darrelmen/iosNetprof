//
//  EAFLanguageTableViewController.h
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 7/16/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
//#import <SplunkMint-iOS/SplunkMint-iOS.h>
#import "EAFAudioPlayer.h"

@interface EAFPhoneScoreTableViewController : UITableViewController<AVAudioPlayerDelegate, UIGestureRecognizerDelegate,AudioPlayerNotification>

@property (strong, nonatomic) NSData *responseData;

@property NSString *language;

@property NSString *chapterName;
@property NSString *chapterSelection;

@property NSString *unitName;
@property NSString *unitSelection;

@property NSDictionary *phoneToWords;
@property NSDictionary *resultToRef;
@property NSDictionary *resultToAnswer;
@property NSDictionary *resultToWords;
@property NSArray *phonesInOrder;
@property AVPlayer *player;
@property NSString *url;

@property long user;
-(void)setCurrentTitle;

@end
