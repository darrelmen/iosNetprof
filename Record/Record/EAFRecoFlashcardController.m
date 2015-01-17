//
//  EAFViewController.m
//  Record
//
//  Created by Ferme, Elizabeth - 0553 - MITLL on 4/2/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
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

@implementation UIProgressView (customView)
- (CGSize)sizeThatFits:(CGSize)size {
    CGSize newSize = CGSizeMake(self.frame.size.width, 9);
    return newSize;
}
@end

@interface EAFRecoFlashcardController ()

@property BButton *playingIcon;
@property NSString *flashcardPlayerStatusContext;

@property CFAbsoluteTime then2 ;
@property CFAbsoluteTime now;
@property int reqid;
@property NSMutableArray *audioRefs;
@property EAFAudioPlayer *myAudioPlayer;
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) AVSpeechSynthesizer *synthesizer;
@property NSTimer *autoAdvanceTimer;
@property NSTimeInterval autoAdvanceInterval;

@property CFAbsoluteTime startPost ;
@property UIBackgroundTaskIdentifier backgroundUpdateTask;
@end

@implementation EAFRecoFlashcardController

- (void)checkAndShowIntro
{
    NSString *userid = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"userid"];
    NSString *showedID = [NSString stringWithFormat:@"showedIntro_%@",userid];
    NSString *showedIntro = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:showedID];
    
    if (showedIntro == nil) {
        UIAlertView *info = [[UIAlertView alloc] initWithTitle:@"Swipe left/right/up/down to advance, tap to flip.\n\nPress and hold to record.\n\nTouch a word to hear audio.\n\nTouch Scores to see answers and sounds to work on." message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [info show];
        
        [SSKeychain setPassword:@"Yes"
                     forService:@"mitll.proFeedback.device" account:showedID];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"viewWillAppear --->");
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"viewDidAppear --->");
}

- (void)viewDidLoad
{
    NSLog(@"viewDidLoad --->");

    [super viewDidLoad];
    
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
    _playingIcon = [BButton awesomeButtonWithOnlyIcon:FAVolumeUp
                                                  type: BButtonTypeDefault
                                                 style:BButtonStyleBootstrapV3];
    _playingIcon.color = [UIColor colorWithWhite:1.0f alpha:0.0f];
    [_playingIcon setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];

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
        NSLog(@"----> No model for %@",_language);
        _recordButtonContainer.hidden = true;
    }
    else {
        _recordButtonContainer.hidden = false;
    }
    
    _scoreProgress.hidden = true;
    
    [_whatToShow setSelectedSegmentIndex:2];
    [_whatToShow setTitle:_language forSegmentAtIndex:1];
    if ([_language isEqualToString:@"English"]) {
        [_whatToShow setTitle:@"Def." forSegmentAtIndex:0];
    }
    else if ([_language isEqualToString:@"Sudanese"]) {
        [_whatToShow setTitle:@"Sudan" forSegmentAtIndex:1];
    }
    else if ([_language isEqualToString:@"CM"]) {
        [_whatToShow setTitle:@"Mandarin" forSegmentAtIndex:1];
    }
    
    _pageControl.transform = CGAffineTransformMakeRotation(M_PI_2);
    
    [_contextButton initWithFrame:CGRectMake(0.0f, 0.0f, 40.0f, 40.0f)
                    //        color:[UIColor colorWithWhite:1.0f alpha:0.0f]
                            color:[UIColor whiteColor]
                             style:BButtonStyleBootstrapV3
                              icon:FAQuoteLeft
                          fontSize:20.0f];
    
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
   // [super viewWillDisappear:animated];

    NSLog(@"- viewWillDisappear - Stop auto play.");

    [self stopAutoPlay];
   // [[UIApplication sharedApplication] endReceivingRemoteControlEvents];    
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent {
    NSLog(@"remoteControlReceivedWithEvent ---> %@ %ld",receivedEvent,receivedEvent.subtype);

    if (receivedEvent.type == UIEventTypeRemoteControl) {
        switch (receivedEvent.subtype) {
            case UIEventSubtypeRemoteControlPause:
                NSLog(@"Got paused  --->");

                [self stopTimer];
                [self unselectAutoPlay];
                break;
            case UIEventSubtypeRemoteControlPlay:
                NSLog(@"Got play  --->");
                _autoPlayButton.selected = true;
                _autoPlayButton.color = _autoPlayButton.selected ?[UIColor blueColor]:[UIColor whiteColor];

                [self respondToSwipe];
                break;
            case UIEventSubtypeRemoteControlTogglePlayPause:
                NSLog(@"Got play/pause track --->");
                break;
                
            case UIEventSubtypeRemoteControlPreviousTrack:
                NSLog(@"Got prev track --->");
                [self stopPlayingAudio];
                _index--;
                if (_index == -1) _index = _jsonItems.count  -1UL;
                [self respondToSwipe];
                break;
                
            case UIEventSubtypeRemoteControlNextTrack:
                NSLog(@"Got next track --->");
                [self stopPlayingAudio];
                [self doAutoAdvance];
                break;
                
            default:
                break;
        }
    }
}


- (void)postEvent:(NSString *) message widget:(NSString *) widget type:(NSString *) type {
    EAFEventPoster *poster = [[EAFEventPoster alloc] init];
    NSDictionary *jsonObject =[_jsonItems objectAtIndex:[self getItemIndex]];
    [poster postEvent:message exid:[jsonObject objectForKey:@"id"] lang:_language widget:widget widgetType:type];
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
    unsigned long toUse = [self getItemIndex];
    NSDictionary *jsonObject =[_jsonItems objectAtIndex:toUse];
    return jsonObject;
}

- (void)configureTextFields
{
    NSDictionary *jsonObject;
    jsonObject = [self getCurrentJson];
    NSString *exercise = [jsonObject objectForKey:@"fl"];
    NSString *englishPhrases = [jsonObject objectForKey:@"en"];
    exercise = [exercise stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    [_foreignLang setText:exercise];
    [_english setText:englishPhrases];
    
    _foreignLang.adjustsFontSizeToFitWidth=YES;
    _english.adjustsFontSizeToFitWidth=YES;
}

- (unsigned long)getItemIndex {
    unsigned long toUse = _index;
    if (
        //[_shuffleSwitch isOn]
        _shuffleButton.selected
        ) {
        //   NSLog(@"current %lu",_index);
        toUse = [[_randSequence objectAtIndex:_index] integerValue];
        //   NSLog(@"output %lu",toUse);
    }
    //else {
        //  NSLog(@"current %lu",_index);
   // }
    return toUse;
}

- (IBAction)gotGenderSelection:(id)sender {
    
    [SSKeychain setPassword:(_genderMaleSelector.selectedSegmentIndex == 0 ? @"Male":_genderMaleSelector.selectedSegmentIndex == 1 ? @"Female" : @"Both")
                     forService:@"mitll.proFeedback.device" account:@"audioGender"];
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

    [self removePlayObserver];
   
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
        //   NSLog(@"checking - audio on %@",audioOn);
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
    //NSLog(@"is slow %@",isSlow ? @"SLOW" :@"REGULAR");
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
        }
        else {
            if (hasFemaleReg) {
                refAudio =  [jsonObject objectForKey:@"frr"];
                [_audioRefs addObject: refAudio];
            }
        }
    }
    else {
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
    BOOL hasTwoGenders = (hasMaleReg || hasMaleSlow) && (hasFemaleReg || hasFemaleSlow);
    _genderMaleSelector.enabled = hasTwoGenders;
    [_genderMaleSelector setEnabled:(hasMaleReg || hasMaleSlow) forSegmentAtIndex:0];
    [_genderMaleSelector setEnabled:(hasFemaleReg || hasFemaleSlow) forSegmentAtIndex:1];
    [_genderMaleSelector setEnabled:hasTwoGenders forSegmentAtIndex:2];

    BOOL hasTwoSpeeds = (hasMaleReg || hasFemaleReg) && (hasMaleSlow || hasFemaleSlow);
    _speedButton.enabled = hasTwoSpeeds;
    
    if (refAudio != nil && ![refAudio isEqualToString:@"NO"] && _audioRefs.count == 0) {
        [_audioRefs addObject:refAudio];
    }
    
    if (_autoPlayButton.selected && _audioRefs.count > 1) {
        [_audioRefs removeLastObject];
    }
  //  NSLog(@"respondToSwipe after refAudio %@ and %@",refAudio,_audioRefs);
    
    NSString *flAtIndex = [jsonObject objectForKey:@"fl"];
    NSString *enAtIndex = [jsonObject objectForKey:@"en"];
    
    flAtIndex = [flAtIndex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    [_foreignLang setText:flAtIndex];
    [_english setText:enAtIndex];
    
    // todo : remove font foolishness here
    BOOL isIPhone = [[UIDevice currentDevice].model containsString:@"iPhone"];
    
    if (isIPhone && [enAtIndex length] > 15) {
        _english.font = [UIFont systemFontOfSize:24];
    }
    else {
        _english.font = [UIFont systemFontOfSize:isIPhone ? 32 :44];
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
    _myAudioPlayer.audioPaths = _audioRefs;
    if (_audioOnButton.selected &&   // volume on
        !preventPlayAudio &&
        showedIntro != nil) {
     
         NSLog(@"respondToSwipe first");

        
        if (showEnglish) {
            NSLog(@"respondToSwipe first - %d", _whatToShow.selectedSegmentIndex);
            if (_autoPlayButton.selected) {

            [self speakEnglish:false];
            }
        }
        else {
            [self playRefAudioIfAvailable];
        }
    }
    else {
        preventPlayAudio = false;
        if (_autoPlayButton.selected) {
            if (showEnglish) {
                NSLog(@"respondToSwipe sec");

                [self speakEnglish:false];
            }
            else {
                [self playRefAudioIfAvailable];
            }

        }
    }
}

- (IBAction)swipeRightDetected:(UISwipeGestureRecognizer *)sender {
    [self viewWillDisappear:true];
   
    _index--;
    if (_index == -1) _index = _jsonItems.count  -1UL;

    [self postEvent:@"swipeRight" widget:@"card" type:@"UIView"];
    [self respondToSwipe];
}

BOOL preventPlayAudio = false;
- (IBAction)swipeLeftDetected:(UISwipeGestureRecognizer *)sender {
    NSLog(@"swipeLeftDetected progress is %f", _progressThroughItems.progress);

    [self viewWillDisappear:true];
    
    _index++;
    BOOL onLast = _index == _jsonItems.count;
    if (onLast) {
        _index = 0;
        // TODO : get the sorted list and resort the items in incorrect first order
    }
   
    if (onLast) {
        preventPlayAudio = TRUE;
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
    }
    else {
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
    [utterance setRate:0.2f];

    if (!_audioOnButton.selected && !volumnOn) {
        utterance.volume = 0;
        NSLog(@"volume %f",utterance.volume);
    }
    else {
        //NSLog(@"normal volume %f",utterance.volume);
    }
    [_synthesizer speakUtterance:utterance];
}

- (IBAction)tapOnEnglish:(id)sender {
    [self stopPlayingAudio];

    [self speakEnglish:true];
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didPauseSpeechUtterance:(AVSpeechUtterance *)utterance {
    NSLog(@"recoflashcard : didPauseSpeechUtterance---");
    [self showSpeechEnded:true];//[utterance.speechString isEqualToString:_english.text]];
}

- (void)showSpeechEnded:(BOOL) isEnglish {
    if (isEnglish) {
        _english.textColor = [UIColor blackColor];
    }
    else {
        _foreignLang.textColor = [UIColor blackColor];
    }
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didContinueSpeechUtterance:(AVSpeechUtterance *)utterance {
    NSLog(@"recoflashcard : didContinueSpeechUtterance---");
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didCancelSpeechUtterance:(AVSpeechUtterance *)utterance {
    NSLog(@"recoflashcard : didCancelSpeechUtterance---");
    [self showSpeechEnded:true];//[utterance.speechString isEqualToString:_english.text]];
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didStartSpeechUtterance:(AVSpeechUtterance *)utterance
{
    NSLog(@"recoflashcard : didStartSpeechUtterance --- '%@'",utterance.speechString);
    
 //   _english.hidden = false;
    _pageControl.currentPage = 0;
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
    BOOL isEnglish = true;//![utterance.speechString isEqualToString:_foreignLang.text];
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
    [_synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    if ([self hasRefAudio]) {
        [_myAudioPlayer playRefAudio];
    }
}

- (IBAction)tapOnForeignDetected:(UITapGestureRecognizer *)sender{
    [self playRefAudioIfAvailable];

    EAFEventPoster *poster = [[EAFEventPoster alloc] init];
    NSDictionary *jsonObject =[_jsonItems objectAtIndex:[self getItemIndex]];
    [poster postEvent:[NSString stringWithFormat:@"playAudioTouch"] exid:[jsonObject objectForKey:@"id"] lang:_language widget:@"flText" widgetType:@"UILabel"];
}

- (void)hideAndShowText {
    long selected = [_whatToShow selectedSegmentIndex];
    NSLog(@"recoflashcard : hideAndShowText %ld", selected);
    if (selected == 0) { // english
        _foreignLang.hidden = true;
        _english.hidden = false;

        _pageControl.hidden = false;
        _pageControl.currentPage = 0;
        
        [_myAudioPlayer stopAudio];
    }
    else if (selected == 1) {  // fl
        _foreignLang.hidden = false;
        _english.hidden = true;

        _pageControl.hidden = false;
        _pageControl.currentPage = 1;
        
        [_synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    }
    else {
        _foreignLang.hidden = false;
        _english.hidden = false;
        _pageControl.hidden = true;
    }
}

// control showing english, fl phrase, or both
- (IBAction)whatToShowSelection:(id)sender {
    [self hideAndShowText];
    if (_autoPlayButton.selected) {
        [self doAutoAdvance];
    }
}

- (IBAction)speedSelection:(id)sender {
//    NSLog(@"\n\n\nGot speed selection...");
    _speedButton.selected = !_speedButton.selected;
    [SSKeychain setPassword:(_speedButton.selected ? @"Slow":@"Regular")
                 forService:@"mitll.proFeedback.device" account:@"audioSpeed"];

  //  _speedButton.imageView = _speedButton.selected ?[UIColor blueColor]:[UIColor whiteColor];
    _speedButton.backgroundColor = _speedButton.selected ?[UIColor blueColor]:[UIColor whiteColor];
    if (!_autoPlayButton.selected) {
        [self respondToSwipe];
    }
}

- (IBAction)audioOnSelection:(id)sender {
    [SSKeychain setPassword:(_audioOnButton.selected ? @"Yes":@"No")
                 forService:@"mitll.proFeedback.device" account:@"audioOn"];
    _audioOnButton.selected = !_audioOnButton.selected;
    _audioOnButton.color = _audioOnButton.selected ?[UIColor blueColor]:[UIColor whiteColor];

    _myAudioPlayer.volume = _audioOnButton.selected ? 1: 0;
    
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
    [self removePlayingAudioIcon];
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

// find first subview and remove the icon from it
// TODO : fix this for spacer case
// TODO : don't do floating icon - change foreground text color instead
- (void)removePlayingAudioIcon {
    NSArray *subviews = [_scoreDisplayContainer subviews];
    if (subviews.count > 0) {
        UIView *first = [subviews objectAtIndex:0];
        if (first.frame.size.height == 0 && subviews.count > 2) {
            first = [subviews objectAtIndex:2];
        //    NSLog(@"instead, removing playing icon from %@",first);
        }
        for (UIView *v in [first subviews]) {
            if (v == _playingIcon) {
                [v removeFromSuperview];
              //  NSLog(@"Removing playing icon from %@",first);
                break;
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
    NSLog(@"audioRecorderDidFinishRecording : file duration was %f vs gesture end %f diff %f",durationInSeconds, (gestureEnd-_then2), (gestureEnd-_then2)-durationInSeconds );
    
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
    }
}

- (void)audioRecorderEncodeErrorDidOccur:
(AVAudioRecorder *)recorder error:(NSError *)error
{
    NSLog(@"Encode Error occurred");
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Error recording..." message: @"Didn't record audio file." delegate: nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

- (void)removePlayObserver {   
    @try {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:[_player currentItem]];
        [_player removeObserver:self forKeyPath:@"status"];
    }
    @catch (NSException *exception) {
        // NSLog(@"initial create - got exception %@",exception.description);
    }
}

- (IBAction)gotTapInSuperview:(id)sender {
    NSLog(@" gotTapInSuperview");

    [self viewWillDisappear:true];
    long selected = [_whatToShow selectedSegmentIndex];
    if (selected == 0 || selected == 1) {
        [self flipCard];
    }
}

- (void)stopPlayingAudio {
    NSLog(@" stopPlayingAudio");

    if (_player) {
        [_player pause];
        [self removePlayObserver];
        [self removePlayingAudioHighlight];
    }
    [_myAudioPlayer stopAudio];
    [_synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
}

// OK, ref audio has finished playing, what next?
- (void)removePlayingAudioHighlight {
    if (_foreignLang.textColor == [UIColor blueColor]) {
        _foreignLang.textColor = [UIColor blackColor];
       // NSLog(@" removePlayingAudioHighlight");
    }
}

- (void)highlightFLWhilePlaying
{
    NSLog(@" highlightFLWhilePlaying - show fl");

//    _foreignLang.hidden = false;
    _foreignLang.textColor = [UIColor blueColor];
    _pageControl.currentPage = 1;
}

- (void)logError:(NSError *)error {
    NSLog(@"Domain:      %@", error.domain);
    NSLog(@"Error Code:  %ld", (long)error.code);
    NSLog(@"Description: %@", [error localizedDescription]);
    NSLog(@"Reason:      %@", [error localizedFailureReason]);
}

bool debugRecord = false;

- (IBAction)recordAudio:(id)sender {
    [self viewWillDisappear:true];

    _then2 = CFAbsoluteTimeGetCurrent();
    if (debugRecord) NSLog(@"recordAudio time = %f",_then2);
    
    [_myAudioPlayer stopAudio];
    EAFEventPoster *poster = [[EAFEventPoster alloc] init];
    NSDictionary *jsonObject =[_jsonItems objectAtIndex:[self getItemIndex]];
    [poster postEvent:[NSString stringWithFormat:@"record audio start"] exid:[jsonObject objectForKey:@"id"] lang:_language widget:@"record audio" widgetType:@"Button"];
    
    if (!_audioRecorder.recording)
    {
        if (debugRecord) NSLog(@"startRecordingFeedbackWithDelay time = %f",CFAbsoluteTimeGetCurrent());
        _english.textColor = [UIColor blackColor];
   
        for (UIView *v in [_scoreDisplayContainer subviews]) {
            [v removeFromSuperview];
        }
        
        NSError *error = nil;
        AVAudioSession *session = [AVAudioSession sharedInstance];
        
        [session setCategory:AVAudioSessionCategoryRecord error:nil];
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

- (void)flipCard {
    NSLog(@"flipCard");
    [self unselectAutoPlay];
    [self stopPlayingAudio];
    
    _pageControl.currentPage = _pageControl.currentPage == 0 ? 1 : 0;
    
    _foreignLang.hidden = !_foreignLang.hidden;
    _english.hidden = !_english.hidden;
    
    NSLog(@"flipCard fl hidden %@", _foreignLang.hidden  ? @"YES" :@"NO");
    NSLog(@"flipCard en hidden %@", _english.hidden  ? @"YES" :@"NO");
    
    if (_foreignLang.hidden && _english.hidden) {
        if (_whatToShow.selectedSegmentIndex == 0) {
            _english.hidden = false;
        }
        else if (_whatToShow.selectedSegmentIndex == 1) {
            _foreignLang.hidden = false;
        }
        else {
            _english.hidden = false;
            _foreignLang.hidden = false;
        }
    }
    if (_audioOnButton.selected) {
        if (!preventPlayAudio) {
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
- (IBAction)swipeUp:(UISwipeGestureRecognizer *)sender {
    NSLog(@"Got swipe up from %@",sender);
    
    CGPoint pt = [sender locationOfTouch:0 inView:self.view];
    NSLog(@"Got swipe up locationOfTouch %f, %f",pt.x, pt.y);
    
    CGPoint pt2 = [sender locationInView:self.view];
    
    NSLog(@"Got swipe up location in view %f, %f",pt2.x, pt2.y);
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    
    NSLog(@"Got swipe   %f, %f",screenWidth,screenHeight);
    
    if (screenHeight - pt2.y < 10) {
        NSLog(@"Got swipe IGNORING SWIPE, since control center swipe %f, %f",screenWidth,screenHeight);
    }
    else {
        
        long selected = [_whatToShow selectedSegmentIndex];
        if (selected == 0 || selected == 1) {
            [self flipCard];
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

double gestureStart;
double gestureEnd;
- (IBAction)longPressAction:(id)sender {
    if (_longPressGesture.state == UIGestureRecognizerStateBegan) {
        gestureStart = CFAbsoluteTimeGetCurrent();
        
        _recordButtonContainer.backgroundColor =[UIColor greenColor];
        _recordButton.enabled = NO;
        [_correctFeedback setHidden:true];
        _scoreProgress.hidden = true;

        [self setDisplayMessage:@""];

        [self recordAudio:nil];
    }
    else if (_longPressGesture.state == UIGestureRecognizerStateEnded) {
        _recordButtonContainer.backgroundColor =[UIColor whiteColor];
        _recordButton.enabled = YES;

        gestureEnd = CFAbsoluteTimeGetCurrent();
        if (debugRecord)  NSLog(@"longPressAction now  time = %f",gestureEnd);
        double gestureDiff = gestureEnd - gestureStart;
        
       // NSLog(@"diff %f",gestureDiff);
        if (gestureDiff < 0.4) {
            [self setDisplayMessage:@"Press and hold to record."];
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
        
        _audioPlayer = [[AVAudioPlayer alloc]
                        initWithContentsOfURL:_audioRecorder.url
                        error:&error];
        
        _audioPlayer.delegate = self;

        // add icon to first subview
        NSArray *subviews = [_scoreDisplayContainer subviews];
        if (subviews.count > 0) {
            UIView *first = [subviews objectAtIndex:0];
            if (first.frame.size.height == 0 && subviews.count > 2) {
                first = [subviews objectAtIndex:2];
               // NSLog(@"instead, adding playing icon to %@",first);
            }
            [first addSubview:_playingIcon];
            
          //  NSLog(@"Adding playing icon to %@",first);

        }
        else {
          //  NSLog(@"No subviews in %@",_scoreDisplayContainer);

        }

        if (error)
        {
            NSLog(@"Error: %@", [error localizedDescription]);
        } else {
            [_audioPlayer setVolume:3];  // TODO Valid???
         //   NSLog(@"volume %f",[_audioPlayer volume]);
            [_audioPlayer play];
        }

        [self postEvent:@"playUserAudio" widget:@"userScoreDisplay" type:@"UIView"];
   }
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
        if (_audioPlayer.playing) {
            [_audioPlayer stop];
        }
    }
}

//- (IBAction)gotValueChange:(id)sender {
//    BOOL value =
//    //[_shuffleSwitch isOn];
//    _shuffleButton.selected;
//    NSLog(@"gotValueChange Got shuffle event %@",value ? @"SELECTED" :@"NOT SELECTED");
//}

- (IBAction)stopRecordingWithDelay:sender {
    [NSTimer scheduledTimerWithTimeInterval:0.33
                                     target:self
                                   selector:@selector(stopAudio:)
                                   userInfo:nil
                                    repeats:NO];
}

- (IBAction)shuffleChange:(id)sender {
//    BOOL value =
//    //[_shuffleSwitch isOn];
//        _shuffleButton.selected;
    
    _shuffleButton.selected = !_shuffleButton.selected;
    _shuffleButton.color = _shuffleButton.selected ?[UIColor blueColor]:[UIColor whiteColor];

    //  NSLog(@"Got shuffle event %@",_shuffleButton.selected ? @"SELECTED" :@"NOT SELECTED");
    
    if (_shuffleButton.selected) {
        [self doShuffle];
    }
    [self respondToSwipe];
    
    EAFEventPoster *poster = [[EAFEventPoster alloc] init];
    NSDictionary *jsonObject =[_jsonItems objectAtIndex:[self getItemIndex]];
    [poster postEvent:[NSString stringWithFormat:@"shuffle"] exid:[jsonObject objectForKey:@"id"] lang:_language widget:@"shuffle" widgetType:@"UIRadio"];
    
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
// NOTE : not used right now since can't post UTF8 characters - see postAudio2
- (void)postAudio {
    // create request
    [_recoFeedbackImage startAnimating];
    
    NSData *postData = [NSData dataWithContentsOfURL:_audioRecorder.url];
    // NSLog(@"data %d",[postData length]);
    
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
    
    // NSLog(@"file length %@",postLength);
    NSString *baseurl = [NSString stringWithFormat:@"%@/scoreServlet", _url];
   //   NSLog(@"talking to %@",baseurl);
    
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
    
    NSURLConnection *connection = [NSURLConnection connectionWithRequest:urlRequest delegate:self];
    [connection start];
    
    _startPost = CFAbsoluteTimeGetCurrent();
    NSLog(@"posting to %@",_url);
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:true];
}

#pragma mark NSURLConnection Delegate Methods

NSInteger httpStatusCode;
NSString *statusCodeDisplay;
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // A response has been received, this is where we initialize the instance var you created
    // so that we can append data to it in the didReceiveData method
    // Furthermore, this method is called each time there is a redirect so reinitializing it
    // also serves to clear it
   
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *resp = (NSHTTPURLResponse *)response;
        httpStatusCode = resp.statusCode;
        statusCodeDisplay = [NSHTTPURLResponse localizedStringForStatusCode:httpStatusCode];
        if (httpStatusCode >= 400) {
            NSLog(@"didReceiveResponse error - %@",response);
        }
    }
    _responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // Append the new data to the instance variable you declared
 //   NSLog(@"didReceiveData ");
    [_responseData appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
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
    UILabel *toShow = [self getWordLabel:toUse score:0];
    toShow.userInteractionEnabled = YES;

    UITapGestureRecognizer *singleFingerTap =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(playAudio:)];
    singleFingerTap.delegate = self;
    [toShow addGestureRecognizer:singleFingerTap];
    [self addScoreDisplayConstraints:toShow];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // The request is complete and data has been received
    // You can parse the stuff in your instance variable now
    
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    CFAbsoluteTime diff = (now-_startPost);
    
    NSLog(@"round trip time was %f",diff);
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:_audioRecorder.url options:nil];
    double durationInSeconds = CMTimeGetSeconds(asset.duration);
    
    [self postEvent:[NSString stringWithFormat:@"round trip was %.2f sec for file of dur %.2f sec",diff,durationInSeconds] widget:[NSString stringWithFormat:@"rt %.2f",diff]  type:[NSString stringWithFormat:@"file %.2f",durationInSeconds] ];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];
    
    [_recoFeedbackImage stopAnimating];
  
    if (httpStatusCode != 200) {NSLog(@"got code %ld %@",(long)httpStatusCode, statusCodeDisplay);}
 
    if (httpStatusCode == 408) {
        [self setDisplayMessage:@"Please try again."];
        return;
    }
    else if (httpStatusCode >= 400 && httpStatusCode < 500) {
        [self setDisplayMessage:[NSString stringWithFormat:@"Network connection problem, please try again (%ld).",httpStatusCode]];
        return;
    }
    else if (httpStatusCode >= 500) {
        [self setDisplayMessage:[NSString stringWithFormat:@"Server error : %@",statusCodeDisplay]];
        return;
    }
    NSError * error;
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:_responseData
                          options:NSJSONReadingMutableContainers
                          error:&error];
    
    if (error != nil) {
        NSLog(@"connectionDidFinishLoading - got error %@",error);
    }
    
    NSNumber *overallScore = [json objectForKey:@"score"];
    BOOL correct = [[json objectForKey:@"isCorrect"] boolValue];
    BOOL saidWord = [[json objectForKey:@"saidWord"] boolValue];
    //  NSLog(@"score was %@",overallScore);
    //  NSLog(@"correct was %@",[json objectForKey:@"isCorrect"]);
    //  NSLog(@"saidWord was %@",[json objectForKey:@"saidWord"]);
    NSString *valid = [json objectForKey:@"valid"];
    NSString *exid = [json objectForKey:@"exid"];
    
    NSString *reqid = [json objectForKey:@"reqid"];

//    NSLog(@"got back %@",reqid);
    if ([reqid intValue] < _reqid-1) {
        NSLog(@"discarding old response - got back %@ latest %d",reqid ,_reqid);
        return;
    }
    NSString *current = [[self getCurrentJson] objectForKey:@"id"];
    if (![exid isEqualToString:current]) {
        NSLog(@"got %@ vs expecting %@",exid,current );
        return;
    }
    if (![valid isEqualToString:@"OK"]) {
        NSLog(@"validity was %@",valid);
    }
    
    if ([valid containsString:@"OK"]) {
        if (saidWord) {
            [self updateScoreDisplay:json];
        }
        else {
            [self setIncorrectMessage:_foreignLang.text];
        }
    }
    else {
        if ([valid containsString:@"MIC"] || [valid containsString:@"TOO_QUIET"]) {
            [self setDisplayMessage:@"Please speak louder"];
        }
        else if ([valid containsString:@"TOO_LOUD"]) {
            [self setDisplayMessage:@"Please speak softer"];
            
        }
        else {
            [self setDisplayMessage:[json objectForKey:@"valid"]];
        }
    }
    _scoreProgress.hidden = false;
    [_scoreProgress setProgress:[overallScore floatValue]];
    [_scoreProgress setProgressTintColor:[self getColor2:[overallScore floatValue]]];
    
    [_correctFeedback setImage:[UIImage imageNamed:correct ? @"checkmark32" : @"redx32"]];
    [_correctFeedback setHidden:false];
}

- (NSArray *)reversedArray:(NSArray *) toReverse {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[toReverse count]];
    NSEnumerator *enumerator = [toReverse reverseObjectEnumerator];
    for (id element in enumerator) {
        [array addObject:element];
    }
    return array;
}

- (UILabel *)getWordLabel:(NSString *)word score:(NSNumber *)score {
    UILabel *wordLabel = [[UILabel alloc] init];
    
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
    wordLabel.font = _foreignLang.font; // font sizes should match
    
    BOOL isIPhone = [[UIDevice currentDevice].model containsString:@"iPhone"];
    
    if (isIPhone && [_foreignLang.text length] > 15) {
        wordLabel.font  = [UIFont systemFontOfSize:24];
    }
    
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
        NSNumber *start = [event objectForKey:@"start"];
        NSNumber *end = [event objectForKey:@"end"];
        
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
    }
    return coloredPhones;
}

// worries about RTL languages
- (void)updateScoreDisplay:(NSDictionary*) json {
    NSArray *wordAndScore  = [json objectForKey:@"WORD_TRANSCRIPT"];
    NSArray *phoneAndScore = [json objectForKey:@"PHONE_TRANSCRIPT"];
    
    for (UIView *v in [_scoreDisplayContainer subviews]) {
        [v removeFromSuperview];
    }
    
    [_scoreDisplayContainer removeConstraints:_scoreDisplayContainer.constraints];
    _scoreDisplayContainer.translatesAutoresizingMaskIntoConstraints = NO;
    _scoreDisplayContainer.clipsToBounds = YES;

    UIView *leftView  = nil;
    UIView *rightView = nil;
    
    NSArray *rtl = [NSArray arrayWithObjects: @"Dari",
                  @"Egyptian",
                    @"Farsi",
                    @"Levantine",
                    @"MSA", @"Pashto1", @"Pashto2", @"Pashto3",  @"Sudanese",  @"Urdu",  nil];
    BOOL isRTL = [rtl containsObject:_language];
    
    if (isRTL) {
        wordAndScore  = [self reversedArray:wordAndScore];
        phoneAndScore = [self reversedArray:phoneAndScore];
    }
    
    UIView *spacerLeft  = [[UIView alloc] init];
    UIView *spacerRight = [[UIView alloc] init];

    spacerLeft.translatesAutoresizingMaskIntoConstraints = NO;
    spacerRight.translatesAutoresizingMaskIntoConstraints = NO;
   
    [_scoreDisplayContainer addSubview:spacerLeft];
    [_scoreDisplayContainer addSubview:spacerRight];

    leftView = spacerLeft;
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
    
    for (NSDictionary *event in wordAndScore) {
        NSString *word = [event objectForKey:@"event"];
        if ([word isEqualToString:@"sil"]) continue;
        NSNumber *score = [event objectForKey:@"score"];
        NSNumber *wstart = [event objectForKey:@"start"];
        NSNumber *wend = [event objectForKey:@"end"];
        
        UIView *exampleView = [[UIView alloc] init];
        exampleView.translatesAutoresizingMaskIntoConstraints = NO;
        [_scoreDisplayContainer addSubview:exampleView];
        rightView = exampleView;
        UITapGestureRecognizer *singleFingerTap =
        [[UITapGestureRecognizer alloc] initWithTarget:self
                                                action:@selector(playAudio:)];
        singleFingerTap.delegate = self;
        [exampleView addGestureRecognizer:singleFingerTap];
        
        // NSLog(@"word is %@",wordEntry);
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
        
        // left
        [_scoreDisplayContainer addConstraint:[NSLayoutConstraint
                                               constraintWithItem:exampleView
                                               attribute:NSLayoutAttributeLeft
                                               relatedBy:NSLayoutRelationEqual
                                               toItem:leftView
                                               attribute:NSLayoutAttributeRight
                                               multiplier:1.0
                                               constant:5.0]];
        leftView = exampleView;
        
        UILabel *wordLabel = [self getWordLabel:word score:score];
        wordLabel.textAlignment = isRTL ? NSTextAlignmentRight : NSTextAlignmentLeft;

        [exampleView addSubview:wordLabel];
        
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

        // get the phone sequence for the word
        NSString *phoneToShow = @"";
        for (NSDictionary *event in phoneAndScore) {
            NSString *phone = [event objectForKey:@"event"];
            if ([phone isEqualToString:@"sil"]) continue;
            NSNumber *start = [event objectForKey:@"start"];
            NSNumber *end = [event objectForKey:@"end"];
            
            if ([start floatValue] >= [wstart floatValue] && [end floatValue] <= [wend floatValue]) {
                phoneToShow = [phoneToShow stringByAppendingString:phone];
                if (addSpaces) {
                    phoneToShow = [phoneToShow stringByAppendingString:@" "];
                }
            }
        }
        
        NSMutableAttributedString *coloredPhones;
        coloredPhones = [self getColoredPhones:phoneToShow wend:wend wstart:wstart phoneAndScore:phoneAndScore];
        
        UILabel *phoneLabel = [[UILabel alloc] init];
        phoneLabel.font = [UIFont systemFontOfSize:24];
        phoneLabel.adjustsFontSizeToFitWidth=YES;

        phoneLabel.textAlignment = isRTL ? NSTextAlignmentRight : NSTextAlignmentLeft;
        
        phoneLabel.attributedText = coloredPhones;
        [phoneLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        [exampleView addSubview:phoneLabel];
        
        [exampleView addConstraint:[NSLayoutConstraint
                                    constraintWithItem:phoneLabel
                                    attribute:NSLayoutAttributeTop
                                    relatedBy:NSLayoutRelationEqual
                                    toItem:wordLabel
                                    attribute:NSLayoutAttributeBottom
                                    multiplier:1.0
                                    constant:+2.0]];
        
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
    
    [_scoreDisplayContainer addConstraint:[NSLayoutConstraint
                                           constraintWithItem:rightView
                                           attribute:NSLayoutAttributeRight
                                           relatedBy:NSLayoutRelationEqual
                                           toItem:spacerRight
                                           attribute:NSLayoutAttributeLeft
                                           multiplier:1.0
                                           constant:0.0]];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // The request has failed for some reason!
    // Check the error var
    [_recoFeedbackImage stopAnimating];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];
    
    NSLog(@"got %@",error);
    if ([[error localizedDescription] containsString:@"timed"]) {
        [self setDisplayMessage:@"Network connection problem, please try again."];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Connection problem" message: @"Couldn't connect to server." delegate: nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
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

#pragma mark - Managing popovers

- (IBAction)showPopover:(id)sender
{
    // Set the sender to a UIButton.
    [_myAudioPlayer stopAudio];
    [self viewWillDisappear:true];
    
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
    BOOL isIPhone = [[UIDevice currentDevice].model containsString:@"iPhone"];
    
    MZFormSheetController *formSheet = isIPhone ?
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
    EAFScoreReportTabBarController *tabBarController = [segue destinationViewController];
    
    EAFWordScoreTableViewController *wordReport = [[tabBarController viewControllers] objectAtIndex:0];
    wordReport.tabBarItem.image = [[UIImage imageNamed:@"rightAndWrong_26h"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
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
    phoneReport.tabBarItem.image = [[UIImage imageNamed:@"sounds.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    
    phoneReport.language = _language;
    phoneReport.chapterName = _chapterTitle;
    phoneReport.chapterSelection = _currentChapter;
    
    phoneReport.unitName = _unitTitle;
    phoneReport.unitSelection = _currentUnit;
    
    phoneReport.url = _url;
}
@end
