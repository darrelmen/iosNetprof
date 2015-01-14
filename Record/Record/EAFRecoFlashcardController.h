//
//  EAFViewController.h
//  Record
//
//  Created by Ferme, Elizabeth - 0553 - MITLL on 4/2/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "BButton.h"
#import <SplunkMint-iOS/SplunkMint-iOS.h>
#import "EAFAudioPlayer.h"

@interface EAFRecoFlashcardController : UIViewController
        <AVAudioRecorderDelegate, AVAudioPlayerDelegate,NSURLConnectionDelegate,UIGestureRecognizerDelegate,AudioPlayerNotification,AVSpeechSynthesizerDelegate>

@property (strong, nonatomic) IBOutlet UIView *cardBackground;
@property (strong, nonatomic) IBOutlet UIView *recordButtonContainer;

@property (strong, nonatomic) AVAudioRecorder *audioRecorder;

@property (strong, nonatomic) IBOutlet UIButton *playRefAudioButton;
@property (strong, nonatomic) IBOutlet UIButton *recordButton;

- (IBAction)recordAudio:(id)sender;
- (IBAction)playAudio:(id)sender;
- (IBAction)stopAudio:(id)sender;
@property (strong, nonatomic) NSMutableData *responseData;

@property (strong, nonatomic) IBOutlet UILabel *foreignLang;
@property (strong, nonatomic) IBOutlet UILabel *english;
@property (strong, nonatomic) IBOutlet UILabel *shuffle;
@property unsigned long index;

@property NSMutableArray *randSequence;
@property NSArray *jsonItems;

@property NSString *url;
@property BOOL hasModel;
@property NSString *currentChapter;
@property NSString *chapterTitle;
@property NSString *currentUnit;
@property NSString *unitTitle;
@property NSString *language;

@property (weak, nonatomic) IBOutlet UIView *scoreDisplayContainer;
@property (strong, nonatomic) IBOutlet UIProgressView *scoreProgress;
@property AVPlayer *player;
- (IBAction)showScoresClick:(id)sender;

@property (strong, nonatomic) IBOutlet UILongPressGestureRecognizer *longPressGesture;

- (IBAction)swipeLeftDetected:(UISwipeGestureRecognizer *)sender;
- (IBAction)swipeRightDetected:(UISwipeGestureRecognizer *)sender;
- (IBAction)tapOnForeignDetected:(UITapGestureRecognizer *)sender;
@property (strong, nonatomic) IBOutlet UIProgressView *progressThroughItems;

@property (strong) NSTimer *repeatingTimer;

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *recoFeedbackImage;
@property (strong, nonatomic) IBOutlet UIImageView *correctFeedback;
@property (strong, nonatomic) IBOutlet UISegmentedControl *genderMaleSelector;

@property (strong, nonatomic) IBOutlet UISegmentedControl *audioOnSelector;
@property (strong, nonatomic) IBOutlet UISwitch *shuffleSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *autoPlaySwitch;


@property (strong, nonatomic) IBOutlet UISwitch *speedSelector;
@property (strong, nonatomic) IBOutlet UISegmentedControl *whatToShow;
- (IBAction)whatToShowSelection:(id)sender;

- (IBAction)speedSelection:(id)sender;
- (IBAction)audioOnSelection:(id)sender;
- (void)respondToSwipe;
- (void)doAutoAdvance;
@property (strong, nonatomic) IBOutlet BButton *contextButton;

@property UITableViewController *itemViewController;
@property (strong, nonatomic) IBOutlet UIPageControl *pageControl;
- (void) viewBecameActive;
@end
