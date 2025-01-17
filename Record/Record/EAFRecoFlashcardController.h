/*
 * DISTRIBUTION STATEMENT C. Distribution authorized to U.S. Government Agencies
 * and their contractors; 2015. Other request for this document shall be referred
 * to DLIFLC.
 *
 * WARNING: This document may contain technical data whose export is restricted
 * by the Arms Export Control Act (AECA) or the Export Administration Act (EAA).
 * Transfer of this data by any means to a non-US person who is not eligible to
 * obtain export-controlled data is prohibited. By accepting this data, the consignee
 * agrees to honor the requirements of the AECA and EAA. DESTRUCTION NOTICE: For
 * unclassified, limited distribution documents, destroy by any method that will
 * prevent disclosure of the contents or reconstruction of the document.
 *
 * This material is based upon work supported under Air Force Contract No.
 * FA8721-05-C-0002 and/or FA8702-15-D-0001. Any opinions, findings, conclusions
 * or recommendations expressed in this material are those of the author(s) and
 * do not necessarily reflect the views of the U.S. Air Force.
 *
 * © 2015 Massachusetts Institute of Technology.
 *
 * The software/firmware is provided to you on an As-Is basis
 *
 * Delivered to the US Government with Unlimited Rights, as defined in DFARS
 * Part 252.227-7013 or 7014 (Feb 2014). Notwithstanding any copyright notice,
 * U.S. Government rights in this work are defined by DFARS 252.227-7013 or
 * DFARS 252.227-7014 as detailed above. Use of this work other than as specifically
 * authorized by the U.S. Government may violate any copyrights that exist in this work.
 *
 */

//
//  EAFViewController.h
//  Record
//
//  Created by Ferme, Elizabeth - 0553 - MITLL on 4/2/14.
//  Copyright (c) 2011-2016 Massachusetts Institute of Technology, Lincoln Laboratory
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "BButton.h"
#import "EAFAudioPlayer.h"

@interface EAFRecoFlashcardController : UIViewController
        <AVAudioRecorderDelegate, AVAudioPlayerDelegate,UIGestureRecognizerDelegate,AudioPlayerNotification,AVSpeechSynthesizerDelegate,UIPopoverControllerDelegate>

@property (strong, nonatomic) IBOutlet UIView *cardBackground;
@property (strong, nonatomic) IBOutlet UIView *recordButtonContainer;

@property (strong, nonatomic) AVAudioRecorder *audioRecorder;

//@property (strong, nonatomic) IBOutlet UIButton *playRefAudioButton;
@property (strong, nonatomic) IBOutlet UIButton *recordButton;

- (IBAction)recordAudio:(id)sender;
- (IBAction)playAudio:(id)sender;
- (IBAction)stopAudio:(id)sender;
@property (strong, nonatomic) NSData *responseData;

@property (strong, nonatomic) IBOutlet UILabel *foreignLang;
@property (strong, nonatomic) IBOutlet UILabel *english;
@property (strong, nonatomic) IBOutlet UILabel *shuffle;
@property unsigned long index;

@property NSMutableArray *randSequence;
@property NSArray *jsonItems;

@property NSString *url;
@property BOOL isRTL;
@property BOOL hasModel;
@property NSString *currentChapter;
@property NSString *chapterTitle;
@property NSString *currentUnit;
@property NSString *unitTitle;
@property NSString *language;

@property (weak, nonatomic) IBOutlet UIView *scoreDisplayContainer;
@property (strong, nonatomic) IBOutlet UIProgressView *scoreProgress;
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

@property (strong, nonatomic) IBOutlet BButton *audioOnButton;
@property (strong, nonatomic) IBOutlet BButton *shuffleButton;
@property (strong, nonatomic) IBOutlet BButton *autoPlayButton;

@property (strong, nonatomic) IBOutlet UIButton *speedButton;
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
- (void) applicationWillResignActive;

@end
