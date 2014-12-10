//
//  EAFLoginViewController.h
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 11/14/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SplunkMint-iOS/SplunkMint-iOS.h>
#import "EAFAudioPlayer.h"

@interface EAFContextPopupViewController : UIViewController

@property (strong, nonatomic) IBOutlet UILabel *contextFL;
@property (strong, nonatomic) IBOutlet UILabel *contextTranslation;
@property (strong, nonatomic) IBOutlet UISegmentedControl *maleFemale;
@property (strong, nonatomic) IBOutlet UILabel *itemFL;

@property  NSString *item;
@property  NSString *fl;
@property  NSString *en;
@property  NSString *mref;
@property  NSString *fref;
@property NSString *url;

@property EAFAudioPlayer *audioPlayer;
@end
