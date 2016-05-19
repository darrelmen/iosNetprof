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
//  EAFViewController.m
//  Record
//
//  Created by Ferme, Elizabeth - 0553 - MITLL on 4/2/14.
//  Copyright (c) 2011-2016 Massachusetts Institute of Technology, Lincoln Laboratory
//

#import "EAFRecoFlashcardController.h"
#import "EAFScoreReportTabBarController.h"
#import "EAFWordScoreTableViewController.h"
#import "EAFPhoneScoreTableViewController.h"
#import "math.h"
#import <AudioToolbox/AudioServices.h>
#import "SSKeychain.h"
#import "UIFont+FontAwesome.h"
#import "NSString+FontAwesome.h"
#import "BButton.h"
#import "EAFItemTableViewController.h"
#import "EAFContextPopupViewController.h"
#import "EAFEventPoster.h"
#import "MZFormSheetController.h"
#import "EAFAudioPlayer.h"
#import "EAFAppDelegate.h"
#import "EAFPopoverViewController.h"
#import <sys/utsname.h> // import it in your header or implementation file.

@implementation UIProgressView (customView)
- (CGSize)sizeThatFits:(CGSize)size {
    CGSize newSize = CGSizeMake(self.frame.size.width, 9);
    return newSize;
}
@end

@interface EAFRecoFlashcardController ()

@property NSString *flashcardPlayerStatusContext;

@property CFAbsoluteTime then2 ;
@property CFAbsoluteTime now;
@property int reqid;
@property NSMutableArray *audioRefs;
@property EAFAudioPlayer *myAudioPlayer;
@property (strong, nonatomic) AVPlayer *altPlayer;
@property float lastUpdate;
@property (nonatomic, strong) AVSpeechSynthesizer *synthesizer;
@property NSTimer *autoAdvanceTimer;
@property NSTimeInterval autoAdvanceInterval;
@property double gestureStart;
@property double gestureEnd;

@property CFAbsoluteTime startPost ;
@property UIBackgroundTaskIdentifier backgroundUpdateTask;
@property BOOL showPhonesLTRAlways;  // constant
@property UIPopoverController *popover;
@property EAFAudioCache *audioCache;
@property NSMutableDictionary *exToScore;
@property NSArray *wordTranscript;
@property NSArray *phoneTranscript;
@property NSMutableArray *wordLabels;
@property NSMutableArray *phoneLabels;
@property BOOL preventPlayAudio;

- (void)postAudio;

@end

@implementation EAFRecoFlashcardController

- (void)checkAndShowIntro
{
    NSString *userid = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"userid"];
    NSString *showedID = [NSString stringWithFormat:@"showedIntro_%@",userid];
    NSString *showedIntro = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:showedID];
    
    if (showedIntro == nil) {
        UIAlertView *info = [[UIAlertView alloc] initWithTitle:@"Swipe left/right/up/down to advance, tap to flip.\n\nPress and hold to record.\n\nTouch a word to hear audio or yourself.\n\nTouch Scores to see answers and sounds to work on." message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [info show];
        
        [SSKeychain setPassword:@"Yes"
                     forService:@"mitll.proFeedback.device" account:showedID];
        _preventPlayAudio = true;
    }
    else {
        //        [self checkAndShowPopover];
    }
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //    NSLog(@"RecoFlashcard - viewWillAppear --->");
    [self performSelectorInBackground:@selector(cacheAudio:) withObject:_jsonItems];
    
    [self respondToSwipe];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    [self playRefAudioIfAvailable];
    //  [self checkAndShowPopover];
};

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    //NSLog(@"popoverControllerDidDismissPopover --->");
}

- (void)configureWhatToShow
{
    [_whatToShow setSelectedSegmentIndex:2];
    
    [_whatToShow setTitle:_language forSegmentAtIndex:1];
    
    if ([_language isEqualToString:@"English"]) {
        [_whatToShow setTitle:@"Def." forSegmentAtIndex:0];
    }
    else if ([_language isEqualToString:@"Sudanese"]) {
        [_whatToShow setTitle:@"Sudan" forSegmentAtIndex:1];
    }
    else if ([_language isEqualToString:@"Pashto1"] || [_language isEqualToString:@"Pashto2"] || [_language isEqualToString:@"Pashto3"]) {
        [_whatToShow setTitle:@"Pashto" forSegmentAtIndex:1];
    }
    
    if (![self isiPad] && ![_language isEqualToString:@"English"]) {
        [_whatToShow setTitle:@"Eng" forSegmentAtIndex:0];
    }
}

- (void)viewDidLoad
{
    //    NSLog(@"RecoFlashcardController.viewDidLoad --->");
    [super viewDidLoad];
    _audioCache = [[EAFAudioCache alloc] init];
    
    [self performSelectorInBackground:@selector(cacheAudio:) withObject:_jsonItems];
    
    _showPhonesLTRAlways = true;
    _exToScore = [[NSMutableDictionary alloc] init];
    //   _exToResponse = [[NSMutableDictionary alloc] init];
    
    // Turn on remote control event delivery
    EAFAppDelegate *myDelegate = [UIApplication sharedApplication].delegate;
    
    myDelegate.recoController = self;
    
    // TODO: make this a parameter?
    _autoAdvanceInterval = 0.5;
    _reqid = 1;
    if (!self.synthesizer) {
        self.synthesizer = [[AVSpeechSynthesizer alloc] init];
        _synthesizer.delegate = self;
    }
    
    _myAudioPlayer = [[EAFAudioPlayer alloc] init];
    _myAudioPlayer.url = _url;
    _myAudioPlayer.language = _language;
    _myAudioPlayer.delegate = self;
    
    [[self view] sendSubviewToBack:_cardBackground];
    
    _cardBackground.layer.cornerRadius = 15.f;
    _cardBackground.layer.borderColor = [UIColor grayColor].CGColor;
    _cardBackground.layer.borderWidth = 2.0f;
    
    _recordButtonContainer.layer.cornerRadius = 15.f;
    _recordButtonContainer.layer.borderWidth = 2.0f;
    _recordButtonContainer.layer.borderColor = [UIColor colorWithRed:0 green:0.5 blue:1 alpha:1].CGColor;
    
    // Set the audio file
    NSArray *pathComponents = [NSArray arrayWithObjects:
                               [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                               @"MyAudioMemo.wav",
                               nil];
    NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];
    NSError *error = nil;
    
    NSError *setOverrideError;
    NSError *setCategoryError;
    
    // Setup audio session
    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&setCategoryError];
    
    if(setCategoryError){
        NSLog(@"%@", [setCategoryError description]);
    }
    
    _longPressGesture.minimumPressDuration = 0.05;
    
    // make sure volume is high on iPhones
    
    [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&setOverrideError];
    
    if(setOverrideError){
        NSLog(@"%@", [setOverrideError description]);
    }
    
    // Define the recorder setting
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:16000.0] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt: 1] forKey:AVNumberOfChannelsKey];
    
    // Initiate and prepare the recorder
    _audioRecorder = [[AVAudioRecorder alloc] initWithURL:outputFileURL settings:recordSetting error:&error];
    
    if (error)
    {
        NSLog(@"error: %@", [error localizedDescription]);
    }
    
    _audioRecorder.delegate = self;
    _audioRecorder.meteringEnabled = YES;
    [_audioRecorder prepareToRecord];
    
    [self checkAvailableMics];
    [self configureTextFields];
    
    [_scoreProgress setTintColor:[UIColor blueColor]];
    [_scoreProgress setTrackTintColor:[UIColor whiteColor]];
    [_scoreProgress setProgressTintColor:[UIColor greenColor]];
    
    _scoreProgress.layer.cornerRadius = 3.f;
    _scoreProgress.layer.borderWidth = 1.0f;
    _scoreProgress.layer.borderColor = [UIColor grayColor].CGColor;
    [_correctFeedback setHidden:true];
    
    if (!_hasModel) {
        NSLog(@"----> EAFRecoFlashcardController : No model for %@",_language);
        _recordButtonContainer.hidden = true;
    }
    else {
        _recordButtonContainer.hidden = false;
    }
    
    _scoreProgress.hidden = true;
    
    [self configureWhatToShow];
    
    _pageControl.transform = CGAffineTransformMakeRotation(M_PI_2);
    
    [_contextButton initWithFrame:CGRectMake(0.0f, 0.0f, 40.0f, 40.0f)
                            color:[UIColor whiteColor]
                            style:BButtonStyleBootstrapV3
                             icon:FAQuoteLeft
                         fontSize:20.0f];
    
    if ([self isiPad]) {
        _contextButton.titleLabel.text = @"sentence";
        [_contextButton addAwesomeIcon:FAQuoteLeft beforeTitle:true];
    }
    [_shuffleButton initWithFrame:CGRectMake(0.0f, 0.0f, 40.0f, 40.0f)
     //        color:[UIColor colorWithWhite:1.0f alpha:0.0f]
                            color:[UIColor whiteColor]
                            style:BButtonStyleBootstrapV3
                             icon:FARandom
                         fontSize:20.0f];
    
    [_audioOnButton initWithFrame:CGRectMake(0.0f, 0.0f, 40.0f, 40.0f)
     //        color:[UIColor colorWithWhite:1.0f alpha:0.0f]
                            color:[UIColor whiteColor]
                            style:BButtonStyleBootstrapV3
                             icon:FAVolumeUp
                         fontSize:20.0f];
    
    [_autoPlayButton initWithFrame:CGRectMake(0.0f, 0.0f, 40.0f, 40.0f)
     //        color:[UIColor colorWithWhite:1.0f alpha:0.0f]
                             color:[UIColor whiteColor]
                             style:BButtonStyleBootstrapV3
                              icon:FAPlay
                          fontSize:20.0f];
    
    
    _speedButton.layer.cornerRadius = 3.f;
    _speedButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    _speedButton.layer.borderWidth = 1.0f;
    
    NSString *ct = [[self getCurrentJson] objectForKey:@"ct"];
    _contextButton.hidden = (ct == nil || ct.length == 0);
    
    NSString *audioOn = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"audioOn"];
    if (audioOn != nil) {
        _audioOnButton.selected = [audioOn isEqualToString:@"Yes"] ? 0:1;
        _audioOnButton.color = _audioOnButton.selected ?[UIColor blueColor]:[UIColor whiteColor];
    }
    
    _myAudioPlayer.volume = _audioOnButton.selected ? 1: 0;
    
    [self respondToSwipe];
    
    [self checkAndShowIntro];
}

// there's a timer that governs the pause between items -- if it's active, invalidate it
- (void)stopTimer {
    if (_autoAdvanceTimer != nil) {
        [_autoAdvanceTimer invalidate];
        [self endBackgroundUpdateTask];
    }
}

- (void)unselectAutoPlay {
    _autoPlayButton.selected = false;
    _autoPlayButton.color = _autoPlayButton.selected ?[UIColor blueColor]:[UIColor whiteColor];
    [self stopTimer];
}

- (void)stopAutoPlay {
    [self unselectAutoPlay];
    [self stopPlayingAudio];
    //  [self whatToShowSelection:nil];
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    NSLog(@"- viewWillDisappear - Stop auto play.");
    [self stopAutoPlay];
    // [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
}

-(void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    NSLog(@"RecoFlashcard - viewDidDisappear - cancelling audio cache queue operations.");
    
    [_audioCache cancelAllOperations];
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent {
    // NSLog(@"remoteControlReceivedWithEvent ---> %@ %ld",receivedEvent,receivedEvent.subtype);
    
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        switch (receivedEvent.subtype) {
            case UIEventSubtypeRemoteControlPause:
                //     NSLog(@"Got paused  --->");
                
                [self stopTimer];
                [self unselectAutoPlay];
                break;
            case UIEventSubtypeRemoteControlPlay:
                //   NSLog(@"Got play  --->");
                _autoPlayButton.selected = true;
                _autoPlayButton.color = _autoPlayButton.selected ?[UIColor blueColor]:[UIColor whiteColor];
                
                [self respondToSwipe];
                break;
            case UIEventSubtypeRemoteControlTogglePlayPause:
                //    NSLog(@"Got play/pause track --->");
                break;
                
            case UIEventSubtypeRemoteControlPreviousTrack:
                //   NSLog(@"Got prev track --->");
                [self stopPlayingAudio];
                _index--;
                if (_index == -1) _index = _jsonItems.count  -1UL;
                [self respondToSwipe];
                break;
                
            case UIEventSubtypeRemoteControlNextTrack:
                //   NSLog(@"Got next track --->");
                [self stopPlayingAudio];
                [self doAutoAdvance];
                break;
                
            default:
                break;
        }
    }
}

- (void)postEvent:(NSString *) message widget:(NSString *) widget type:(NSString *) type {
    EAFEventPoster *poster = [[EAFEventPoster alloc] initWithURL:_url];
    NSDictionary *jsonObject =[_jsonItems objectAtIndex:[self getItemIndex]];
    [poster postEvent:message exid:[jsonObject objectForKey:@"id"] widget:widget widgetType:type];
}

- (IBAction)showScoresClick:(id)sender {
    [self stopPlayingAudio];
    [self postEvent:@"showScoresClick" widget:@"showScores" type:@"Button"];
    [self performSegueWithIdentifier:@"goToReport" sender:self];
}

- (void)checkAvailableMics {
    NSError* theError = nil;
    BOOL result = YES;
    
    AVAudioSession* myAudioSession = [AVAudioSession sharedInstance];
    
    result = [myAudioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&theError];
    if (!result)
    {
        NSLog(@"setCategory failed");
    }
    
    result = [myAudioSession setActive:YES error:&theError];
    if (!result)
    {
        NSLog(@"setActive failed");
    }
    
    // Get the set of available inputs. If there are no audio accessories attached, there will be
    // only one available input -- the built in microphone.
    NSArray* inputs = [myAudioSession availableInputs];
    
    // Locate the Port corresponding to the built-in microphone.
    AVAudioSessionPortDescription* builtInMicPort = nil;
    AVAudioSessionPortDescription* headsetMicPort = nil;
    for (AVAudioSessionPortDescription* port in inputs)
    {
        if ([port.portType isEqualToString:AVAudioSessionPortBuiltInMic])
        {
            builtInMicPort = port;
            NSLog(@"found built in mic %@",port);
            // break;
        }
        else if ([port.portType isEqualToString:AVAudioSessionPortHeadsetMic])
        {
            headsetMicPort = port;
            NSLog(@"prefer headset mic!");
            [myAudioSession setPreferredInput:port error:&theError];
            // break;
        }
    }
    
    // Print out a description of the data sources for the built-in microphone
    NSLog(@"There are %u data sources for port :\"%@\"", (unsigned)[builtInMicPort.dataSources count], builtInMicPort);
    // NSLog(@"Headset port :\"%@\"",  headsetMicPort);
    //  NSLog(@"Sources : %@", builtInMicPort.dataSources);
    
    // prefer headset, then front mic
    if (!headsetMicPort) {
        // loop over the built-in mic's data sources and attempt to locate the front microphone
        AVAudioSessionDataSourceDescription* frontDataSource = nil;
        for (AVAudioSessionDataSourceDescription* source in builtInMicPort.dataSources)
        {
            if ([source.orientation isEqual:AVAudioSessionOrientationFront])
            {
                frontDataSource = source;
                break;
            }
        } // end data source iteration
        
        if (frontDataSource)
        {
            NSLog(@"Currently selected source is \"%@\" for port \"%@\"", builtInMicPort.selectedDataSource.dataSourceName, builtInMicPort.portName);
            NSLog(@"Attempting to select source \"%@\" on port \"%@\"", frontDataSource, builtInMicPort.portName);
            
            // Set a preference for the front data source.
            theError = nil;
            result = [builtInMicPort setPreferredDataSource:frontDataSource error:&theError];
            if (!result)
            {
                // an error occurred. Handle it!
                NSLog(@"setPreferredDataSource failed");
            }
            else {
                
                if (theError) {
                    NSLog(@"Domain:      %@", theError.domain);
                    NSLog(@"Error Code:  %ld", (long)theError.code);
                    NSLog(@"Description: %@", [theError localizedDescription]);
                    NSLog(@"Reason:      %@", [theError localizedFailureReason]);
                }
                //     NSLog(@"Currently selected source is \"%@\" for port \"%@\"", builtInMicPort.selectedDataSource.dataSourceName, builtInMicPort.portName);
                //     NSLog(@"There are %u data sources for port :\"%@\"", (unsigned)[builtInMicPort.dataSources count], builtInMicPort);
                
            }
            //AVAudioSessionDataSourceDescription *pref = [builtInMicPort preferredDataSource];
            // NSLog(@"Currently preferred source is \"%@\" for port \"%@\"", pref, builtInMicPort.portName);
        }
    }
}

- (NSDictionary *)getCurrentJson
{
    return [_jsonItems objectAtIndex:[self getItemIndex]];
}

- (BOOL)isiPhone
{
    //  NSLog(@"dev %@",[UIDevice currentDevice].model);
    return [[UIDevice currentDevice].model rangeOfString:@"iPhone"].location != NSNotFound;
}

- (BOOL)isiPad
{
    return ![self isiPhone];
}

- (void)scaleFont:(NSString *)exercise labelToScale:(UILabel *)labelToScale largest:(int) largest slen:(float) slen smallest:(int) smallest
{
    float len = [NSNumber numberWithUnsignedLong:exercise.length].floatValue;
    //    NSLog(@"scaleFont len of %@ = %lu",exercise,(unsigned long)len);
    float scale = slen/len;
    scale = fmin(1,scale);
    float newFont = smallest + floor((largest-smallest)*scale);
    //  NSLog(@"scaleFont font is %f",newFont);
    [labelToScale setFont:[UIFont systemFontOfSize:[NSNumber numberWithFloat:newFont].intValue]];
}

- (NSString *)trim:(NSString *)exercise
{
    return [exercise stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (void)configureTextFields
{
    NSDictionary *jsonObject = [self getCurrentJson];
    
    long selected = [_whatToShow selectedSegmentIndex];
    if (selected == 3) {
        NSString *exercise       = [jsonObject objectForKey:@"fl"];
        [self hideWithDashes:exercise];
    }
    else {
        //[_foreignLang setText:[self trim:exercise]];
        [self setForeignLang];
    }
    
    NSString *englishPhrases = [jsonObject objectForKey:@"en"];
    [_english setText:englishPhrases];
    
    _foreignLang.adjustsFontSizeToFitWidth=YES;
    _foreignLang.minimumScaleFactor=0.1;
    
    _english.adjustsFontSizeToFitWidth=YES;
    _english.minimumScaleFactor=0.1;
    
    if ([self isiPad]) {
        [_foreignLang setFont:[UIFont systemFontOfSize:52]];
        //        NSLog(@"font size is %@",_foreignLang.font);
    }
}

- (unsigned long)getItemIndex {
    unsigned long toUse = _index;
    if (
        _shuffleButton.selected
        ) {
        toUse = [[_randSequence objectAtIndex:_index] integerValue];
    }
    return toUse;
}

- (IBAction)gotGenderSelection:(id)sender {
    NSString *genderSelect = _genderMaleSelector.selectedSegmentIndex == 0 ? @"Male":_genderMaleSelector.selectedSegmentIndex == 1 ? @"Female" : @"Both";
    
    [SSKeychain setPassword:genderSelect
                 forService:@"mitll.proFeedback.device" account:@"audioGender"];
    
    [self postEvent:genderSelect widget:@"genderSelect" type:@"UIButton"];
    
    [self respondToSwipe];
}

- (void)setGenderSelector {
    NSString *audioGender = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"audioGender"];
    if (audioGender == nil) {
        [SSKeychain setPassword:@"Both"
                     forService:@"mitll.proFeedback.device" account:@"audioGender"];
    }
    //    NSLog(@"respondToSwipe gender sel %@",audioGender);
    _genderMaleSelector.selectedSegmentIndex = [audioGender isEqualToString:@"Male"] ? 0:[audioGender isEqualToString:@"Female"]?1:2;
}

// so if we swipe while the ref audio is playing, remove the observer that will tell us when it's complete
- (void)respondToSwipe {
    _progressThroughItems.progress = (float) _index/(float) _jsonItems.count;
    [self hideAndShowText];
    
    //   [self removePlayObserver];
    
    if ([self hasRefAudio]) {
        [_myAudioPlayer stopAudio];
    }
    
    [_synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    [_recoFeedbackImage stopAnimating];
    
    [_correctFeedback setHidden:true];
    [_scoreProgress     setProgress:0 ];
    
    [self setGenderSelector];
    
    NSString *audioSpeed = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"audioSpeed"];
    if (audioSpeed != nil) {
        //   NSLog(@"checking - audio on %@",audioSpeed);
        _speedButton.selected = [audioSpeed isEqualToString:@"Slow"];
        _speedButton.backgroundColor = _speedButton.selected ?[UIColor blueColor]:[UIColor whiteColor];
    }
    
    NSDictionary *jsonObject =[self getCurrentJson] ;
    
    NSString *refAudio = [jsonObject objectForKey:@"ref"];
    
    NSString *test =  [jsonObject objectForKey:@"msr"];
    BOOL hasMaleSlow = (test != NULL && ![test isEqualToString:@"NO"]);
    
    test =  [jsonObject objectForKey:@"mrr"];
    BOOL hasMaleReg = (test != NULL && ![test isEqualToString:@"NO"]);
    
    test =  [jsonObject objectForKey:@"fsr"];
    BOOL hasFemaleSlow = (test != NULL && ![test isEqualToString:@"NO"]);
    
    test =  [jsonObject objectForKey:@"frr"];
    BOOL hasFemaleReg = (test != NULL && ![test isEqualToString:@"NO"]);
    
    long selectedGender = _genderMaleSelector.selectedSegmentIndex;
    _audioRefs = [[NSMutableArray alloc] init];
    BOOL isSlow = _speedButton.selected;
    
    //    NSLog(@"speed is %@",isSlow ? @"SLOW" :@"REGULAR");
    //    NSLog(@"male slow %@",hasMaleSlow ? @"YES" :@"NO");
    //    NSLog(@"male reg  %@",hasMaleReg ? @"YES" :@"NO");
    //    NSLog(@"selected gender is %ld",selectedGender);
    //    NSLog(@"dict  %@",jsonObject);
    BOOL hasTwoGenders = (hasMaleReg || hasMaleSlow) && (hasFemaleReg || hasFemaleSlow);
    
    if (hasTwoGenders) {
        if (selectedGender == 0) {
            if (isSlow) {
                if (hasMaleSlow) {
                    refAudio = [jsonObject objectForKey:@"msr"];
                    [_audioRefs addObject: refAudio];
                }
            }
            else {
                if (hasMaleReg) {
                    refAudio = [jsonObject objectForKey:@"mrr"];
                    [_audioRefs addObject: refAudio];
                }
            }
        }
        else if (selectedGender == 1){
            if (isSlow) {
                if (hasFemaleSlow) {
                    refAudio = [jsonObject objectForKey:@"fsr"];
                    [_audioRefs addObject: refAudio];
                }
                else if (hasMaleSlow && refAudio == nil) { // fall back
                    refAudio = [jsonObject objectForKey:@"msr"];
                }
            }
            else {
                if (hasFemaleReg) {
                    refAudio =  [jsonObject objectForKey:@"frr"];
                    [_audioRefs addObject: refAudio];
                }
                else if (hasMaleReg && refAudio == nil) { // fall back
                    refAudio = [jsonObject objectForKey:@"mrr"];
                }
            }
        } else {
            if (isSlow) {
                if (hasMaleSlow) {
                    refAudio = [jsonObject objectForKey:@"msr"];
                    [_audioRefs addObject: refAudio];
                }
                if (hasFemaleSlow) {
                    refAudio = [jsonObject objectForKey:@"fsr"];
                    [_audioRefs addObject: refAudio];
                }
            }
            else {
                if (hasMaleReg) {
                    refAudio = [jsonObject objectForKey:@"mrr"];
                    [_audioRefs addObject: refAudio];
                }
                if (hasFemaleReg) {
                    refAudio =  [jsonObject objectForKey:@"frr"];
                    [_audioRefs addObject: refAudio];
                }
            }
        }
    } else {
        if (isSlow) {
            if (hasMaleSlow) {
                refAudio = [jsonObject objectForKey:@"msr"];
                [_audioRefs addObject: refAudio];
            }
            if (hasFemaleSlow) {
                refAudio = [jsonObject objectForKey:@"fsr"];
                [_audioRefs addObject: refAudio];
            }
            if (!hasMaleSlow && !hasFemaleSlow) {
                if (hasMaleReg && refAudio == nil) {
                    refAudio = [jsonObject objectForKey:@"mrr"];
                }
                else if (hasFemaleReg && refAudio == nil) {
                    refAudio = [jsonObject objectForKey:@"frr"];
                }
            }
        }
        else {
            if (hasMaleReg) {
                refAudio = [jsonObject objectForKey:@"mrr"];
                [_audioRefs addObject: refAudio];
            }
            if (hasFemaleReg) {
                refAudio =  [jsonObject objectForKey:@"frr"];
                [_audioRefs addObject: refAudio];
            }
            if (!hasMaleReg && !hasFemaleReg) {
                if (hasMaleSlow && refAudio == nil) {
                    refAudio = [jsonObject objectForKey:@"msr"];
                }
                else if (hasFemaleSlow && refAudio == nil) {
                    refAudio = [jsonObject objectForKey:@"fsr"];
                }
            }
        }
    }
    _genderMaleSelector.enabled = hasTwoGenders;
    [_genderMaleSelector setEnabled:(hasMaleReg || hasMaleSlow) forSegmentAtIndex:0];
    [_genderMaleSelector setEnabled:(hasFemaleReg || hasFemaleSlow) forSegmentAtIndex:1];
    [_genderMaleSelector setEnabled:hasTwoGenders forSegmentAtIndex:2];
    
    BOOL hasTwoSpeeds = (hasMaleReg || hasFemaleReg) && (hasMaleSlow || hasFemaleSlow);
    _speedButton.enabled = hasTwoSpeeds;
    
    if (refAudio != nil && ![refAudio isEqualToString:@"NO"] && _audioRefs.count == 0) {
        //        NSLog(@"respondToSwipe adding refAudio %@",refAudio);
        [_audioRefs addObject:refAudio];
    }
    
    if (_autoPlayButton.selected && _audioRefs.count > 1) {
        [_audioRefs removeLastObject];
    }
    //  NSLog(@"respondToSwipe after refAudio %@ and %@",refAudio,_audioRefs);
    
    NSString *flAtIndex = [jsonObject objectForKey:@"fl"];
    NSString *enAtIndex = [jsonObject objectForKey:@"en"];
    
    flAtIndex = [self trim:flAtIndex];
    
    // long selected = ;
    if ([_whatToShow selectedSegmentIndex] == 3) {
        [self hideWithDashes:flAtIndex];
    }
    else {
        [_foreignLang setText:flAtIndex];
    }
    
    [_english setText:enAtIndex];
    
    BOOL isIPhone = [self isiPhone];
    
    if (isIPhone) {
        int maxFont  = 48;
        int maxEFont = 40;
        
        NSString *dev =[self deviceName];
        
        BOOL issmall = [dev rangeOfString:@"iPhone4"].location != NSNotFound;
        if (issmall) {
            maxFont = 30;
            maxEFont = 30;
        }
        [self scaleFont:flAtIndex labelToScale:_foreignLang largest:maxFont slen:22 smallest:14];
        
        //     CGRect rect = [_english.text boundingRectWithSize:_english.bounds.size options:NSStringDrawingTruncatesLastVisibleLine attributes:nil context:nil];
        //   NSLog(@"Got rect %@",rect);
        //     NSLog(@"%@ vs %@", NSStringFromCGRect(rect), NSStringFromCGRect(_english.bounds));
        
        [self scaleFont:enAtIndex labelToScale:_english     largest:maxEFont slen:10 smallest:14];
    }
    
    for (UIView *v in [_scoreDisplayContainer subviews]) {
        [v removeFromSuperview];
    }
    _scoreProgress.hidden = true;
    _myAudioPlayer.audioPaths = _audioRefs;
    
    NSString *userid = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"userid"];
    NSString *showedID = [NSString stringWithFormat:@"showedIntro_%@",userid];
    NSString *showedIntro = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:showedID];
    
    BOOL showEnglish = _whatToShow.selectedSegmentIndex == 0;
    // complicated...
    // _myAudioPlayer.audioPaths = _audioRefs;
    if (_audioOnButton.selected &&   // volume on
        !_preventPlayAudio &&
        showedIntro != nil) {
        
        //         NSLog(@"respondToSwipe first");
        if (showEnglish) {
            //   NSLog(@"respondToSwipe first - %ld", (long)_whatToShow.selectedSegmentIndex);
            if (_autoPlayButton.selected) {
                
                [self speakEnglish:false];
            }
        }
        else {
            [self playRefAudioIfAvailable];
        }
    }
    else {
        _preventPlayAudio = false;
        if (_autoPlayButton.selected) {
            if (showEnglish) {
                [self speakEnglish:false];
            }
            else {
                [self playRefAudioIfAvailable];
            }
        }
    }
}

- (NSString*) deviceName {
    struct utsname systemInfo;
    uname(&systemInfo);
    
    return [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
}

- (IBAction)swipeRightDetected:(UISwipeGestureRecognizer *)sender {
    [self stopAutoPlay];
    
    _index--;
    if (_index == -1) _index = _jsonItems.count  -1UL;
    
    [self postEvent:@"swipeRight" widget:@"card" type:@"UIView"];
    [self respondToSwipe];
}

- (IBAction)swipeLeftDetected:(UISwipeGestureRecognizer *)sender {
    //    NSLog(@"swipeLeftDetected progress is %f", _progressThroughItems.progress);
    
    [self stopAutoPlay];
    
    _index++;
    BOOL onLast = _index == _jsonItems.count;
    if (onLast) {
        _index = 0;
        // TODO : get the sorted list and resort the items in incorrect first order
    }
    
    if (onLast) {
        _preventPlayAudio = TRUE;
    }
    
    [self postEvent:@"swipeLeft" widget:@"card" type:@"UIView"];
    
    if (onLast) {
        [self showScoresClick:nil];
        [((EAFItemTableViewController*)_itemViewController) askServerForJson];
    }
    else {
        [self respondToSwipe];
    }
}

- (IBAction)autoPlaySelected:(id)sender {
    _autoPlayButton.selected = !_autoPlayButton.selected;
    _autoPlayButton.color = _autoPlayButton.selected ?[UIColor blueColor]:[UIColor whiteColor];
    
    if (_autoPlayButton.selected) {
        NSError *activationError = nil;
        BOOL success = [[AVAudioSession sharedInstance] setActive:YES error:&activationError];
        if (!success) { /* handle the error condition */ }
        
        // do autoplay
        [self stopPlayingAudio];
        
        if (_audioRefs.count > 1) {
            [_audioRefs removeLastObject];
        }
        [self playRefAudioIfAvailable];
        // Turn on remote control event delivery
        
        NSLog(@"beginReceivingRemoteControlEvents ----\n");
        
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
        [self postEvent:@"autoPlaySelected" widget:@"autoPlay" type:@"Button"];
        
    }
    else {
        [self postEvent:@"autoPlayDeselected" widget:@"autoPlay" type:@"Button"];
        
        // stop autoplay
        //[[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    }
}

// TODO make sure have right ui state when we return
- (void) viewBecameActive {
    NSLog(@"view became active ----\n");
}

-(void) applicationWillResignActive {
    NSLog(@"applicationWillResignActive ----\n");
}

- (void) speakEnglish:(BOOL) volumeOn {
    NSLog(@"Speak english");
    _english.hidden = false;
    [self speak:_english.text volumeOn:volumeOn];
}

// for now, don't speak foreign language items
- (void)speak:(NSString *) toSpeak volumeOn:(BOOL)volumnOn {
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:toSpeak];
    
    utterance.volume = 0.8;
    // [utterance setRate:0.2f];
    
    if (!_audioOnButton.selected && !volumnOn) {
        utterance.volume = 0;
        NSLog(@"volume %f",utterance.volume);
    }
    //else {
    //NSLog(@"normal volume %f",utterance.volume);
    //}
    [_synthesizer speakUtterance:utterance];
}

- (IBAction)tapOnEnglish:(id)sender {
    [self stopPlayingAudio];
    [self speakEnglish:true];
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didPauseSpeechUtterance:(AVSpeechUtterance *)utterance {
    NSLog(@"recoflashcard : didPauseSpeechUtterance---");
    [self showSpeechEnded:true];
}

- (void)showSpeechEnded:(BOOL) isEnglish {
    //    if (isEnglish) {
    _english.textColor = [UIColor blackColor];
    //    }
    //    else {
    //        _foreignLang.textColor = [UIColor blackColor];
    //    }
    //  NSLog(@"Font size %f",_foreignLang.font.pointSize);
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didContinueSpeechUtterance:(AVSpeechUtterance *)utterance {
    NSLog(@"recoflashcard : didContinueSpeechUtterance---");
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didCancelSpeechUtterance:(AVSpeechUtterance *)utterance {
    NSLog(@"recoflashcard : didCancelSpeechUtterance---");
    [self showSpeechEnded:true];
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didStartSpeechUtterance:(AVSpeechUtterance *)utterance
{
    NSLog(@"recoflashcard : didStartSpeechUtterance --- '%@'",utterance.speechString);
    
    //   _pageControl.currentPage = 0;
    _english.textColor = [UIColor blueColor];
}

// when autoplay is active, automatically go to next item...
- (void)doAutoAdvance
{
    [self endBackgroundUpdateTask];
    
    _index++;
    BOOL onLast = _index == _jsonItems.count;
    if (onLast) {
        _index = 0;
    }
    
    [self respondToSwipe];
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance
{
    NSLog(@"recoflashcard : didFinishSpeechUtterance--- '%@'",utterance.speechString);
    BOOL isEnglish = true;
    [self showSpeechEnded:isEnglish];
    
    if (_autoPlayButton.selected) {
        NSLog(@"-----> didFinishSpeechUtterance : '%@' is done playing, so advancing to %lu",utterance.speechString,_index);
        [self beginBackgroundUpdateTask];
        
        if (_whatToShow.selectedSegmentIndex == 0) { // english first, so play fl
            _foreignLang.hidden = false;
            [self playRefAudioIfAvailable];
        }
        else { // played fl, then english, which is done, so go to next item
            _autoAdvanceTimer = [NSTimer scheduledTimerWithTimeInterval:_autoAdvanceInterval target:self selector:@selector(doAutoAdvance) userInfo:nil repeats:NO];
        }
    }
}
- (void) beginBackgroundUpdateTask
{
    self.backgroundUpdateTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [self endBackgroundUpdateTask];
    }];
}

- (void) endBackgroundUpdateTask
{
    if (self.backgroundUpdateTask) {
        [[UIApplication sharedApplication] endBackgroundTask: self.backgroundUpdateTask];
        self.backgroundUpdateTask = UIBackgroundTaskInvalid;
    }
}

// deals with missing audio...?
- (void)playRefAudioIfAvailable {
    // NSLog(@"play ref if avail");
    [_synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    if ([self hasRefAudio]) {
        //  NSLog(@"\tplay ref if avail");
        [_myAudioPlayer playRefAudio];
    }
    else {
        NSString *current = [[self getCurrentJson] objectForKey:@"id"];
        NSLog(@"HUH? no ref audio exid %@",current);
    }
}

- (IBAction)tapOnForeignDetected:(UITapGestureRecognizer *)sender{
    _myAudioPlayer.volume = 1;
    
    [self playRefAudioIfAvailable];
    [self postEvent:@"playAudioTouch" widget:_english.text type:@"UILabel"];
}

- (void)hideWithDashes:(NSString *)exercise {
    NSString *trim = [self trim:exercise];
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[^\\s]" options:NSRegularExpressionCaseInsensitive error:&error];
    NSString *modifiedString = [regex stringByReplacingMatchesInString:trim options:0 range:NSMakeRange(0, [trim length]) withTemplate:@"-"];
    
    [_foreignLang setText:modifiedString];
}

- (void)hideAndShowText {
    long selected = [_whatToShow selectedSegmentIndex];
    // NSLog(@"recoflashcard : hideAndShowText %ld", selected);
    if (selected == 0) { // english
        _foreignLang.hidden = true;
        _english.hidden = false;
        _pageControl.hidden = false;
        _pageControl.currentPage = 0;
        
        [_myAudioPlayer stopAudio];
        [self setForeignLang];
    }
    else if (selected == 1) {  // fl
        _foreignLang.hidden = false;
        _english.hidden = true;
        _pageControl.hidden = false;
        _pageControl.currentPage = 1;
        
        [self setForeignLang];
        [_synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    }
    else if (selected == 2){
        _foreignLang.hidden = false;
        _english.hidden = false;
        _pageControl.hidden = true;
        [self setForeignLang];
    }
    else {
        _foreignLang.hidden = false;
        _english.hidden = true;
        _pageControl.hidden = false;
        _pageControl.currentPage = 0;
        
        NSDictionary *jsonObject = [self getCurrentJson];
        NSString *exercise       = [jsonObject objectForKey:@"fl"];
        [self hideWithDashes:exercise];
    }
}

- (void)setForeignLang {
    NSDictionary *jsonObject = [self getCurrentJson];
    NSString *exercise       = [jsonObject objectForKey:@"fl"];
    [_foreignLang setText:[self trim:exercise]];
}

// control showing english, fl phrase, or both
- (IBAction)whatToShowSelection:(id)sender {
    [self hideAndShowText];
    
    long selected = [_whatToShow selectedSegmentIndex];
    
    if (selected == 0) { // english
        [self postEvent:@"showOnlyEnglish" widget:@"UIChoice" type:@"Button"];
    }
    else if (selected == 1) {  // fl
        [self postEvent:@"showOnlyForeign" widget:@"UIChoice" type:@"Button"];
    }
    else if (selected == 2){
        [self postEvent:@"showBothEnglishAndForeign" widget:@"UIChoice" type:@"Button"];
    }
    else {
        [self postEvent:@"hideBoth" widget:@"UIChoice" type:@"Button"];
    }
    
    if (_autoPlayButton.selected) {
        [self doAutoAdvance];
    }
}

- (IBAction)speedSelection:(id)sender {
    _speedButton.selected = !_speedButton.selected;
    NSString *speed = (_speedButton.selected ? @"Slow":@"Regular");
    [SSKeychain setPassword:speed
                 forService:@"mitll.proFeedback.device" account:@"audioSpeed"];
    
    
    [self postEvent:speed widget:@"speed" type:@"UIButton"];

    _speedButton.backgroundColor = _speedButton.selected ?[UIColor blueColor]:[UIColor whiteColor];
    if (!_autoPlayButton.selected) {
        [self respondToSwipe];
    }
}

// remember selection in keychain cache
- (IBAction)audioOnSelection:(id)sender {
    [SSKeychain setPassword:(_audioOnButton.selected ? @"Yes":@"No")
                 forService:@"mitll.proFeedback.device" account:@"audioOn"];
    _audioOnButton.selected = !_audioOnButton.selected;
    _audioOnButton.color = _audioOnButton.selected ?[UIColor blueColor]:[UIColor whiteColor];
    
    _myAudioPlayer.volume = _audioOnButton.selected ? 1: 0;
    
    if (_audioOnButton.selected) {
        [self postEvent:@"turnOnAudio" widget:@"audioOnButton" type:@"Button"];
    }
    else {
        [self postEvent:@"turnOffAudio" widget:@"audioOnButton" type:@"Button"];
        
    }
    
    if (!_autoPlayButton.selected) {
        if (!_audioOnButton.selected) {
            [self stopPlayingAudio];
        }
        [self respondToSwipe];
    }
}

- (BOOL) hasRefAudio
{
    return _audioRefs.count > 0;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)audioPlayerDidFinishPlaying:
(AVAudioPlayer *)player successfully:(BOOL)flag
{
    _recordButton.enabled = YES;
    [self setTextColor:[UIColor blackColor]];
}

- (void) playStarted {
    [self highlightFLWhilePlaying];
}

- (void) playStopped {
    [self removePlayingAudioHighlight];
}

- (void) playGotToEnd {
    if (_autoPlayButton.selected) {
        // doing autoplay!
        // skip english if lang is english
        if ([_english.text isEqualToString:_foreignLang.text]) {
            [self doAutoAdvance];
        }
        else {
            // OK move on to english part of card, automatically
            NSLog(@"playGotToEnd - speak english");
            if (_whatToShow.selectedSegmentIndex == 0) { // already played english, so now at end of fl, go to next
                [self doAutoAdvance];
            }
            else { // haven't played english yet, so play it
                [self speakEnglish:false];
            }
        }
    }
    else {
        //  NSLog(@"playGotToEnd - no op");
    }
}

// set the text color of all the labels in the scoreDisplayContainer
- (void)setTextColor:(UIColor *)color {
    for (UIView *subview in [_scoreDisplayContainer subviews]) {
        if ([subview isKindOfClass:[UILabel class]]) {
            UILabel *asLabel = (UILabel *) subview;
            asLabel.textColor = color;
            NSLog(@"initial hit %@ %@",asLabel,asLabel.text);
        }
        else {
            for (UIView *subview2 in [subview subviews]) {
                if ([subview2 isKindOfClass:[UILabel class]]) {
                    UILabel *asLabel = (UILabel *) subview2;
                    asLabel.textColor = color;
                }
            }
        }
    }
}

- (void)audioPlayerDecodeErrorDidOccur:
(AVAudioPlayer *)player error:(NSError *)error
{
    NSLog(@"Decode Error occurred %@",error);
}

- (void)audioRecorderDidFinishRecording:
(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    if (debugRecord)  NSLog(@"audioRecorderDidFinishRecording time = %f",CFAbsoluteTimeGetCurrent());
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:_audioRecorder.url options:nil];
    CMTime time = asset.duration;
    double durationInSeconds = CMTimeGetSeconds(time);
    
    NSLog(@"audioRecorderDidFinishRecording : file duration was %f vs event       %f diff %f",durationInSeconds, (_now-_then2), (_now-_then2)-durationInSeconds );
    NSLog(@"audioRecorderDidFinishRecording : file duration was %f vs gesture end %f diff %f",durationInSeconds, (_gestureEnd-_then2), (_gestureEnd-_then2)-durationInSeconds );
    
    if (durationInSeconds > 0.3) {
        if (_hasModel) {
            [self postAudio];
        }
        else {
            NSLog(@"audioRecorderDidFinishRecording not posting audio since no model...");
        }
    }
    else {
        [self setDisplayMessage:@"Recording too short."];
        if (_audioRecorder.recording)
        {
            if (debugRecord)  NSLog(@"audioRecorderDidFinishRecording : stopAudio stop time = %f",CFAbsoluteTimeGetCurrent());
            [_audioRecorder stop];
        }
    }
}

- (void)audioRecorderEncodeErrorDidOccur:
(AVAudioRecorder *)recorder error:(NSError *)error
{
    NSLog(@"Encode Error occurred");
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Error recording..." message: @"Didn't record audio file." delegate: nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

- (IBAction)gotTapInSuperview:(id)sender {
    // NSLog(@" gotTapInSuperview");
    [self stopAutoPlay];
    
    long selected = [_whatToShow selectedSegmentIndex];
    if (selected == 0 || selected == 1 || selected == 3) {
        [self flipCard];
    }
}

- (void)stopPlayingAudio {
    NSLog(@" stopPlayingAudio ---- ");
    
    [self removePlayingAudioHighlight];
    [_myAudioPlayer stopAudio];
    [_altPlayer pause];
    [_synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    
    int i = 0;
    
    for (NSDictionary *event in _wordTranscript) {
        NSString *word = [event objectForKey:@"event"];
        if ([word isEqualToString:@"sil"] || [word isEqualToString:@"<s>"] || [word isEqualToString:@"</s>"]) continue;
        NSNumber *wstart = [event objectForKey:@"start"];
        NSNumber *wend   = [event objectForKey:@"end"];
        NSNumber *wscore   = [event objectForKey:@"score"];
        // NSLog(@"w on %d of %d",i,weakSelf.wordLabels.count);
        // NSLog(@"p on %d of %d",i,weakSelf.phoneLabels.count);
        
        UILabel *label      = [_wordLabels  objectAtIndex:i];
        UILabel *phoneLabel = [_phoneLabels objectAtIndex:i++];
        
        // put back the coloring on the word labels
        NSMutableAttributedString *highlight = [[NSMutableAttributedString alloc] initWithString:label.text];
        
        UIColor *hColor = [self getColor2:[wscore floatValue]];
        NSRange range = NSMakeRange(0, [highlight length]);
        
        [highlight addAttribute:NSBackgroundColorAttributeName
                          value:hColor
                          range:range];
        
        label.attributedText = highlight;
        
        //      NSLog(@"event %@ at %f - %f not in %f",word,[wstart floatValue],[wend floatValue],now);
        
        // put back the coloring on the phone labels
        NSString *phoneToShow = [self getPhonesWithinWord:wend wstart:wstart phoneAndScore:self.phoneTranscript];
        NSMutableAttributedString *coloredPhones = [self getColoredPhones:phoneToShow wend:wend wstart:wstart phoneAndScore:self.phoneTranscript];
        phoneLabel.attributedText = coloredPhones;
    }
    
}

- (void)removePlayingAudioHighlight {
    if (_foreignLang.textColor == [UIColor blueColor]) {
        _foreignLang.textColor = [UIColor blackColor];
    }
}

- (void)highlightFLWhilePlaying
{
    //    NSLog(@" highlightFLWhilePlaying - show fl");
    _foreignLang.textColor = [UIColor blueColor];
    //    _pageControl.currentPage = 1;
}

- (void)logError:(NSError *)error {
    NSLog(@"Domain:      %@", error.domain);
    NSLog(@"Error Code:  %ld", (long)error.code);
    NSLog(@"Description: %@", [error localizedDescription]);
    NSLog(@"Reason:      %@", [error localizedFailureReason]);
}

bool debugRecord = false;

- (IBAction)recordAudio:(id)sender {
    [self stopAutoPlay];
    
    _then2 = CFAbsoluteTimeGetCurrent();
    if (debugRecord) NSLog(@"recordAudio time = %f",_then2);
    
    [_myAudioPlayer stopAudio];
    
    //    [self performSelectorOnMainThread:@selector(postRecordAudioStart)
    //                           withObject:nil
    //                        waitUntilDone:NO];
    
    //   [self postEvent:@"record audio start" widget:@"record audio" type:@"Button"];
    if (!_audioRecorder.recording)
    {
        if (debugRecord) NSLog(@"startRecordingFeedbackWithDelay time = %f",CFAbsoluteTimeGetCurrent());
        _english.textColor = [UIColor blackColor];
        
        for (UIView *v in [_scoreDisplayContainer subviews]) {
            [v removeFromSuperview];
        }
        
        NSError *error = nil;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord error:&error];
        [_audioRecorder record];
        
        if (_audioRecorder.recording)
        {
            if (debugRecord) {
                CFAbsoluteTime recordingBegins = CFAbsoluteTimeGetCurrent();
                NSLog(@"recordAudio -recording %f vs begin %f diff %f ",_then2,recordingBegins,(recordingBegins-_then2));
            }
        }
        else {
            NSLog(@"recordAudio -DUDE NOT recording");
            [self logError:error];
        }
    }
}

- (void)postRecordAudioStart {
    [self postEvent:@"record audio start" widget:@"record audio" type:@"Button"];
}

- (void)flipCard {
    [self unselectAutoPlay];
    [self stopPlayingAudio];
    
    _pageControl.currentPage = _pageControl.currentPage == 0 ? 1 : 0;
    long selected = [_whatToShow selectedSegmentIndex];
    
    //  NSLog(@"flipCard initially selected %ld fl hidden %@",selected, _foreignLang.hidden  ? @"YES" :@"NO");
    
    _foreignLang.hidden = !_foreignLang.hidden;
    _english.hidden = !_english.hidden;
    
    NSLog(@"flipCard selected %ld fl hidden %@",selected, _foreignLang.hidden  ? @"YES" :@"NO");
    //NSLog(@"flipCard en hidden %@", _english.hidden  ? @"YES" :@"NO");
    
    if (selected == 3) { // hide
        NSLog(@"flipCard hide selected");
        
        _foreignLang.hidden = false;
        
        if ([[_foreignLang text] hasPrefix:@"-"]) {
            NSLog(@"flipCard starts with dash");
            
            _english.hidden = false;
            [self setForeignLang];
        }
        else {
            NSLog(@"flipCard fl =  %@",[_foreignLang text]);
            
            _english.hidden = true;
            
            NSDictionary *jsonObject = [self getCurrentJson];
            NSString *exercise       = [jsonObject objectForKey:@"fl"];
            [self hideWithDashes:exercise];
        }
    }
    else {
        if (_foreignLang.hidden && _english.hidden) {
            if (selected == 0) { // english
                _english.hidden = false;
            }
            else if (selected == 1) { // foreign lang
                _foreignLang.hidden = false;
            }
            else {
                _english.hidden = false;
                _foreignLang.hidden = false;
            }
        }
    }
    
    if (_audioOnButton.selected) {
        if (!_preventPlayAudio) {
            if (!_foreignLang.hidden) {
                [self playRefAudioIfAvailable];
            }
            else if (_autoPlayButton.selected && !_english.hidden) {
                [self speakEnglish:false];
            }
        }
    }
}

// TODO : maybe only flip card on tap?
// TODO : swipe up to show control center also registers as a swipe up on the card, pausing the auto play playback
- (IBAction)swipeUp:(UISwipeGestureRecognizer *)sender {
    //    NSLog(@"Got swipe up from %@",sender);
    CGPoint pt2 = [sender locationInView:self.view];
    
    //    NSLog(@"Got swipe up location in view %f, %f",pt2.x, pt2.y);
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = screenRect.size.height;
    
    //    NSLog(@"Got swipe   %f, %f",screenWidth,screenHeight);
    
    if (screenHeight - pt2.y < 10) {
        CGFloat screenWidth = screenRect.size.width;
        NSLog(@"Got swipe IGNORING SWIPE, since control center swipe %f, %f",screenWidth,screenHeight);
    }
    else {
        long selected = [_whatToShow selectedSegmentIndex];
        if (selected == 0 || selected == 1 || selected == 3) { // eng or fl
            [self flipCard];
        }
        else if (selected == 3) { // hide
            if ([[_foreignLang text] hasPrefix:@"-"]) {
                [self setForeignLang];
                _english.hidden = false;
                _foreignLang.hidden = false;
            }
            
        }
        else {
            [self swipeLeftDetected:sender];
        }
        [self postEvent:@"swipeUp" widget:@"card" type:@"card"];
    }
}

- (IBAction)swipeDown:(id)sender {
    if ([_whatToShow selectedSegmentIndex] == 2) {
        [self swipeRightDetected:sender];
    }
    else {
        [self swipeUp:sender ];
    }
}

- (IBAction)longPressAction:(id)sender {
    if (_longPressGesture.state == UIGestureRecognizerStateBegan) {
        _gestureStart = CFAbsoluteTimeGetCurrent();
        
        _recordButtonContainer.backgroundColor =[UIColor greenColor];
        _recordButton.enabled = NO;
        
        [_correctFeedback setHidden:true];
        _scoreProgress.hidden = true;
        
        [self setDisplayMessage:@""];
        [self recordAudio:nil];
    }
    else if (_longPressGesture.state == UIGestureRecognizerStateEnded) {
        _gestureEnd = CFAbsoluteTimeGetCurrent();
        
        _recordButtonContainer.backgroundColor =[UIColor whiteColor];
        _recordButton.enabled = YES;
        
        if (debugRecord)  NSLog(@"longPressAction now  time = %f",_gestureEnd);
        double gestureDiff = _gestureEnd - _gestureStart;
        
        // NSLog(@"diff %f",gestureDiff);
        if (gestureDiff < 0.4) {
            [self setDisplayMessage:@"Press and hold to record."];
            if (_audioRecorder.recording)
            {
                if (debugRecord)  NSLog(@"longPressAction : stopAudio stop time = %f",CFAbsoluteTimeGetCurrent());
                [_audioRecorder stop];
            }
        }
        else {
            [self stopRecordingWithDelay:nil];
        }
    }
}

// called when touch on highlighted word
- (IBAction)playAudio:(id)sender {
    if (!_audioRecorder.recording)
    {
        NSLog(@"playAudio %@",_audioRecorder.url);
        [self stopPlayingAudio];
        
        NSError *error;
        AVAudioSession *session = [AVAudioSession sharedInstance];
        
        [session setCategory:AVAudioSessionCategoryPlayback error:nil];
        // what does this do?
        [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
        
        _altPlayer = [[AVPlayer alloc] initWithURL:_audioRecorder.url];
        
        CMTime tm = CMTimeMakeWithSeconds(0.01, 100);
        _lastUpdate = 0.0;
        
        __weak typeof(self) weakSelf = self;
        
        NSMutableDictionary *prevWordAttr  = [NSMutableDictionary new];
        
        int i = 0;
        for (NSDictionary *event in weakSelf.wordTranscript) {
            NSString *word = [event objectForKey:@"event"];
            if ([word isEqualToString:@"sil"] || [word isEqualToString:@"<s>"] || [word isEqualToString:@"</s>"]) continue;
            // NSLog(@"w on %d of %d",i,weakSelf.wordLabels.count);
            //   NSLog(@"p on %d of %d",i,weakSelf.phoneLabels.count);
            
            UILabel *label      = [weakSelf.wordLabels  objectAtIndex:i];
            // UILabel *phoneLabel = [weakSelf.phoneLabels objectAtIndex:i];
            
            [prevWordAttr  setObject:label.attributedText forKey:[NSNumber numberWithInt:i]];
            //   [prevPhoneAttr setObject:phoneLabel.attributedText forKey:[NSNumber numberWithInt:i]];
            i++;
        }
        
        UIColor *hColor = [EAFRecoFlashcardController colorFromHexString:@"#007AFF"];
        
        [_altPlayer addPeriodicTimeObserverForInterval:tm queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            float now = CMTimeGetSeconds(time);
            if (now == weakSelf.lastUpdate && now > 0) {
                weakSelf.recordButton.enabled = YES;
            }
            else {
                int i = 0;
                for (NSDictionary *event in weakSelf.wordTranscript) {
                    NSString *word = [event objectForKey:@"event"];
                    if ([word isEqualToString:@"sil"] || [word isEqualToString:@"<s>"] || [word isEqualToString:@"</s>"]) continue;
                    NSNumber *wstart = [event objectForKey:@"start"];
                    NSNumber *wend   = [event objectForKey:@"end"];
                    // NSLog(@"w on %d of %d",i,weakSelf.wordLabels.count);
                    //   NSLog(@"p on %d of %d",i,weakSelf.phoneLabels.count);
                    
                    UILabel *label      = [weakSelf.wordLabels  objectAtIndex:i];
                    NSNumber *index = [NSNumber numberWithInt:i];
                    UILabel *phoneLabel = [weakSelf.phoneLabels objectAtIndex:i++];
                    
                    if (now >= [wstart floatValue] && now < [wend floatValue]) {
                        //   NSLog(@"hilight text %@",label.text);
                        NSMutableAttributedString *highlight = [[NSMutableAttributedString alloc] initWithString:label.text];
                        
                        NSRange range = NSMakeRange(0, [highlight length]);
                        
                        [highlight addAttribute:NSBackgroundColorAttributeName
                                          value:hColor
                                          range:range];
                        
                        label.attributedText = highlight;
                        
                        NSAttributedString *attr =
                        [weakSelf markForegroundPhones:wend wstart:wstart phoneAndScore:weakSelf.phoneTranscript current:phoneLabel.attributedText now:now];
                        
                        phoneLabel.attributedText = attr;
                    }
                    else {
                        //  NSLog(@"don't highlight %@",label.text);
                        label.attributedText = [prevWordAttr objectForKey:index];
                        
                        NSMutableAttributedString *coloredPhones = [weakSelf getColoredPhones:phoneLabel.text wend:wend wstart:wstart phoneAndScore:weakSelf.phoneTranscript];
                        phoneLabel.attributedText = coloredPhones;
                        
                        //      NSLog(@"event %@ at %f - %f not in %f",word,[wstart floatValue],[wend floatValue],now);
                    }
                }
            }
            
            weakSelf.lastUpdate = now;
        }];
        
        if (error)
        {
            NSLog(@"Error: %@", [error localizedDescription]);
        } else {
            [_altPlayer play];
        }
        
        [self postEvent:@"playUserAudio" widget:@"userScoreDisplay" type:@"UIView"];
    }
}

+ (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

- (IBAction)stopAudio:(id)sender {
    _now = CFAbsoluteTimeGetCurrent();
    if (debugRecord)  NSLog(@"stopAudio Event duration was %f",(_now-_then2));
    if (debugRecord)  NSLog(@"stopAudio now  time =        %f",_now);
    
    _recordButton.enabled = YES;
    
    if (_audioRecorder.recording)
    {
        if (debugRecord)  NSLog(@"stopAudio stop time = %f",CFAbsoluteTimeGetCurrent());
        [_audioRecorder stop];
        
    } else {
        NSLog(@"stopAudio not recording");
    }
}

- (IBAction)stopRecordingWithDelay:sender {
    [NSTimer scheduledTimerWithTimeInterval:0.33
                                     target:self
                                   selector:@selector(stopAudio:)
                                   userInfo:nil
                                    repeats:NO];
}

- (IBAction)shuffleChange:(id)sender {
    _shuffleButton.selected = !_shuffleButton.selected;
    _shuffleButton.color = _shuffleButton.selected ?[UIColor blueColor]:[UIColor whiteColor];
    
    if (_shuffleButton.selected) {
        [self doShuffle];
    }
    [self respondToSwipe];
    
    [self postEvent:@"shuffle" widget:@"shuffle" type:@"UIButton"];
}

- (void)doShuffle {
    _randSequence = [[NSMutableArray alloc] initWithCapacity:_jsonItems.count];
    
    for (unsigned long i = 0; i < _jsonItems.count; i++) {
        [_randSequence addObject:[NSNumber numberWithUnsignedLong:i]];
    }
    
    unsigned int max = _jsonItems.count-1;
    
    for (unsigned int ii = 0; ii < max; ++ii) {
        unsigned int remainingCount = max - ii;
        unsigned int r = arc4random_uniform(remainingCount)+ii;
        [_randSequence exchangeObjectAtIndex:ii withObjectAtIndex:r];
    }
    
    _index = 0;
}

// Posts audio with current fl field
- (void)postAudio {
    // create request
    [_recoFeedbackImage startAnimating];
    
    NSData *postData = [NSData dataWithContentsOfURL:_audioRecorder.url];
    // NSLog(@"data %d",[postData length]);
    
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
    
    // NSLog(@"file length %@",postLength);
    NSString *baseurl = [NSString stringWithFormat:@"%@/scoreServlet", _url];
    NSLog(@"postAudio talking to %@",baseurl);
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:baseurl]];
    [urlRequest setHTTPMethod: @"POST"];
    [urlRequest setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [urlRequest setValue:@"application/x-www-form-urlencoded"
      forHTTPHeaderField:@"Content-Type"];
    [urlRequest setTimeoutInterval:15];
    
    // add request parameters
    [urlRequest setValue:@"MyAudioMemo.wav" forHTTPHeaderField:@"fileName"];
    NSString *userid = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"userid"];
    
    [urlRequest setValue:userid forHTTPHeaderField:@"user"];
    [urlRequest setValue:[UIDevice currentDevice].model forHTTPHeaderField:@"deviceType"];
    NSString *retrieveuuid = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"UUID"];
    
    [urlRequest setValue:retrieveuuid forHTTPHeaderField:@"device"];
    [urlRequest setValue:[[self getCurrentJson] objectForKey:@"id"]
      forHTTPHeaderField:@"exercise"];
    [urlRequest setValue:@"decode" forHTTPHeaderField:@"request"];
    
    NSString *req = [NSString stringWithFormat:@"%d",_reqid];
    
    //   NSLog(@"Req id %@ %d",req, _reqid);
    [urlRequest setValue:req forHTTPHeaderField:@"reqid"];
    _reqid++;
    
    // post the audio
    
    [urlRequest setHTTPBody:postData];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    
    // NSLog(@"posting to %@",_url);
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         dispatch_async(dispatch_get_main_queue(), ^{
             [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];
             [_recoFeedbackImage stopAnimating];
         });
         
         //  NSLog(@"Got back error %@",error);
         //  NSLog(@"Got back response %@",response);
         
         //    NSLog(@"response to post of audio...");
         if (error != nil) {
             NSLog(@"postAudio : Got error %@",error);
             dispatch_async(dispatch_get_main_queue(), ^{
                 if (error.code == NSURLErrorNotConnectedToInternet) {
                     [self setDisplayMessage:@"Make sure your wifi or cellular connection is on."];
                 }
                 else {
                     [self setDisplayMessage:@"Network connection problem, please try again."];
                 }
             });
             [self postEvent:error.localizedDescription widget:@"Record" type:@"Connection error"];
         }
         else {
             _responseData = data;
             [self performSelectorOnMainThread:@selector(connectionDidFinishLoading:)
                                    withObject:nil
                                 waitUntilDone:YES];
         }
     }];
    
    _startPost = CFAbsoluteTimeGetCurrent();
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:true];
}

- (void)addScoreDisplayConstraints:(UILabel *)toShow {
    for (UIView *v in [_scoreDisplayContainer subviews]) {
        [v removeFromSuperview];
    }
    [_scoreDisplayContainer addSubview:toShow];
    
    // height
    [_scoreDisplayContainer addConstraint:[NSLayoutConstraint
                                           constraintWithItem:toShow
                                           attribute:NSLayoutAttributeHeight
                                           relatedBy:NSLayoutRelationEqual
                                           toItem:_scoreDisplayContainer
                                           attribute:NSLayoutAttributeHeight
                                           multiplier:1.0
                                           constant:0.0]];
    
    [_scoreDisplayContainer addConstraint:[NSLayoutConstraint constraintWithItem:toShow
                                                                       attribute:NSLayoutAttributeCenterX
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:_scoreDisplayContainer
                                                                       attribute:NSLayoutAttributeCenterX
                                                                      multiplier:1
                                                                        constant:0]];
    
    
    [_scoreDisplayContainer addConstraint:[NSLayoutConstraint
                                           constraintWithItem:toShow
                                           attribute:NSLayoutAttributeBottom
                                           relatedBy:NSLayoutRelationEqual
                                           toItem:_scoreDisplayContainer
                                           attribute:NSLayoutAttributeBottom
                                           multiplier:1.0
                                           constant:0.0]];
    
    [_scoreDisplayContainer addConstraint:[NSLayoutConstraint
                                           constraintWithItem:toShow
                                           attribute:NSLayoutAttributeLeft
                                           relatedBy:NSLayoutRelationGreaterThanOrEqual
                                           toItem:_scoreDisplayContainer
                                           attribute:NSLayoutAttributeLeft
                                           multiplier:1.0
                                           constant:0.0]];
    
    
    [_scoreDisplayContainer addConstraint:[NSLayoutConstraint
                                           constraintWithItem:toShow
                                           attribute:NSLayoutAttributeRight
                                           relatedBy:NSLayoutRelationLessThanOrEqual
                                           toItem:_scoreDisplayContainer
                                           attribute:NSLayoutAttributeRight
                                           multiplier:1.0
                                           constant:0.0]];
}

- (void)setDisplayMessage:(NSString *) toUse {
    //NSLog(@"display %@",toUse);
    UILabel *toShow = [[UILabel alloc] init];
    [toShow setTranslatesAutoresizingMaskIntoConstraints:NO];
    toShow.text =toUse;
    [toShow setFont:[UIFont systemFontOfSize:24.0f]];
    toShow.adjustsFontSizeToFitWidth = YES;
    
    [self addScoreDisplayConstraints:toShow];
}

- (void)setIncorrectMessage:(NSString *) toUse {
    //NSLog(@"display %@",toUse);
    UILabel *toShow = [self getWordLabel:toUse score:0 wordFont:[UIFont systemFontOfSize:24]];
    toShow.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *singleFingerTap =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(playAudio:)];
    singleFingerTap.delegate = self;
    [toShow addGestureRecognizer:singleFingerTap];
    [self addScoreDisplayConstraints:toShow];
}

- (void)showScoreToUser:(NSDictionary *)json previousScore:(NSNumber *)previousScore {
    //   BOOL saidWord = [[json objectForKey:@"saidWord"] boolValue];
    BOOL correct = [[json objectForKey:@"isCorrect"] boolValue];
    NSString *valid = [json objectForKey:@"valid"];
    //NSNumber *overallScore = correct ? [json objectForKey:@"score"] : 0;
    NSNumber *overallScore = [json objectForKey:@"score"];
    
    if (![valid isEqualToString:@"OK"]) {
        NSLog(@"validity was %@",valid);
    }
    
    if ([valid rangeOfString:@"OK"].location != NSNotFound) {
        [self updateScoreDisplay:json];
    }
    else {
        if ([valid rangeOfString:@"MIC"].location != NSNotFound || [valid rangeOfString:@"TOO_QUIET"].location != NSNotFound) {
            [self setDisplayMessage:@"Please speak louder"];
        }
        else if ([valid rangeOfString:@"TOO_LOUD"].location != NSNotFound) {
            [self setDisplayMessage:@"Please speak softer"];
        }
        else if ([valid rangeOfString:@"SNR_TOO_LOW"].location != NSNotFound) {
            [self setDisplayMessage:@"Speaking too quietly or the room is too noisy."];
        }
        else {
            [self setDisplayMessage:[json objectForKey:@"valid"]];
        }
    }
    _scoreProgress.hidden = false;
    [_scoreProgress setProgress:[overallScore floatValue]];
    [_scoreProgress setProgressTintColor:[self getColor2:[overallScore floatValue]]];
    
    if (previousScore != nil) {
        [_scoreProgress setProgress:[previousScore floatValue]];
        [_scoreProgress setProgressTintColor:[self getColor2:[previousScore floatValue]]];
        [self performSelector:@selector(showProgressAnimated:) withObject:overallScore afterDelay:0.5];
    }
    else {
        [_scoreProgress setProgress:[overallScore floatValue]];
        [_scoreProgress setProgressTintColor:[self getColor2:[overallScore floatValue]]];
    }
    [_correctFeedback setImage:[UIImage imageNamed:correct ? @"checkmark32" : @"redx32"]];
    [_correctFeedback setHidden:false];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    CFAbsoluteTime diff = (now-_startPost);
    CFAbsoluteTime millis = diff * 1000;
    int iMillis = (int) millis;
    
    //  NSLog(@"connectionDidFinishLoading - round trip time was %f %d ",diff, iMillis);
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:_audioRecorder.url options:nil];
    double durationInSeconds = CMTimeGetSeconds(asset.duration);
    
    [self postEvent:[NSString stringWithFormat:@"round trip was %.2f sec for file of dur %.2f sec",diff,durationInSeconds]
             widget:[NSString stringWithFormat:@"rt %.2f",diff]
               type:[NSString stringWithFormat:@"file %.2f",durationInSeconds] ];
    
    NSError * error;
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:_responseData
                          options:NSJSONReadingMutableContainers
                          error:&error];
    
    if (error != nil) {
        NSLog(@"connectionDidFinishLoading - got error %@",error);
        // NSLog(@"data was %@",_responseData);
    }
    else {
        //  NSLog(@"JSON was %@",json);
    }
    //  NSLog(@"score was %@",overallScore);
    //     NSLog(@"correct was %@",[json objectForKey:@"isCorrect"]);
    //     NSLog(@"saidWord was %@",[json objectForKey:@"saidWord"]);
    NSString *exid = [json objectForKey:@"exid"];
    
    NSNumber *resultID = [json objectForKey:@"resultID"];
    
    // Post a RT value for the result id
    EAFEventPoster *poster = [[EAFEventPoster alloc] initWithURL:_url];
    NSString * roundTrip =[NSString stringWithFormat:@"%d",iMillis];
    //NSLog(@"connectionDidFinishLoading - roundTrip  %@",roundTrip);
    
    [poster postRT:[resultID stringValue] rtDur:roundTrip];
    
    //   NSLog(@"exid was %@",exid);
    NSNumber *score = [json objectForKey:@"score"];
    //   NSLog(@"score was %@ class %@",[json objectForKey:@"score"], [[json objectForKey:@"score"] class]);
    NSNumber *minusOne = [NSNumber numberWithInt:-1];
    //   NSLog(@"score was %@ vs %@",score, minusOne);
    if ([score isEqualToNumber:minusOne]) {
        [self setDisplayMessage:@"Server error, please report."];
        return;
    }
    
    NSNumber *previousScore;
    if (exid != nil) {
        previousScore = [_exToScore objectForKey:exid];
        BOOL saidWord = [[json objectForKey:@"saidWord"] boolValue];
        NSNumber *overallScore = saidWord ? [json objectForKey:@"score"] : 0;
        [_exToScore setValue:overallScore forKey:exid];
    }
    
    NSString *reqid = [json objectForKey:@"reqid"];
    
    //    NSLog(@"got back %@",reqid);
    if ([reqid intValue] < _reqid-1) {
        NSLog(@"json was %@",json);
        
        NSLog(@"discarding old response - got back %@ latest %d",reqid ,_reqid);
        return;
    }
    NSString *current = [[self getCurrentJson] objectForKey:@"id"];
    if (![exid isEqualToString:current]) {
        NSLog(@"response exid not same as current - got %@ vs expecting %@",exid,current );
        return;
    }
    
    [self showScoreToUser:json previousScore:previousScore];
}

- (void) showProgressAnimated:(NSNumber *)overallScore {
    [_scoreProgress setProgressTintColor:[self getColor2:[overallScore floatValue]]];
    [_scoreProgress setProgress:[overallScore floatValue] animated:true];//:[overallScore floatValue]];
}

- (NSArray *)reversedArray:(NSArray *) toReverse {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[toReverse count]];
    NSEnumerator *enumerator = [toReverse reverseObjectEnumerator];
    for (id element in enumerator) {
        [array addObject:element];
    }
    return array;
}

- (UILabel *)getWordLabel:(NSString *)word score:(NSNumber *)score wordFont:(UIFont *)wordFont {
    UILabel *wordLabel = [[UILabel alloc] init];
    //  NSLog(@"getWordLabel word %@",word);
    
    NSString *wordActually = word;
    if ([_language isEqualToString:@"English"]) {
        wordActually = [word lowercaseString];
    }
    NSMutableAttributedString *coloredWord = [[NSMutableAttributedString alloc] initWithString:wordActually];
    
    NSRange range = NSMakeRange(0, [coloredWord length]);
    
    // NSLog(@"score was %@ %f",scoreString,score);
    if ([score floatValue] > -0.1) {
        UIColor *color = [self getColor2:[score floatValue]];
        [coloredWord addAttribute:NSBackgroundColorAttributeName
                            value:color
                            range:range];
    }
    
    wordLabel.attributedText = coloredWord;
    wordLabel.font  = wordFont;
    
    //    if ([self isiPhone]// && [_foreignLang.text length] > 15
    //        ) {
    //        wordLabel.font  = wordFont;//[UIFont systemFontOfSize:24];
    //      //  int v = [wordLabel contentCompressionResistancePriorityForAxis:UILayoutConstraintAxisHorizontal];
    //     //   NSLog(@"got constraint %d",v);
    ////        NSLog(@"got constraint %f",[wordLabel contentHuggingPriorityForAxis:UILayoutConstraintAxisHorizontal] );
    //    }
    //    else {
    //
    //    }
    
    [wordLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    wordLabel.adjustsFontSizeToFitWidth=YES;
    return wordLabel;
}

BOOL addSpaces = false;

- (NSMutableAttributedString *)getColoredPhones:(NSString *)phoneToShow wend:(NSNumber *)wend wstart:(NSNumber *)wstart phoneAndScore:(NSArray *)phoneAndScore {
    // now mark the ranges in the string with colors
    
    NSMutableAttributedString *coloredPhones = [[NSMutableAttributedString alloc] initWithString:phoneToShow];
    
    int pstart = 0;
    for (NSDictionary *event in phoneAndScore) {
        NSString *phoneText = [event objectForKey:@"event"];
        if ([phoneText isEqualToString:@"sil"]) continue;
        
        NSNumber *pscore = [event objectForKey:@"score"];
        NSNumber *start  = [event objectForKey:@"start"];
        NSNumber *end    = [event objectForKey:@"end"];
        
        if ([start floatValue] >= [wstart floatValue] && [end floatValue] <= [wend floatValue]) {
            NSRange range = NSMakeRange(pstart, [phoneText length]);
            pstart += range.length + (addSpaces ? 1 : 0);
            float score = [pscore floatValue];
            UIColor *color = [self getColor2:score];
            //        NSLog(@"%@ %f %@ range at %lu length %lu", phoneText, score,color,(unsigned long)range.location,(unsigned long)range.length);
            [coloredPhones addAttribute:NSBackgroundColorAttributeName
                                  value:color
                                  range:range];
        }
        else {
            
        }
    }
    return coloredPhones;
}

// So here we set the background color for the phone to be highlight blue when the audio cursor
// is inside the phone region, otherwise, we use the scored color.
-  (NSMutableAttributedString *) markForegroundPhones:(NSNumber *)wend wstart:(NSNumber *)wstart
                                        phoneAndScore:(NSArray *)phoneAndScore
                                              current:(NSAttributedString *)current
                                                  now:(float) now
{
    // now mark the ranges in the string with colors
    NSMutableAttributedString *coloredPhones = [[NSMutableAttributedString alloc] initWithAttributedString:current];
    //   NSLog(@"current %d ",[current length]);
    
    UIColor *hColor = [EAFRecoFlashcardController colorFromHexString:@"#007AFF"];
    
    int pstart = 0;
    for (NSDictionary *event in phoneAndScore) {
        NSString *phoneText = [event objectForKey:@"event"];
        if ([phoneText isEqualToString:@"sil"]) continue;
        //      NSLog(@"phone %@ at %d",phoneText,pstart);
        
        NSNumber *start  = [event objectForKey:@"start"];
        NSNumber *end    = [event objectForKey:@"end"];
        
        if ([start floatValue] >= [wstart floatValue] && [end floatValue] <= [wend floatValue]) {
            NSRange range = NSMakeRange(pstart, [phoneText length]);
            //         NSLog(@"\tpstart %@ at %d %d",phoneText,pstart,i);
            pstart += range.length + (addSpaces ? 1 : 0);
            NSNumber *pscore = [event objectForKey:@"score"];
            
            if (now >= [start floatValue] && now < [end floatValue]) {
                //      NSLog(@"%f-%f in %f phone %@ range %@",[start floatValue],[end floatValue],now,phoneText,NSStringFromRange(range));
                [coloredPhones addAttribute:NSBackgroundColorAttributeName
                                      value:hColor
                                      range:range];
            }
            else {
                float score = [pscore floatValue];
                UIColor *color = [self getColor2:score];
                [coloredPhones addAttribute:NSBackgroundColorAttributeName
                                      value:color
                                      range:range];
            }
        }
    }
    return coloredPhones;
}

//- (BOOL)isRTL {
//    NSArray *rtl = [NSArray arrayWithObjects: @"Dari",
//                    @"Egyptian",
//                    @"EgyptianCandidate",
//                    @"Farsi",
//                    @"Levantine",
//                    @"MSA", @"Pashto1", @"Pashto2", @"Pashto3",  @"Sudanese",  @"Urdu",  nil];
//    BOOL isRTL = [rtl containsObject:_language];
//    return isRTL;
//}

- (void)addSingleTap:(UIView *)exampleView {
    UITapGestureRecognizer *singleFingerTap =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(playAudio:)];
    singleFingerTap.delegate = self;
    [exampleView addGestureRecognizer:singleFingerTap];
}

- (NSString *)getPhonesWithinWord:(NSNumber *)wend wstart:(NSNumber *)wstart phoneAndScore:(NSArray *)phoneAndScore {
    // get the phone sequence for the word
    NSString *phoneToShow = @"";
    for (NSDictionary *event in phoneAndScore) {
        NSString *phone = [event objectForKey:@"event"];
        if ([phone isEqualToString:@"sil"]) continue;
        NSNumber *start = [event objectForKey:@"start"];
        NSNumber *end   = [event objectForKey:@"end"];
        
        if ([start floatValue] >= [wstart floatValue] && [end floatValue] <= [wend floatValue]) {
            phoneToShow = [phoneToShow stringByAppendingString:phone];
            if (addSpaces) {
                phoneToShow = [phoneToShow stringByAppendingString:@" "];
            }
        }
    }
    return phoneToShow;
}

- (void)addPhoneLabelConstraints:(UIView *)exampleView phoneLabel:(UILabel *)phoneLabel {
    // left
    
    [exampleView addConstraint:[NSLayoutConstraint
                                constraintWithItem:phoneLabel
                                attribute:NSLayoutAttributeLeft
                                relatedBy:NSLayoutRelationEqual
                                toItem:exampleView
                                attribute:NSLayoutAttributeLeft
                                multiplier:1.0
                                constant:0.0]];
    
    // right
    
    [exampleView addConstraint:[NSLayoutConstraint
                                constraintWithItem:phoneLabel
                                attribute:NSLayoutAttributeRight
                                relatedBy:NSLayoutRelationEqual
                                toItem:exampleView
                                attribute:NSLayoutAttributeRight
                                multiplier:1.0
                                constant:0.0]];
    
    [exampleView addConstraint:[NSLayoutConstraint
                                constraintWithItem:phoneLabel
                                attribute:NSLayoutAttributeBottom
                                relatedBy:NSLayoutRelationEqual
                                toItem:exampleView
                                attribute:NSLayoutAttributeBottom
                                multiplier:1.0
                                constant:2.0]];
}

- (void)addWordLabelContstraints:(UIView *)exampleView wordLabel:(UILabel *)wordLabel {
    // top
    [exampleView addConstraint:[NSLayoutConstraint
                                constraintWithItem:wordLabel
                                attribute:NSLayoutAttributeTop
                                relatedBy:NSLayoutRelationEqual
                                toItem:exampleView
                                attribute:NSLayoutAttributeTop
                                multiplier:1.0
                                constant:0.0]];
    
    // left
    [exampleView addConstraint:[NSLayoutConstraint
                                constraintWithItem:wordLabel
                                attribute:NSLayoutAttributeLeft
                                relatedBy:NSLayoutRelationEqual
                                toItem:exampleView
                                attribute:NSLayoutAttributeLeft
                                multiplier:1.0
                                constant:0.0]];
    
    // right
    [exampleView addConstraint:[NSLayoutConstraint
                                constraintWithItem:wordLabel
                                attribute:NSLayoutAttributeRight
                                relatedBy:NSLayoutRelationEqual
                                toItem:exampleView
                                attribute:NSLayoutAttributeRight
                                multiplier:1.0
                                constant:0.0]];
}

- (UILabel *)getPhoneLabel:(BOOL)isRTL coloredPhones:(NSMutableAttributedString *)coloredPhones phoneFont:(UIFont *) phoneFont {
    UILabel *phoneLabel = [[UILabel alloc] init];
    phoneLabel.font = phoneFont;
    phoneLabel.adjustsFontSizeToFitWidth=YES;
    phoneLabel.textAlignment = isRTL ? NSTextAlignmentRight : NSTextAlignmentLeft;
    phoneLabel.attributedText = coloredPhones;
    [phoneLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    return phoneLabel;
}

- (UIFont *)getWordFont {
    float len = [NSNumber numberWithUnsignedLong:_foreignLang.text.length].floatValue;
    // NSLog(@"len %lu",(unsigned long)len);
    float slen = [self isiPhone] ? 10 : 20;
    float scale = slen/len;
    scale = fmin(1,scale);
    
    int largest  = [self isiPhone] ? 24 : 48;
    int smallest = [self isiPhone] ? 7  : 14;
    
    float newFont = smallest + floor((largest-smallest)*scale);
    // NSLog(@"getWordFont len %lu font is %f",(unsigned long)len,newFont);
    UIFont *wordFont = [UIFont systemFontOfSize:[NSNumber numberWithFloat:newFont].intValue];
    return wordFont;
}

// worries about RTL languages
- (void)updateScoreDisplay:(NSDictionary*) json {
    NSArray *wordAndScore  = [json objectForKey:@"WORD_TRANSCRIPT"];
    NSArray *phoneAndScore = [json objectForKey:@"PHONE_TRANSCRIPT"];
    
    //    NSLog(@"updateScoreDisplay size for words %lu",(unsigned long)wordAndScore.count);
    
    //    NSLog(@"word  json %@",wordAndScore);
    //    NSLog(@"phone json %@",phoneAndScore);
    for (UIView *v in [_scoreDisplayContainer subviews]) {
        [v removeFromSuperview];
    }
    
    UIFont *wordFont;
    wordFont = [self getWordFont];
    
    [_scoreDisplayContainer removeConstraints:_scoreDisplayContainer.constraints];
    _scoreDisplayContainer.translatesAutoresizingMaskIntoConstraints = NO;
    _scoreDisplayContainer.clipsToBounds = YES;
    
    UIView *leftView  = nil;
    UIView *rightView = nil;
    
    //BOOL isRTL = [self isRTL];
    
    if (_isRTL) {
        wordAndScore  = [self reversedArray:wordAndScore];
        if (!_showPhonesLTRAlways) {
            phoneAndScore = [self reversedArray:phoneAndScore];
        }
    }
    
    UIView *spacerLeft  = [[UIView alloc] init];
    UIView *spacerRight = [[UIView alloc] init];
    
    spacerLeft.translatesAutoresizingMaskIntoConstraints = NO;
    spacerRight.translatesAutoresizingMaskIntoConstraints = NO;
    
    [_scoreDisplayContainer addSubview:spacerLeft];
    [_scoreDisplayContainer addSubview:spacerRight];
    
    leftView = spacerLeft;
    
    // width of spacers on left and right are equal
    [_scoreDisplayContainer addConstraint:[NSLayoutConstraint
                                           constraintWithItem:spacerLeft
                                           attribute:NSLayoutAttributeWidth
                                           relatedBy:NSLayoutRelationEqual
                                           toItem:spacerRight
                                           attribute:NSLayoutAttributeWidth
                                           multiplier:1.0
                                           constant:0.0]];
    
    //right edge of right spacer
    [_scoreDisplayContainer addConstraint:[NSLayoutConstraint
                                           constraintWithItem:spacerRight
                                           attribute:NSLayoutAttributeRight
                                           relatedBy:NSLayoutRelationEqual
                                           toItem:_scoreDisplayContainer
                                           attribute:NSLayoutAttributeRight
                                           multiplier:1.0
                                           constant:0.0]];
    
    // left edge of left spacer
    [_scoreDisplayContainer addConstraint:[NSLayoutConstraint
                                           constraintWithItem:spacerLeft
                                           attribute:NSLayoutAttributeLeft
                                           relatedBy:NSLayoutRelationEqual
                                           toItem:_scoreDisplayContainer
                                           attribute:NSLayoutAttributeLeft
                                           multiplier:1.0
                                           constant:0.0]];
    _wordLabels  = [NSMutableArray new];
    _phoneLabels = [NSMutableArray new];
    _wordTranscript = wordAndScore;
    _phoneTranscript = phoneAndScore;
    // _phoneStarts = [NSMutableArray new];
    // _phoneEnds = [NSMutableArray new];
    
    for (NSDictionary *event in wordAndScore) {
        NSString *word = [event objectForKey:@"event"];
        if ([word isEqualToString:@"sil"] || [word isEqualToString:@"<s>"] || [word isEqualToString:@"</s>"]) continue;
        NSNumber *score = [event objectForKey:@"score"];//saidWord ? [event objectForKey:@"score"] : 0;
        NSNumber *wstart = [event objectForKey:@"start"];
        NSNumber *wend = [event objectForKey:@"end"];
        
        UIView *exampleView = [[UIView alloc] init];
        exampleView.translatesAutoresizingMaskIntoConstraints = NO;
        [_scoreDisplayContainer addSubview:exampleView];
        rightView = exampleView;
        [self addSingleTap:exampleView];
        
        //         NSLog(@"word is %@",word);
        // first example view constraints left side to left side of container
        // all - top to top of container
        // bottom to bottom of container
        // after first, left side is right side of previous container, with margin
        
        // upper part is word, lower is phones
        // upper has left, right top bound to container
        // upper bottom is half container height
        
        // lower has left, right bottom bound to container
        // lower has top that is equal to bottom of top or half container height
        
        // top
        
        [_scoreDisplayContainer addConstraint:[NSLayoutConstraint
                                               constraintWithItem:exampleView
                                               attribute:NSLayoutAttributeTop
                                               relatedBy:NSLayoutRelationEqual
                                               toItem:_scoreDisplayContainer
                                               attribute:NSLayoutAttributeTop
                                               multiplier:1.0
                                               constant:0.0]];
        
        // bottom
        [_scoreDisplayContainer addConstraint:[NSLayoutConstraint
                                               constraintWithItem:exampleView
                                               attribute:NSLayoutAttributeBottom
                                               relatedBy:NSLayoutRelationEqual
                                               toItem:_scoreDisplayContainer
                                               attribute:NSLayoutAttributeBottom
                                               multiplier:1.0
                                               constant:0.0]];
        
        // left - initial left view is the left spacer, but afterwards is the previous word view
        [_scoreDisplayContainer addConstraint:[NSLayoutConstraint
                                               constraintWithItem:exampleView
                                               attribute:NSLayoutAttributeLeft
                                               relatedBy:NSLayoutRelationEqual
                                               toItem:leftView
                                               attribute:NSLayoutAttributeRight
                                               multiplier:1.0
                                               constant:5.0]];
        leftView = exampleView;
        
        UILabel *wordLabel = [self getWordLabel:word score:score wordFont:wordFont];
        wordLabel.textAlignment = _isRTL ? NSTextAlignmentRight : NSTextAlignmentLeft;
        [_wordLabels addObject:wordLabel];
        
        [exampleView addSubview:wordLabel];
        
        [self addWordLabelContstraints:exampleView wordLabel:wordLabel];
        
        NSString *phoneToShow = [self getPhonesWithinWord:wend wstart:wstart phoneAndScore:phoneAndScore];
        //        NSLog(@"phone to show %@",phoneToShow);
        
        NSMutableAttributedString *coloredPhones = [self getColoredPhones:phoneToShow wend:wend wstart:wstart phoneAndScore:phoneAndScore];
        
        UILabel *phoneLabel = [self getPhoneLabel:_isRTL coloredPhones:coloredPhones phoneFont:wordFont];
        [_phoneLabels addObject:phoneLabel];
        
        [exampleView addSubview:phoneLabel];
        
        // top of the phone label is the bottom of the word
        [exampleView addConstraint:[NSLayoutConstraint
                                    constraintWithItem:phoneLabel
                                    attribute:NSLayoutAttributeTop
                                    relatedBy:NSLayoutRelationEqual
                                    toItem:wordLabel
                                    attribute:NSLayoutAttributeBottom
                                    multiplier:1.0
                                    constant:+2.0]];
        
        [self addPhoneLabelConstraints:exampleView phoneLabel:phoneLabel];
    }
    
    // if the alignment fails completely it can sometimes return no words at all.
    if (rightView != nil)  {
        // the right side of the last word is the same as the left side of the right side spacer
        [_scoreDisplayContainer addConstraint:[NSLayoutConstraint
                                               constraintWithItem:rightView
                                               attribute:NSLayoutAttributeRight
                                               relatedBy:NSLayoutRelationEqual
                                               toItem:spacerRight
                                               attribute:NSLayoutAttributeLeft
                                               multiplier:1.0
                                               constant:0.0]];
    }
    // TODO : consider how to make all the labels have the same font after being adjusted
    //    for (UILabel *word in wordLabels) {
    //        NSLog(@"Word %@ %@",word.text,word.font);
    //    }
}

- (UIColor *) getColor2:(float) score {
    if (score > 1.0) score = 1.0;
    if (score < 0)  score = 0;
    
    float red   = fmaxf(0,(255 - (fmaxf(0, score-0.5)*2*255)));
    float green = fminf(255, score*2*255);
    float blue  = 0;
    
    red /= 255;
    green /= 255;
    blue /= 255;
    
    return [UIColor colorWithRed:red green:green blue:blue alpha:1];
}

- (void)cacheAudio:(NSArray *)items
{
    NSMutableArray *paths = [[NSMutableArray alloc] init];
    NSMutableArray *rawPaths = [[NSMutableArray alloc] init];
    
    NSArray *fields = [NSArray arrayWithObjects:@"ref",@"mrr",@"msr",@"frr",@"fsr",@"ctmref",@"ctfref",@"ctref",nil];
    
    NSString *urlWithSlash = _url; //[NSString stringWithFormat:@"%@/",_url];
    for (NSDictionary *object in items) {
        for (NSString *id in fields) {
            NSString *refPath = [object objectForKey:id];
            
            if (refPath && refPath.length > 2) { //i.e. not NO
                //NSLog(@"adding %@ %@",id,refPath);
                
                refPath = [refPath stringByReplacingOccurrencesOfString:@".wav"
                                                             withString:@".mp3"];
                
                NSMutableString *mu = [NSMutableString stringWithString:refPath];
                [mu insertString:urlWithSlash atIndex:0];
                //  NSLog(@"cacheAudio %@ %@",mu,urlWithSlash);
                
                [paths addObject:mu];
                [rawPaths addObject:refPath];
            }
            else {
                //NSLog(@"skipping %@ %@",id,refPath);
            }
        }
    }
    
    NSLog(@"EAFRecoFlashcardController - Got get audio -- %@ ",_audioCache);
    
    [_audioCache goGetAudio:rawPaths paths:paths language:_language];
}

#pragma mark - Managing popovers

- (IBAction)showPopover:(id)sender
{
    // Set the sender to a UIButton.
    [_myAudioPlayer stopAudio];
    [self stopAutoPlay];
    
    // Present the popover from the button that was tapped in the detail view.
    [[MZFormSheetController appearance] setCornerRadius:20.0];
    // [[MZFormSheetBackgroundWindow appearance] setBackgroundColor:[UIColor clearColor]];
    //  [[MZFormSheetBackgroundWindow appearance] setBackgroundBlurEffect:YES];
    
    EAFContextPopupViewController *popupController = [self.storyboard instantiateViewControllerWithIdentifier:@"ContextPopover"];
    
    popupController.url = _url;
    popupController.language = _language;
    popupController.item = [[self getCurrentJson] objectForKey:@"fl"];
    popupController.fl = [[self getCurrentJson] objectForKey:@"ct"];
    popupController.en = [[self getCurrentJson] objectForKey:@"ctr"];
    popupController.mref  = [[self getCurrentJson] objectForKey:@"ctmref"];
    if (popupController.mref == nil) {
        popupController.mref  = [[self getCurrentJson] objectForKey:@"ctref"];
    }
    popupController.fref  = [[self getCurrentJson] objectForKey:@"ctfref"];
    
    //    BOOL isIPhone;
    //  isIPhone = [self isiPhone];
    
    MZFormSheetController *formSheet = [self isiPhone] ?
    //        [[MZFormSheetController alloc] initWithViewController:popupController] :
    [[MZFormSheetController alloc] initWithSize:CGSizeMake(300, 350) viewController:popupController] :
    [[MZFormSheetController alloc] initWithSize:CGSizeMake(500, 500) viewController:popupController];
    
    formSheet.transitionStyle = MZFormSheetTransitionStyleSlideFromTop;
    formSheet.shouldDismissOnBackgroundViewTap = YES;
    
    [formSheet presentAnimated:YES completionHandler:^(UIViewController *presentedFSViewController) {
        
    }];
    
    formSheet.didTapOnBackgroundViewCompletionHandler = ^(CGPoint location)
    {
        
    };
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    NSLog(@"Reco flashcard - Got segue!!! %@ %@ ", _chapterTitle, _currentChapter);
    @try {
        EAFScoreReportTabBarController *tabBarController = [segue destinationViewController];
        tabBarController.url = _url;
        
        EAFWordScoreTableViewController *wordReport = [[tabBarController viewControllers] objectAtIndex:0];
        wordReport.tabBarItem.image = [[UIImage imageNamed:@"rightAndWrong_26h-unselected"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        wordReport.tabBarItem.selectedImage = [[UIImage imageNamed:@"rightAndWrong_26h-selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        wordReport.language = _language;
        
        wordReport.chapterName = _chapterTitle;
        wordReport.chapterSelection = _currentChapter;
        
        wordReport.unitName = _unitTitle;
        wordReport.unitSelection = _currentUnit;
        
        wordReport.jsonItems = _jsonItems;
        wordReport.url = _url;
        
        NSMutableDictionary *exToFL = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *exToEnglish = [[NSMutableDictionary alloc] init];
        
        for (NSDictionary *jsonObject in _jsonItems) {
            NSString *id = [jsonObject objectForKey:@"id"];
            NSString *exercise = [jsonObject objectForKey:@"fl"];
            NSString *englishPhrases = [jsonObject objectForKey:@"en"];
            [exToFL setValue:exercise forKey:id];
            [exToEnglish setValue:englishPhrases forKey:id];
        }
        
        // NSLog(@"setting exToFl to %lu",(unsigned long)exToFL.count);
        wordReport.exToFL = exToFL;
        wordReport.exToEnglish = exToEnglish;
        
        EAFPhoneScoreTableViewController *phoneReport = [[tabBarController viewControllers] objectAtIndex:1];
        phoneReport.tabBarItem.selectedImage = [[UIImage imageNamed:@"checkAndEar.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        phoneReport.tabBarItem.image = [[UIImage imageNamed:@"ear-unselected_32.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        
        phoneReport.language = _language;
        phoneReport.chapterName = _chapterTitle;
        phoneReport.chapterSelection = _currentChapter;
        
        phoneReport.unitName = _unitTitle;
        phoneReport.unitSelection = _currentUnit;
        
        phoneReport.url = _url;
        phoneReport.isRTL = _isRTL;
    }
    @catch (NSException *exception)
    {
        // Print exception information
        NSLog( @"NSException caught" );
        NSLog( @"Name: %@", exception.name);
        NSLog( @"Reason: %@", exception.reason );
        return;
    }
}
@end
