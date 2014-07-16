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

@interface EAFViewController : UIViewController
        <AVAudioRecorderDelegate, AVAudioPlayerDelegate,NSURLConnectionDelegate>

@property (strong, nonatomic) AVAudioRecorder *audioRecorder;
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;

@property (strong, nonatomic) IBOutlet UIButton *recordButton;
@property (strong, nonatomic) IBOutlet UIButton *playButton;
@property (strong, nonatomic) IBOutlet UIButton *stopButton;

- (IBAction)recordAudio:(id)sender;
- (IBAction)playAudio:(id)sender;
- (IBAction)stopAudio:(id)sender;
@property (strong, nonatomic) NSMutableData *responseData;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *recordingFeedback;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *recoFeedback;


@property (strong, nonatomic) IBOutlet UILabel *foreignLang;
@property (strong, nonatomic) IBOutlet UILabel *transliteration;
@property (strong, nonatomic) IBOutlet UILabel *english;
@property (strong, nonatomic) IBOutlet NSString *refAudioPath;
@property (strong, nonatomic) IBOutlet UIButton *playRefAudioButton;
@property int index;
@property NSArray *items;
@property NSArray *paths;


@property (weak, nonatomic) IBOutlet UILabel *scoreDisplay;


@property AVPlayerItem *playerItem;
@property AVPlayer *player;


-(void) setForeignText:(NSString *)foreignLang;
@property (strong, nonatomic) IBOutlet MSAnnotatedGauge *annotatedGauge2;

//- (void)handleSwipeRight:(UIGestureRecognizer*)recognizer;
@property (strong, nonatomic) IBOutlet UISwipeGestureRecognizer *rightSwipe;
@property (strong, nonatomic) IBOutlet UISwipeGestureRecognizer *leftSwipe;
- (IBAction)swipeRightDetected:(UISwipeGestureRecognizer *)sender;
- (IBAction)swipeLeftDetected:(UISwipeGestureRecognizer *)sender;

@end
