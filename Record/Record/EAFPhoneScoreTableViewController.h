//
//  EAFLanguageTableViewController.h
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 7/16/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <SplunkMint-iOS/SplunkMint-iOS.h>

@interface EAFPhoneScoreTableViewController : UITableViewController<NSURLConnectionDelegate,AVAudioPlayerDelegate, UIGestureRecognizerDelegate>

@property (strong, nonatomic) NSMutableData *responseData;

@property NSString *language;

@property NSString *chapterName;
@property NSString *chapterSelection;
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
