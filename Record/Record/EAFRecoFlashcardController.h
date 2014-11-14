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

@interface EAFRecoFlashcardController : UIViewController
        <AVAudioRecorderDelegate, AVAudioPlayerDelegate,NSURLConnectionDelegate>

@property (strong, nonatomic) IBOutlet UIView *cardBackground;
@property (strong, nonatomic) IBOutlet UIView *recordButtonContainer;

@property (strong, nonatomic) AVAudioRecorder *audioRecorder;
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;

@property (strong, nonatomic) IBOutlet UIButton *playRefAudioButton;
@property (strong, nonatomic) IBOutlet UIButton *recordButton;
@property (strong, nonatomic) IBOutlet UIButton *playButton;

- (IBAction)recordAudio:(id)sender;
- (IBAction)playAudio:(id)sender;
- (IBAction)stopAudio:(id)sender;
@property (strong, nonatomic) NSMutableData *responseData;

//@property (strong, nonatomic) IBOutlet UITextView *foreignLang;
@property (strong, nonatomic) IBOutlet UILabel *foreignLang;
@property (strong, nonatomic) IBOutlet UILabel *english;
@property (strong, nonatomic) IBOutlet UILabel *shuffle;
@property (strong, nonatomic) IBOutlet NSString *refAudioPath;
@property (strong, nonatomic) IBOutlet NSString *rawRefAudioPath;
@property unsigned long index;

@property NSMutableArray *randSequence;
@property NSArray *jsonItems;

@property NSString *url;
@property BOOL hasModel;
@property NSString *currentChapter;
@property NSString *chapterTitle;
@property NSString *language;

//@property (weak, nonatomic) IBOutlet UILabel *scoreDisplay;
@property (weak, nonatomic) IBOutlet UIView *scoreDisplayContainer;
@property (strong, nonatomic) IBOutlet UIProgressView *scoreProgress;
@property AVPlayer *player;
@property (strong, nonatomic) IBOutlet UIView *scoreButtonView;
//@property (strong, nonatomic) IBOutlet BButton *showScores;
- (IBAction)showScoresClick:(id)sender;


@property (strong, nonatomic) IBOutlet UILongPressGestureRecognizer *longPressGesture;
@property (strong, nonatomic) IBOutlet UISwipeGestureRecognizer *leftSwipe;
@property (strong, nonatomic) IBOutlet UISwipeGestureRecognizer *rightSwipe;

- (IBAction)swipeLeftDetected:(UISwipeGestureRecognizer *)sender;
- (IBAction)swipeRightDetected:(UISwipeGestureRecognizer *)sender;
- (IBAction)tapOnForeignDetected:(UITapGestureRecognizer *)sender;

@property (strong) NSTimer *repeatingTimer;
- (NSDictionary *)userInfo;

- (void)invocationMethod:(NSDate *)date;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *recoFeedbackImage;
@property (strong, nonatomic) IBOutlet UIImageView *correctFeedback;

@property (strong, nonatomic) IBOutlet UISwitch *shuffleSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *audioOnSelector;
@property (strong, nonatomic) IBOutlet UISwitch *genderMaleSelector;
@property (strong, nonatomic) IBOutlet UISwitch *speedSelector;
@property (strong, nonatomic) IBOutlet UISegmentedControl *whatToShow;
- (IBAction)whatToShowSelection:(id)sender;
- (IBAction)genderSelection:(id)sender;
- (IBAction)speedSelection:(id)sender;
- (IBAction)audioOnSelection:(id)sender;

//- (float)heightOfLabelForText:(UILabel *)label withText:(NSString *)withText;

@end
