//
//  EAFLanguageTableViewController.h
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 7/16/14.
//  Copyright (c) 2011-2016 Massachusetts Institute of Technology, Lincoln Laboratory
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "EAFAudioPlayer.h"

@interface EAFPhoneScoreTableViewController : UITableViewController<AVAudioPlayerDelegate, UIGestureRecognizerDelegate,AudioPlayerNotification>

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
@property BOOL isRTL;

@property long user;
-(void)setCurrentTitle;

@end
