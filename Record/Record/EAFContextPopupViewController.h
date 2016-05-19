//
//  EAFLoginViewController.h
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 11/14/14.
//  Copyright (c) 2011-2016 Massachusetts Institute of Technology, Lincoln Laboratory
//  @author <a href="mailto:gordon.vidaver@ll.mit.edu">Gordon Vidaver</a>
//

#import <UIKit/UIKit.h>
//#import <SplunkMint-iOS/SplunkMint-iOS.h>
#import "EAFAudioPlayer.h"
#import "BButton.h"

@interface EAFContextPopupViewController : UIViewController<AudioPlayerNotification>

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
@property NSString *language;

@end
