//
//  EAFLanguageTableViewController.h
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 7/16/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EAFAudioPlayer.h"

@interface EAFWordScoreTableViewController : UITableViewController<NSURLConnectionDelegate,AudioPlayerNotification>

@property NSString *language;

@property NSString *chapterName;
@property NSString *chapterSelection;

@property NSString *unitName;
@property NSString *unitSelection;

@property NSDictionary *exToFL;
@property NSDictionary *exToEnglish;

@property NSArray *jsonItems;

@property long user;

-(void)setCurrentTitle;
@property NSString *url;

@end
