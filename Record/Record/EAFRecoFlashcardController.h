//
//  EAFViewController.h
//  Record
//
//  Created by Ferme, Elizabeth - 0553 - MITLL on 4/2/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "MSAnnotatedGauge.h"

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

@property (strong, nonatomic) IBOutlet UILabel *foreignLang;
@property (strong, nonatomic) IBOutlet UILabel *transliteration;
@property (strong, nonatomic) IBOutlet UILabel *english;
@property (strong, nonatomic) IBOutlet NSString *refAudioPath;
@property (strong, nonatomic) IBOutlet NSString *rawRefAudioPath;
@property unsigned long index;
@property NSArray *items;
@property NSArray *englishWords;
@property NSArray *translitWords;
@property NSArray *examples;
@property NSArray *paths;
@property NSArray *rawPaths;
@property NSString *url;
@property BOOL hasModel;
@property (strong, nonatomic) IBOutlet UILongPressGestureRecognizer *longPressGesture;
@property (strong, nonatomic) IBOutlet UILabel *recordInstructions;

@property NSString *language;


@property (weak, nonatomic) IBOutlet UILabel *scoreDisplay;
@property AVPlayer *player;


-(void) setForeignText:(NSString *)foreignLang;
-(void) setEnglishText:(NSString *)english;
-(void) setTranslitText:(NSString *)translit;
-(void) setExampleText:(NSString *)example;
@property (strong, nonatomic) IBOutlet MSAnnotatedGauge *annotatedGauge2;

@property (strong, nonatomic) IBOutlet UISwipeGestureRecognizer *rightSwipe;
@property (strong, nonatomic) IBOutlet UISwipeGestureRecognizer *leftSwipe;
- (IBAction)swipeRightDetected:(UISwipeGestureRecognizer *)sender;
- (IBAction)swipeLeftDetected:(UISwipeGestureRecognizer *)sender;
- (IBAction)tapOnForeignDetected:(UITapGestureRecognizer *)sender;

@property (strong) NSTimer *repeatingTimer;
- (NSDictionary *)userInfo;

- (void)invocationMethod:(NSDate *)date;
@property (strong, nonatomic) IBOutlet UIImageView *recordFeedbackImage;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *recoFeedbackImage;

@property (strong, nonatomic) IBOutlet UISwitch *shuffleSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *audioOnSelector;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *gotTapOnFL;

@end
