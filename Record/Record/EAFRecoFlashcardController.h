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
//  EAFRecoFlashcardController
//  Record
//
//  Created by Ferme, Elizabeth - 0553 - MITLL on 4/2/14.
//  Copyright (c) 2011-2016 Massachusetts Institute of Technology, Lincoln Laboratory
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "BButton.h"
#import "EAFAudioPlayer.h"
#import "EAFMoreSelectionPopupViewController.h"
#import "MoreSelection.h"

@interface EAFRecoFlashcardController : UIViewController
        <AVAudioRecorderDelegate, AVAudioPlayerDelegate,UIGestureRecognizerDelegate,AudioPlayerNotification,AVSpeechSynthesizerDelegate,UIPopoverControllerDelegate, PassSelection>

@property (strong, nonatomic) IBOutlet UIView *cardBackground;
@property (strong, nonatomic) IBOutlet UIView *recordButtonContainer;

@property (strong, nonatomic) AVAudioRecorder *audioRecorder;

@property (strong, nonatomic) IBOutlet UIButton *recordButton;

- (IBAction)recordAudio:(id)sender;
- (IBAction)playAudio:(id)sender;
- (IBAction)stopRecordingAudio:(id)sender;
@property (strong, nonatomic) NSData *responseData;

@property (strong, nonatomic) IBOutlet UILabel *foreignLang;
@property (strong, nonatomic) IBOutlet UILabel *english;
@property (strong, nonatomic) IBOutlet UILabel *tl;

@property (strong, nonatomic) IBOutlet UILabel *shuffle;
@property unsigned long index;

@property NSMutableArray *randSequence;
@property NSArray *jsonItems;

@property NSString *url;
//@property BOOL isRTL;

@property NSString *currentChapter;
@property NSString *chapterTitle;
@property NSString *currentUnit;
@property NSString *unitTitle;
@property NSString *language;

@property NSNumber *projid;
@property NSNumber *listid;
@property NSString *listtitle;

// quiz slots
@property NSNumber *numQuizItems;
@property NSNumber *quizMinutes;
@property NSNumber *minScoreToAdvance;
@property BOOL playAudio;

@property (weak, nonatomic) IBOutlet UIView *scoreDisplayContainer;
@property (strong, nonatomic) IBOutlet UIProgressView *scoreProgress;
- (IBAction)showScoresClick:(id)sender;

@property (strong, nonatomic) IBOutlet UILongPressGestureRecognizer *longPressGesture;

- (IBAction)swipeLeftDetected:(UISwipeGestureRecognizer *)sender;
- (IBAction)swipeRightDetected:(UISwipeGestureRecognizer *)sender;
- (IBAction)tapOnForeignDetected:(UITapGestureRecognizer *)sender;
- (IBAction)tapOnEnglishDetected:(id)sender;

- (IBAction)tapOnTlDetected:(id)sender;

@property (strong, nonatomic) IBOutlet UIProgressView *progressThroughItems;
@property (strong, nonatomic) IBOutlet UIProgressView *timerProgress;

@property (weak, nonatomic) IBOutlet UILabel *progressNum;
@property (weak, nonatomic) IBOutlet UILabel *timeRemainingLabel;

@property (strong) NSTimer *repeatingTimer;

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *recoFeedbackImage;
@property (strong, nonatomic) IBOutlet UILabel *correctFeedback;
@property (strong, nonatomic) IBOutlet UIImageView *answerAudioOn;
@property (strong, nonatomic) IBOutlet UIView *metering;
@property (strong, nonatomic) IBOutlet UIView *peak;
@property (strong, nonatomic) IBOutlet UIView *outline;

- (void)respondToSwipe;
- (void)doAutoAdvance;
@property (strong, nonatomic) IBOutlet BButton *contextButton;

@property UITableViewController *itemViewController;
@property (strong, nonatomic) IBOutlet UIPageControl *pageControl;
- (void) viewBecameActive;
- (void) applicationWillResignActive;

@property EAFMoreSelectionPopupViewController *moreSelectionPopupView;
@property MoreSelection *moreSelection;

@property NSString *identityRestoreID;
@property BOOL isAudioOnSelected;
@property BOOL showSentences;

@property (strong, nonatomic) IBOutlet UIToolbar *selectionToolbar;

-(IBAction)showScores:(id)sender;

@end
