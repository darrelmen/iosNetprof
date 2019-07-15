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

#import "EAFGetSites.h"


#import "EAFMoreSelectionPopupViewController.h"

#import <sys/utsname.h> // import it in your header or implementation file.
#import <QuartzCore/QuartzCore.h>
#import "UIColor_netprofColors.h"

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
@property NSTimer *meteringTimer;
@property NSTimeInterval autoAdvanceInterval;
@property double gestureStart;
@property double gestureEnd;

@property CFAbsoluteTime startPost ;
@property UIBackgroundTaskIdentifier backgroundUpdateTask;
@property BOOL showPhonesLTRAlways;  // constant
@property UIPopoverController *popover;
@property EAFAudioCache *audioCache;
@property NSMutableDictionary *exToScore;
@property NSMutableDictionary *exToScoreJson;
@property NSMutableDictionary *exToRecordedAudio;
@property NSNumber *lastRecordedAudioExID;

@property NSArray *wordTranscript;
@property NSArray *phoneTranscript;
@property NSMutableArray *wordLabels;
@property NSMutableArray *phoneLabels;
@property BOOL preventPlayAudio;
@property EAFGetSites *siteGetter;

@property NSInteger languageSegmentIndex;
@property NSInteger voiceSegmentIndex;

@property BButton *shuffleBtn;
@property BButton *autoPlayButton;
@property UIButton *speedButton;
@property BButton *moreSelectButton;

@property UIInterfaceOrientation interfaceOrientation;

@property NSString *tlAtIndex;

@property BOOL timerStarted;
@property int timeRemainingMillis;
@property long sessionTimeStamp;
@property long lastSessionTimeStamp;
@property NSTimer *quizTimer;
@property NSTimer *slowContentTimer;
@property NSTimer *stopRecordingLaterTimer;
@property (strong, nonatomic) NSData *responseListData;

@property BOOL isPostingAudio;
@property UIAlertView *loadingContentAlert;
@property EAFEventPoster *poster;
@property BOOL addSpaces;

- (void)postAudio;

@end

@implementation EAFRecoFlashcardController

// GLOBAL CONSTANT!
//int const TIMEOUT = 15;

- (void)checkAndShowIntro
{
    NSString *userid = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"userid"];
    NSString *showedID = [NSString stringWithFormat:@"showedIntro_%@",userid];
    NSString *showedIntro = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:showedID];
    if (showedIntro == nil && [self notAQuiz]) {
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
    if (_listid != NULL) {
        if (_jsonItems == NULL) {
            [self askServerForJsonForList];
        }
    }
    if ([self isAQuiz] && [_exToScore count] == 0) {
        [self setTitle:@"Press and hold to record."];
    }
}

// view will appear
-(void)askServerForJsonForList {
    if (_siteGetter == NULL) {
        _siteGetter = [EAFGetSites new];
        
        if (_url == NULL) {
            _url = [_siteGetter getServerURL];
        }
    }
    NSString* baseurl =[NSString stringWithFormat:@"%@scoreServlet?request=CONTENT&list=%@", _url, _listid];
    NSLog(@"Reco : askServerForJsonForList url %@",baseurl);
    
    _sessionTimeStamp = -1;
    _lastSessionTimeStamp = -1;
    
    NSURL *url = [NSURL URLWithString:baseurl];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    
    [urlRequest setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    //    [urlRequest setTimeoutInterval:1];
    
    [urlRequest setHTTPMethod: @"GET"];
    [urlRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    [urlRequest setValue:[_projid stringValue] forHTTPHeaderField:@"projid"];
    NSLog(@"Reco projid = %@",_projid);
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:true];
    NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession] dataTaskWithRequest:urlRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
                                          //    [NSURLConnection sendAsynchronousRequest:urlRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
                                          {
                                              if (error != nil) {
                                                  NSLog(@"EAFRecoFlashcardController askServerForJsonForList Got error %@",error);
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                      [self connection:nil didFailWithError:error];
                                                  });
                                                  [self showConnectionError:error];
                                                  [self->_poster postError:urlRequest error:error];
                                              }
                                              else {
                                                  self->_responseListData = data;
                                                  NSLog(@"EAFRecoFlashcardController askServerForJsonForList Got data length %lu",(unsigned long)[data length]);
                                                  [self performSelectorOnMainThread:@selector(connectionDidFinishLoadingList:)
                                                                         withObject:nil
                                                                      waitUntilDone:YES];
                                              }
                                          }];
    
    [downloadTask resume];
    
    _loadingContentAlert = NULL;
    _slowContentTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(slowContentTimerFired) userInfo:nil repeats:NO];
}

- (void) slowContentTimerFired {
    _loadingContentAlert = [[UIAlertView alloc] initWithTitle:@"Fetching quiz.\nPlease Wait..." message:nil delegate:self cancelButtonTitle:nil otherButtonTitles: nil];
    [_loadingContentAlert show];
}

//- (void)postWarningEvent:(NSURLRequest *)request error:(NSError *)error {
//    [self postEvent:error.localizedDescription widget:@"WARNING" type:[NSString stringWithFormat:@"connection failure to %@", request]];
//}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // The request has failed for some reason!
    // Check the error var
    NSLog(@"Reco - Download content failed with %@",error);
    // _requestPending = false;
    // [[self tableView] reloadData];
    
    //  NSString *type = [NSString stringWithFormat:@"connection failure to %@", connection.currentRequest];
    [_poster postError:connection.currentRequest error:error];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];
}

- (void)dismissLoadingContentAlert {
    if (_loadingContentAlert != NULL) {
        [_loadingContentAlert dismissWithClickedButtonIndex:0 animated:true];
    }
}

- (void)connectionDidFinishLoadingList:(NSURLConnection *)connection {
    // The request is complete and data has been received
    [_slowContentTimer invalidate];
    [self dismissLoadingContentAlert];
    [self useListData:connection.currentRequest];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];
}

- (BOOL) useListData:(NSURLRequest *)currentRequest {
    NSError * error;
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:_responseListData
                          options:NSJSONReadingAllowFragments
                          error:&error];
    
    if (error) {
        NSLog(@"useListData error code %ldl = %@",(long)error.code, error.description);
        return false;
    }
    
    _jsonItems = [json objectForKey:@"content"];
    NSString *errMessage = [json objectForKey:@"ERROR"];
    if (errMessage != NULL && ![errMessage isEqualToString:@"OK"]) {
        NSLog(@"useListData got error %@",errMessage);
        NSString *msg= [NSString stringWithFormat:@"Network connection problem, please try again. Error : %@",errMessage];
        [self showError:msg];
        [self dismissLoadingContentAlert];
        [_poster postError:currentRequest error:error];
        
        return false;
    }
    else {
        [self cacheAudio];
        
        NSLog(@"Reco - useListData --- num json %lu ",(unsigned long)_jsonItems.count);
        
        if ([self isAQuiz]) {
            _timeRemainingMillis = _quizMinutes.intValue*60000;
            [self setTimeRemainingLabel];
        }
        
        [self respondToSwipe];
        _numQuizItems = [NSNumber numberWithUnsignedLong:_jsonItems.count];
        
        [self showQuizIntro];
        return true;
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    [self playRefAudioIfAvailable];
};

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    //NSLog(@"popoverControllerDidDismissPopover --->");
}

- (void)cacheAudio {
    if (_jsonItems != NULL) {
        [self performSelectorInBackground:@selector(cacheAudio:) withObject:_jsonItems];
    }
    else {
        NSLog(@" --- did not cache audio?");
    }
}

- (void)createAudioRecorder {
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
    [session setActive:true error:&error];
    [session requestRecordPermission:^(BOOL granted) {
        if (!granted) {
            NSLog(@"createAudioRecorder record permission not granted...");
            //            dispatch_async(dispatch_get_main_queue(), ^{
            //                self->_recordButton.enabled = FALSE;
            //            });
        }
    }];
    if (error)
    {
        NSLog(@"error: %@", [error localizedDescription]);
    }
    
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&setCategoryError];
    
    if(setCategoryError){
        NSLog(@"%@", [setCategoryError description]);
    }
    
    
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
        NSLog(@"error creating recorder: %@", [error localizedDescription]);
    }
    else {
        _audioRecorder.delegate = self;
        _audioRecorder.meteringEnabled = YES;
        [_audioRecorder prepareToRecord];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _sessionTimeStamp = -1;
    _lastSessionTimeStamp  = -1;
    
    CGFloat borderWidth = 1.0f;
    
    _outline.frame = CGRectInset(_outline.frame, -borderWidth, -borderWidth);
    
    // [UIColor colorWithRed:0 green:0 blue:0 alpha:0.25];
    
    _outline.layer.borderColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.25].CGColor;//[UIColor grayColor].CGColor;
    _outline.layer.borderWidth = borderWidth;
    
    _audioCache = [[EAFAudioCache alloc] init];
    _audioCache.language = _language;
    
    _addSpaces = ([[_language lowercaseString] isEqualToString:@"korean"]);
    
    _siteGetter = [EAFGetSites new];
    [_siteGetter getSites];
    // NSLog(@"RecoFlashcardController.viewDidLoad : getSites...");
    
    if (_url == NULL) {
        _url = [_siteGetter getServerURL];
    }
    
    BOOL noQuiz =([self notAQuiz]);
    
    [_timerProgress setHidden:noQuiz];
    [_timeRemainingLabel setHidden:noQuiz];
    
    [self cacheAudio];
    _showPhonesLTRAlways = true;
    _exToScore = [[NSMutableDictionary alloc] init];
    _exToScoreJson = [[NSMutableDictionary alloc] init];
    _exToRecordedAudio = [[NSMutableDictionary alloc] init];
    
    // Turn on remote control event delivery
    EAFAppDelegate *myDelegate = [UIApplication sharedApplication].delegate;
    
    myDelegate.recoController = self;
    
    // TODO: make this a parameter?
    _autoAdvanceInterval = 0.75;
    _reqid = 1;
    if (!self.synthesizer) {
        self.synthesizer = [[AVSpeechSynthesizer alloc] init];
        _synthesizer.delegate = self;
    }
    
    _myAudioPlayer = [[EAFAudioPlayer alloc] init];
    _myAudioPlayer.url = _url;
    _myAudioPlayer.language = _language;
    _myAudioPlayer.delegate = self;
    _poster = [self getPoster];
    _myAudioPlayer.poster = _poster;
    
    [[self view] sendSubviewToBack:_cardBackground];
    
    _cardBackground.layer.cornerRadius = 15.f;
    _cardBackground.layer.borderColor = [UIColor grayColor].CGColor;
    _cardBackground.layer.borderWidth = 2.0f;
    _cardBackground.layer.backgroundColor = [UIColor whiteColor].CGColor;
    [self view].backgroundColor = [UIColor npDarkBlue];
    _recordButtonContainer.layer.cornerRadius = 15.f;
    _recordButtonContainer.layer.borderWidth = 2.0f;
    _recordButtonContainer.layer.borderColor = [UIColor npRecordBorder].CGColor;
    _recordButton.tintColor = [UIColor npRecordBorder];
    _pageControl.tintColor = [UIColor npDarkBlue];
    _foreignLang.textColor = [UIColor npDarkBlue];
    _english.textColor = [UIColor npDarkBlue];
    
    // Set the audio file
    [self createAudioRecorder];
    
    _longPressGesture.minimumPressDuration = 0.05;
    
    
    //  [self checkAvailableMics];
    [self configureTextFields];
    
    [_scoreProgress setTintColor:[UIColor npLightBlue]];
    [_scoreProgress setTrackTintColor:[UIColor whiteColor]];
    [_scoreProgress setProgressTintColor:[UIColor greenColor]];
    
    _scoreProgress.layer.cornerRadius = 3.f;
    _scoreProgress.layer.borderWidth = 1.0f;
    _scoreProgress.layer.borderColor = [UIColor grayColor].CGColor;
    
    [_correctFeedback setHidden:true];
    [_answerAudioOn setHidden:true];
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playAudio:)];
    singleTap.numberOfTapsRequired = 1;
    _answerAudioOn.userInteractionEnabled = YES;
    [_answerAudioOn addGestureRecognizer:singleTap];
    
    
    _scoreProgress.hidden = true;
    _progressThroughItems.progressTintColor = [UIColor npLightYellow];
    
    _pageControl.transform = CGAffineTransformMakeRotation(M_PI_2);
    
    [_contextButton initWithFrame:CGRectMake(0.0f, 0.0f, 40.0f, 40.0f)
                            color:[UIColor whiteColor]
                            style:BButtonStyleBootstrapV3
                             icon:FAQuoteLeft
                         fontSize:20.0f];
    if ([self isiPad]) {
        _contextButton.titleLabel.text = @" sentence ";
        [_contextButton addAwesomeIcon:FAQuoteLeft beforeTitle:true];
    }
    _contextButton.color = [UIColor npLightBlue];
    
    NSString *ct = [[self getCurrentJson] objectForKey:@"ct"];
    _contextButton.hidden = (ct == nil || ct.length == 0);
    
    
    
    NSString *audioOn = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"audioOn"];
    NSLog(@"viewDidLoad audio on %@",audioOn);
    if (audioOn != nil) {
        _isAudioOnSelected = [audioOn isEqualToString:@"Yes"];
    }
    else {
        _isAudioOnSelected = NO;
    }
    
    _myAudioPlayer.volume = _isAudioOnSelected ? 1: 0;
    
    _languageSegmentIndex = 2;  // initial value is show both - enum better?
    _voiceSegmentIndex = 0;
    
    _selectionToolbar=[[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, 10, 10)];
    
    _moreSelection = [[MoreSelection alloc]initWithLanguageIndex:_languageSegmentIndex withVoiceIndex:_voiceSegmentIndex];
    
    [self setupToolBar];
    
    if (_jsonItems != NULL) {
        [self respondToSwipe];
    }
    
    [self checkAndShowIntro];
    
    
    UIBarButtonItem *scoreShow = [[UIBarButtonItem alloc]
                                  initWithTitle:@"Score"
                                  style:UIBarButtonItemStylePlain
                                  target:self
                                  action:@selector(showScores:)];
    self.navigationItem.rightBarButtonItem = scoreShow;
    
    
    
    if (![self notAQuiz]) {
        self.navigationItem.rightBarButtonItem.enabled = false;
        [_selectionToolbar setHidden:true];
    }
    
    //    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    //    [[NSNotificationCenter defaultCenter] addObserver:self
    //                             selector:@selector(orientationChanged:)
    //                            name:UIDeviceOrientationDidChangeNotification
    //                            object:[UIDevice currentDevice]];
}

- (void) showQuizIntro {
    NSString *min = @"minutes";
    if (_quizMinutes.intValue == 1) min = @"minute";
    NSString *advance = [NSString stringWithFormat:@"Scores above %@ advance automatically.\n", _minScoreToAdvance];
    if (_minScoreToAdvance.intValue == 0) advance = @"";
    NSString *postLength = [NSString stringWithFormat:@"You have %@ %@ to complete %@ items.\n%@If you finish with time remaining, it's OK to go back.\nSwipe to skip an item or go back.",_quizMinutes,min,_numQuizItems,advance];
    
    //    NSString *rememberedFirst = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"firstName"];
    //    NSString *rememberedLast = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"lastName"];
    NSString *rememberedUserID = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"chosenUserID"];
    
    // NSString *welcome = [NSString stringWithFormat:@"Welcome %@ %@",rememberedFirst,rememberedLast];
    NSString *welcome = [NSString stringWithFormat:@"Welcome %@!",rememberedUserID];
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:welcome
                                                                   message:postLength
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              if (self->_quizTimer == NULL && [self isAQuiz]) {  // start the timer!
                                                                  [self startQuiz];
                                                              }
                                                          }];
    
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void) showError:(NSString *) msg {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Network error"
                                                                   message:msg
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}

//-(void)orientationChanged:(NSNotification*)notification{
//   
//    NSLayoutConstraint *height;
//    CGFloat constData = 0.0;
//    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
//    if (UIDeviceOrientationIsLandscape(deviceOrientation) &&
//        !self.isShowingLandscapeView)
//    {
//        self.isShowingLandscapeView = YES;
//    }
//    else if (UIDeviceOrientationIsPortrait(deviceOrientation) &&
//             self.isShowingLandscapeView)
//    {
//        self.isShowingLandscapeView = NO;
//    }
//    
//    if (self.previousOrientation != self.isShowingLandscapeView){
//        if (self.isShowingLandscapeView){
//            NSLog(@"Orientation Change Occur: Landscape Mode");
//            constData = self.view.bounds.size.height * 0.2;
//        }
//        else {
//            NSLog(@"Orientation Change Occur: Portrait Mode");
//            constData = self.view.bounds.size.height * 0.4;
//        }
//        
//    }
//    
//    self.previousOrientation = self.isShowingLandscapeView;


//   [_selectionToolbar setTranslatesAutoresizingMaskIntoConstraints: NO];


//    if(CGRectGetWidth(self.view.bounds) < CGRectGetHeight(self.view.bounds))
//    {
//       CGFloat  constData = self.view.bounds.size.height * 0.2;
//         height = [NSLayoutConstraint constraintWithItem:_selectionToolbar attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:constData];
//        [self setupToolBar:height];
//        NSLog(@"Portrait is -- %@", height);
//   
//    } else {
//       CGFloat  constData = self.view.bounds.size.height * 0.1;
//         height = [NSLayoutConstraint constraintWithItem:_selectionToolbar attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:25];
//         [self setupToolBar:height];
//         NSLog(@"Landscape is -- %@", height);
//    }


//   [self updateOrientation];
//}


-(void)setupToolBar {
    _selectionToolbar.layer.backgroundColor =  [UIColor whiteColor].CGColor;
    [_selectionToolbar setTranslatesAutoresizingMaskIntoConstraints: NO];
    [self.view addSubview:_selectionToolbar];
    _selectionToolbar.barTintColor = [UIColor whiteColor];
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    _shuffleBtn = [BButton awesomeButtonWithOnlyIcon:FARandom color:[UIColor npLightBlue] style:BButtonStyleBootstrapV3];
    [self createButtonForiPhoneiPad:_shuffleBtn];
    
    [_shuffleBtn addTarget:self action:@selector(shuffle:) forControlEvents:UIControlEventTouchUpInside];
    //   [_shuffleBtn sizeToFit];
    UIBarButtonItem *shuffleBarItem = [[UIBarButtonItem alloc]	initWithCustomView:_shuffleBtn];
    
    _autoPlayButton = [BButton awesomeButtonWithOnlyIcon:FAPlay color:[UIColor npLightBlue] style:BButtonStyleBootstrapV3];
    [self createButtonForiPhoneiPad:_autoPlayButton];
    
    [_autoPlayButton addTarget:self action:@selector(autoPlaySelected:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *playBarItem = [[UIBarButtonItem alloc] initWithCustomView:_autoPlayButton];
    
    _speedButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _speedButton.layer.cornerRadius = 4;
    _speedButton.clipsToBounds = YES;
    _speedButton.layer.borderColor = [UIColor npLightBlueBorder].CGColor;
    _speedButton.layer.borderWidth = 1.0f;
    [_speedButton setImage:[UIImage imageNamed:@"turtle"] forState:UIControlStateNormal];
    [_speedButton setImage:[UIImage imageNamed:@"turtle_selected"] forState:UIControlStateSelected];
    [_speedButton setBackgroundColor:[UIColor npLightBlue]];
    
    
    if([self isiPhone]){
        _speedButton.frame=CGRectMake(0.0, 0.0, self.view.bounds.size.height * 0.1, self.view.bounds.size.height * 0.1);
        // _speedButton.frame=CGRectMake(0.0, 0.0, 55, 55);
        //   _speedButton.frame=CGRectMake(0.0, 0.0,self.view.bounds.size.height * 0.12 - 5, self.view.bounds.size.height * 0.12 -5);
        
    } else {
        _speedButton.frame=CGRectMake(0.0, 0.0, 160, 160);
    }
    
    [_speedButton addTarget:self action:@selector(speedSelection:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *speedBarItem = [[UIBarButtonItem alloc] initWithCustomView:_speedButton];
    
    _moreSelectButton = [BButton awesomeButtonWithOnlyIcon:FAEllipsisV color:[UIColor npLightBlue] style:BButtonStyleBootstrapV3];
    [self createButtonForiPhoneiPad:_moreSelectButton];
    
    [_moreSelectButton addTarget:self action:@selector(ShowMoreSelectPopup:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *moreBarItem = [[UIBarButtonItem alloc] initWithCustomView:_moreSelectButton];
    
    
    
    NSArray *toolBarItems = [NSArray arrayWithObjects: flexibleSpace, shuffleBarItem, playBarItem, speedBarItem, moreBarItem, flexibleSpace, nil];
    [_selectionToolbar setItems: toolBarItems animated:NO];
    
    
    NSLayoutConstraint *left = [NSLayoutConstraint constraintWithItem:_selectionToolbar attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeading multiplier:1 constant:0];
    
    NSLayoutConstraint *right = [NSLayoutConstraint constraintWithItem:_selectionToolbar attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1 constant:0];
    
    NSLayoutConstraint *top = [NSLayoutConstraint constraintWithItem:_selectionToolbar attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_cardBackground attribute:NSLayoutAttributeBottom multiplier:1 constant:10];
    
    
    NSLayoutConstraint *bottom = [NSLayoutConstraint constraintWithItem:_selectionToolbar attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
    CGFloat constData = 0.0;
    //  _interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if([self isiPhone]){
        constData = self.view.bounds.size.height * 0.12;
    } else {
        // constData = self.view.bounds.size.height * 0.2;
        constData = 180.0;
    }
    NSLayoutConstraint  *height = [NSLayoutConstraint constraintWithItem:_selectionToolbar attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:constData];
    //_selectionToolbar.backgroundColor = [UIColor colorWithRed:3/255.0 green:99/255.0 blue:148/255.0 alpha:1.0];
    [self.view addConstraints:@[left, right, top, bottom, height]];
    
}
-(void)createButtonForiPhoneiPad:(BButton *)button{
    if([self isiPhone]){
        //  button.frame=CGRectMake(0.0, 0.0, 55, 55);
        button.frame=CGRectMake(0.0, 0.0, self.view.bounds.size.height * 0.1, self.view.bounds.size.height * 0.1);
        button.titleLabel.font = [UIFont fontAwesomeFontOfSize:30];
        
    } else {
        button.frame=CGRectMake(0.0, 0.0, 160, 160);
        button.titleLabel.font = [UIFont fontAwesomeFontOfSize:80];
    }
}

- (IBAction)shuffle:(id)sender {
    _shuffleBtn.selected = !_shuffleBtn.selected;
    _shuffleBtn.color = _shuffleBtn.selected ?[UIColor npDarkBlue]:[UIColor npLightBlue];
    
    if (_shuffleBtn.selected) {
        [self doShuffle];
        [self respondToSwipe];
    }
    [self postEvent:@"shuffle" widget:@"shuffle" type:@"BButton"];
}

-(IBAction)showScores:(id)sender{
    [self stopPlayingAudio];
    [self postEvent:@"showScoresClick" widget:@"showScores" type:@"Button"];
    [self performSegueWithIdentifier:@"goToReport" sender:self];
}

-(void) getSelection:(MoreSelection *)selection{
    _moreSelection = selection;
    _languageSegmentIndex = _moreSelection.languageIndex;
    _voiceSegmentIndex = _moreSelection.voiceIndex;
    _isAudioOnSelected = _moreSelection.isAudioSelected;
    _identityRestoreID = _moreSelection.identityRestorationID;
    [self whatToShowSelect];
    [self gotGenderSelect];
    [self audioOnSelection];
    _moreSelectButton.selected = !_moreSelectButton.selected;
    _moreSelectButton.color = _moreSelectButton.selected ?[UIColor npDarkBlue]:[UIColor npLightBlue];
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
    _autoPlayButton.color = _autoPlayButton.selected ?[UIColor npDarkBlue]:[UIColor npLightBlue];
    [self stopTimer];
}

- (void)stopAutoPlay {
    [self unselectAutoPlay];
    [self stopPlayingAudio];
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    NSLog(@"- viewWillDisappear - Stop auto play.");
    
    if (_quizTimer != NULL) {
        [self stopQuiz];
    }
    
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
                _autoPlayButton.color = _autoPlayButton.selected ?[UIColor npDarkBlue]:[UIColor npLightBlue];
                
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
    //    NSLog(@"postEvent id       %@", id);
    //    NSLog(@"postEvent widget   %@", widget);
    //    NSLog(@"postEvent type     %@", type);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_poster postEvent:message exid:[NSString stringWithFormat:@"%@",[self getCurrentExID]] widget:widget widgetType:type];
    });
}

- (EAFEventPoster*)getPoster {
    return [[EAFEventPoster alloc] initWithURL:_url projid:[self getProjectID]];
}

- (id) getProjectID {
    if (_projid == NULL) {
        //    NSLog(@"getProjectID lang %@",_language);
        return [_siteGetter.nameToProjectID objectForKey:_language];
    }
    else {
        return _projid;
    }
}

- (id) getProjectLanguage {
    return [_siteGetter.nameToLanguage objectForKey:_language];
}

- (IBAction)showScoresClick:(id)sender {
    [self stopPlayingAudio];
    [self postEvent:@"showScoresClick" widget:@"showScores" type:@"Button"];
    [self performSegueWithIdentifier:@"goToReport" sender:self];
}

// deprecated
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
    //  NSLog(@"There are %u data sources for port :\"%@\"", (unsigned)[builtInMicPort.dataSources count], builtInMicPort);
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
    
    //NSLog(@"scaleFont font is %f",newFont);
    
    // [labelToScale setFont:[UIFont systemFontOfSize:[NSNumber numberWithFloat:newFont].intValue]];
    [labelToScale setFont:[UIFont fontWithName:@"Arial" size:[NSNumber numberWithFloat:newFont].intValue]];
}

- (NSString *)trim:(NSString *)exercise
{
    return [exercise stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (void)configureTextFields
{
    NSDictionary *jsonObject = [self getCurrentJson];
    long selected = _languageSegmentIndex;
    if (selected == 3) {
        NSString *exercise       = [jsonObject objectForKey:@"fl"];
        [self hideWithDashes:exercise];
    }
    else {
        [self setForeignLang];
    }
    
    NSString *englishPhrases = [jsonObject objectForKey:@"en"];
    [_english setText:englishPhrases];
    
    // TODO : do we need these???
    _foreignLang.adjustsFontSizeToFitWidth=YES;
    _foreignLang.minimumScaleFactor=0.1;
    
    _english.adjustsFontSizeToFitWidth=YES;
    _english.minimumScaleFactor=0.1;
    
    //    _tl.adjustsFontSizeToFitWidth=YES;
    //    _tl.minimumScaleFactor=0.1;
    
    if ([self isiPad]) {
        [_foreignLang setFont:[UIFont fontWithName:@"Arial" size:52]];
        //      [_tl setFont:[UIFont fontWithName:@"Arial" size:44]];
        // [_foreignLang setFont:[UIFont systemFontOfSize:52]];
        //        NSLog(@"font size is %@",_foreignLang.font);
    }
}

- (unsigned long)getItemIndex {
    unsigned long toUse = _index;
    if (_shuffleBtn.selected) {
        toUse = [[_randSequence objectAtIndex:_index] integerValue];
    }
    return toUse;
}

-(void)gotGenderSelect{
    NSString *genderSelect = _voiceSegmentIndex == 0 ? @"Male":_voiceSegmentIndex == 1 ? @"Female" : @"Both";
    
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
    /*
     _genderMaleSelector.selectedSegmentIndex = [audioGender isEqualToString:@"Male"] ? 0:[audioGender isEqualToString:@"Female"]?1:2;
     */
    _voiceSegmentIndex = [audioGender isEqualToString:@"Male"] ? 0:[audioGender isEqualToString:@"Female"]?1:2;
}

// so if we swipe while the ref audio is playing, remove the observer that will tell us when it's complete
- (void)respondToSwipe {
    // NSLog(@"respondToSwipe - %ld",_index);
    
    long jsonItemCount = (long) _jsonItems.count;
    
    _progressThroughItems.progress = ((float) _index+1) /(float) _jsonItems.count;
    
    NSString *jsonItemCountStr = [NSString stringWithFormat:@"%ld",jsonItemCount];
    
    _progressNum.text = [NSString stringWithFormat:@"%ld  / %ld", _index + 1, jsonItemCount];
    _progressNum.textColor = [UIColor npLightBlue];
    _timeRemainingLabel.textColor = [UIColor npLightBlue];
    
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:_progressNum.text];
    [str addAttribute:NSForegroundColorAttributeName value:[UIColor npLightBlue] range:NSMakeRange(0,[jsonItemCountStr length])];
    _progressNum.attributedText = str;
    
    [_progressNum setFont:[UIFont fontWithName:@"Arial" size:16]];
    
    [self hideAndShowText];
    
    //   [self removePlayObserver];
    
    if ([self hasRefAudio]) {
        NSLog(@"respondToSwipe stop audio - %ld",_index);
        // [self postEvent:@"stop audio since has ref audio..." widget:@"respondToSwipe" type:@"Button"];
        [_myAudioPlayer stopAudio];
    }
    
    [_synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    [_recoFeedbackImage stopAnimating];
    
    [_correctFeedback setHidden:true];
    _answerAudioOn.hidden=TRUE;
    [_scoreProgress     setProgress:0 ];
    
    // fade in the english!
    self->_english.alpha = 0.0;
    
    float delay = _showSentences ? 1.5:0.5;
    [UIView animateWithDuration:0.5 delay:delay options:UIViewAnimationOptionCurveLinear  animations:^{
        //code with animation
        self->_english.alpha = 1.0;
    } completion:^(BOOL finished) {
        //code for completion
    }];
    
    [self setGenderSelector];
    
    NSDictionary *jsonObject =[self getCurrentJson] ;
    
    NSString *refAudio=@"";
    
    if ([[jsonObject objectForKey:@"ref"] isKindOfClass:[NSString class]]) {
        refAudio = [jsonObject objectForKey:@"ref"];
    }
    else {
        refAudio = [jsonObject objectForKey:@"ctmref"];
    }
    
    
    NSString *test =  [jsonObject objectForKey:@"msr"];
    BOOL hasMaleSlow = (test != NULL && ![test isEqualToString:@"NO"]);
    
    NSString *maleRegToUse = _showSentences ? @"ctmref":@"mrr";
    NSString *femaleRegToUse = _showSentences ? @"ctfref":@"frr";
    
    test =  [jsonObject objectForKey:maleRegToUse];
    BOOL hasMaleReg = (test != NULL && ![test isEqualToString:@"NO"]);
    
    test =  [jsonObject objectForKey:@"fsr"];
    BOOL hasFemaleSlow = (test != NULL && ![test isEqualToString:@"NO"]);
    
    if (_showSentences) {
        test =  [jsonObject objectForKey:@"ctfref"];
    }
    else {
        test =  [jsonObject objectForKey:femaleRegToUse];
    }
    
    BOOL hasFemaleReg = (test != NULL && ![test isEqualToString:@"NO"]);
    
    long selectedGender = _voiceSegmentIndex;
    _audioRefs = [[NSMutableArray alloc] init];
    NSString *audioSpeed = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"audioSpeed"];
    BOOL isSlow = (audioSpeed     != NULL) && [audioSpeed isEqualToString:@"Slow"];
    
    //    NSLog(@"speed is %@",isSlow ? @"SLOW" :@"REGULAR");
    //    NSLog(@"male slow %@",hasMaleSlow ? @"YES" :@"NO");
    //    NSLog(@"male reg  %@",hasMaleReg ? @"YES" :@"NO");
    //    NSLog(@"selected gender is %ld",selectedGender);
    //    NSLog(@"ref is %@",refAudio);
    //    NSLog(@"msr is %@",test);
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
                    refAudio = [jsonObject objectForKey:maleRegToUse];
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
                    refAudio =  [jsonObject objectForKey:femaleRegToUse];
                    [_audioRefs addObject: refAudio];
                }
                else if (hasMaleReg && refAudio == nil) { // fall back
                    refAudio = [jsonObject objectForKey:maleRegToUse];
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
                    refAudio = [jsonObject objectForKey:maleRegToUse];
                    [_audioRefs addObject: refAudio];
                }
                if (hasFemaleReg) {
                    refAudio =  [jsonObject objectForKey:femaleRegToUse];
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
                    refAudio = [jsonObject objectForKey:maleRegToUse];
                }
                else if (hasFemaleReg && refAudio == nil) {
                    refAudio = [jsonObject objectForKey:femaleRegToUse];
                }
            }
            
        }
        else {
            if (hasMaleReg) {
                refAudio = [jsonObject objectForKey:maleRegToUse];
                [_audioRefs addObject: refAudio];
            }
            if (hasFemaleReg) {
                refAudio =  [jsonObject objectForKey:femaleRegToUse];
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
    _moreSelection.hasTwoGenders = hasTwoGenders;
    _moreSelection.hasMaleReg = hasMaleReg;
    _moreSelection.hasMaleSlow = hasMaleSlow;
    _moreSelection.hasFemaleReg = hasFemaleReg;
    _moreSelection.hasFemaleSlow = hasFemaleSlow;
    /*
     _genderMaleSelector.enabled = hasTwoGenders;
     [_genderMaleSelector setEnabled:(hasMaleReg || hasMaleSlow) forSegmentAtIndex:0];
     [_genderMaleSelector setEnabled:(hasFemaleReg || hasFemaleSlow) forSegmentAtIndex:1];
     [_genderMaleSelector setEnabled:hasTwoGenders forSegmentAtIndex:2];
     */
    
    BOOL hasTwoSpeeds = (hasMaleReg || hasFemaleReg) && (hasMaleSlow || hasFemaleSlow);
    _speedButton.enabled = hasTwoSpeeds;
    
    if (audioSpeed != nil && (hasMaleSlow || hasFemaleSlow)) {
        //   NSLog(@"checking - audio on %@",audioSpeed);
        _speedButton.selected = [audioSpeed isEqualToString:@"Slow"];
        _speedButton.backgroundColor = _speedButton.selected ?[UIColor npDarkBlue]:[UIColor npLightBlue];
        _speedButton.layer.borderColor = _speedButton.selected ? [UIColor npDarkBlueBorder].CGColor : [UIColor npLightBlueBorder].CGColor;
    }
    
    if (refAudio != nil && ![refAudio isEqualToString:@"NO"] && _audioRefs.count == 0) {
        //        NSLog(@"respondToSwipe adding refAudio %@",refAudio);
        [_audioRefs addObject:refAudio];
    }
    
    if (_autoPlayButton.selected && _audioRefs.count > 1) {
        [_audioRefs removeLastObject];
    }
    NSLog(@"respondToSwipe after refAudio %@ and %@",refAudio,_audioRefs);
    
    //  [self postEvent:[NSString stringWithFormat:@"EAFReco : found refAudio %@ and %@",refAudio,_audioRefs] widget:@"respondToSwipe" type:@"Button"];
    
    NSString *flAtIndex = [jsonObject objectForKey:@"fl"];
    NSString *enAtIndex = [jsonObject objectForKey:@"en"];
    _tlAtIndex = [jsonObject objectForKey:@"tl"];
    
    flAtIndex = [self trim:flAtIndex];
    _tlAtIndex = [self trim:_tlAtIndex];
    
    //NSLog(@"respondToSwipe _languageSegmentIndex %ld",(long)_languageSegmentIndex);
    
    if (_languageSegmentIndex == 3) {
        [self hideWithDashes:flAtIndex];
    }
    else {
        [self setForeignLangWith:flAtIndex];
        if([_tlAtIndex length] != 0){
            [_tl setText:_tlAtIndex];
        } else {
            _tl.hidden = YES;
        }
    }
    
    [_english setText:[self clean39:enAtIndex]];
    
    // so somehow we have to manually scale the font based on the length of the text, wish I could figure out how to not do this
    BOOL isIPhone = [self isiPhone];
    int minTextLength = _showSentences ? 20:10;
    int maxFont  = 48;
    
    if (isIPhone) {
        int maxEFont = 40;
        
        NSString *dev =[self deviceName];
        
        BOOL issmall = [dev rangeOfString:@"iPhone4"].location != NSNotFound;
        if (issmall) {
            maxFont = 30;
            maxEFont = 30;
        }
        
        [self scaleFont:flAtIndex labelToScale:_foreignLang largest:maxFont slen:minTextLength smallest:14];
        [self scaleFont:_tlAtIndex labelToScale:_tl largest:maxFont slen:minTextLength smallest:14];
        
        //     CGRect rect = [_english.text boundingRectWithSize:_english.bounds.size options:NSStringDrawingTruncatesLastVisibleLine attributes:nil context:nil];
        //   NSLog(@"Got rect %@",rect);
        //     NSLog(@"%@ vs %@", NSStringFromCGRect(rect), NSStringFromCGRect(_english.bounds));
        
        [self scaleFont:enAtIndex labelToScale:_english     largest:maxEFont slen:minTextLength smallest:12];
    } else {
        [self scaleFont:enAtIndex labelToScale:_english     largest:maxFont slen:minTextLength smallest:32];
        [self scaleFont:_tlAtIndex labelToScale:_tl     largest:maxFont slen:minTextLength smallest:32];
    }
    
    for (UIView *v in [_scoreDisplayContainer subviews]) {
        [v removeFromSuperview];
    }
    _scoreProgress.hidden = true;
    _myAudioPlayer.audioPaths = _audioRefs;
    
    NSString *userid = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"userid"];
    NSString *showedID = [NSString stringWithFormat:@"showedIntro_%@",userid];
    NSString *showedIntro = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:showedID];
    
    BOOL showEnglish = _languageSegmentIndex == 0;
    
    // [self postEvent:@"EAFReco : about to think about playing audio..." widget:@"respondToSwipe" type:@"Button"];
    
    // complicated...
    if(_playAudio) {
        //  [self postEvent:@"EAFReco : try to play ref audio b/c of quiz" widget:@"respondToSwipe" type:@"Button"];
        [self playRefAudioIfAvailable];
    }
    else if (_isAudioOnSelected && !_preventPlayAudio && showedIntro != nil) {
        
        //         NSLog(@"respondToSwipe first");
        if (showEnglish) {
            //   NSLog(@"respondToSwipe first - %ld", (long)_whatToShow.selectedSegmentIndex);
            //   [self postEvent:@"EAFReco : 1 try to speak english" widget:@"respondToSwipe" type:@"Button"];
            if (_autoPlayButton.selected) {
                [self speakEnglish:false];
            }
            else {
                [self postEvent:@"EAFReco : not speaking english" widget:@"respondToSwipe" type:@"Button"];
            }
        }
        else {
            //    [self postEvent:@"EAFReco : 1 try to play ref audio" widget:@"respondToSwipe" type:@"Button"];
            [self playRefAudioIfAvailable];
        }
    }
    else {
        _preventPlayAudio = false;
        if (_autoPlayButton.selected) {
            if (showEnglish) {
                //   [self postEvent:@"EAFReco : 2 try to speak english" widget:@"respondToSwipe" type:@"Button"];
                [self speakEnglish:false];
            }
            else {
                //  [self postEvent:@"EAFReco : 2 try to play ref audio" widget:@"respondToSwipe" type:@"Button"];
                [self playRefAudioIfAvailable];
            }
        }
        else {
            //   [self postEvent:@"EAFReco : not playing ref audio" widget:@"respondToSwipe" type:@"Button"];
        }
    }
    
    NSDictionary *prevScore= [_exToScoreJson objectForKey: [self getCurrentExID]];
    if (prevScore != NULL) {
        [self showScoreToUser:prevScore previousScore:NULL];
    }
    
    //   [self postEvent:@"EAFReco : exit..." widget:@"respondToSwipe" type:@"Button"];
    
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
    if (_index == -1) {
        _index = _jsonItems.count  -1UL;
    }
    
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
        // NSLog(@"OK index is %ld",_index);
        // TODO : get the sorted list and resort the items in incorrect first order
    }
    
    if (onLast) {
        // [self postEvent:@"on last so prevent play..." widget:@"swipeLeftDetected" type:@"UIView"];
        _preventPlayAudio = TRUE;
    }
    
    [self postEvent:@"swipeLeft" widget:@"card" type:@"UIView"];
    
    if (onLast) {
        if ([self notAQuiz]) {
            [self showScoresClick:nil];
            [((EAFItemTableViewController*)_itemViewController) askServerForJson];
        }
        else {
            [self respondToSwipe];
        }
    }
    else {
        [self respondToSwipe];
    }
}

- (IBAction)autoPlaySelected:(id)sender {
    _autoPlayButton.selected = !_autoPlayButton.selected;
    _autoPlayButton.color = _autoPlayButton.selected ?[UIColor npDarkBlue]:[UIColor npLightBlue];
    
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
    /*
     if (!_audioOnButton.selected && !volumnOn) {
     */
    if (!_isAudioOnSelected && !volumnOn) {
        utterance.volume = 0;
        NSLog(@"volume %f",utterance.volume);
    }
    //else {
    //NSLog(@"normal volume %f",utterance.volume);
    //}
    [_synthesizer speakUtterance:utterance];
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didPauseSpeechUtterance:(AVSpeechUtterance *)utterance {
    NSLog(@"recoflashcard : didPauseSpeechUtterance---");
    [self showSpeechEnded:true];
}

- (void)showSpeechEnded:(BOOL) isEnglish {
    _english.textColor = [UIColor npDarkBlue];
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
    _english.textColor = [UIColor npMedPurple];
}

NSLayoutConstraint *meteringConstraint;
NSLayoutConstraint *peakConstraint;
-(void) doMeteringUpdate
{
    [_audioRecorder updateMeters];
    float peak   =  [_audioRecorder peakPowerForChannel:0];
    float average = [_audioRecorder averagePowerForChannel:0];
    
    float minDB = -50.0;
    
    if (peak < minDB) {
        // NSLog(@"peak min capped from %f", peak);
        peak = minDB;
    }
    
    //    if (average == -120) {
    //        [self setDisplayMessage:@"Please allow recording."];  // kinda wasteful....
    //    }
    
    if (average < minDB) {
        // NSLog(@"average min capped from %f", average);
        average = minDB;
    }
    
    if (average > -6) {
        // NSLog(@"average yellow %f", average);
        [_metering setBackgroundColor:[UIColor yellowColor]];
    }
    else {
        BOOL isGreen = [_metering backgroundColor] == [UIColor greenColor];
        if (!isGreen) {
            [_metering setBackgroundColor:[UIColor greenColor]];
            //     NSLog(@"average set normal color %f", average);
        }
    }
    
    if (peak > -2) {
        // NSLog(@"average red %f", average);
        [_peak setBackgroundColor:[UIColor redColor]];
    }
    else if (peak > -6) {
        //  NSLog(@"average yellow %f", average);
        [_peak setBackgroundColor:[UIColor yellowColor]];
    }
    else {
        BOOL isGreen = [_peak backgroundColor] == [UIColor blackColor];
        if (!isGreen) {
            [_peak setBackgroundColor:[UIColor blackColor]];
            //     NSLog(@"average set normal color %f", average);
        }
    }
    
    // 0-> -6 yellow
    
    average = (average*(-50.0f/minDB))-minDB;
    peak    = (peak*(-50.0f/minDB))-minDB;
    [self updateMeteringConstraint:average];
    [self updatePeakConstraint:peak];
}

// when autoplay is active, automatically go to next item...
- (void)doAutoAdvance
{
    [self endBackgroundUpdateTask];
    
    _index++;
    NSLog(@"recoflashcard : doAutoAdvance %ld",_index);
    
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
        if (_languageSegmentIndex == 0) { // english first, so play fl
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

- (BOOL)notAQuiz {
    return _quizMinutes == NULL;
}

- (BOOL)isAQuiz {
    return _quizMinutes != NULL;
}

// deals with missing audio...?
- (void)playRefAudioIfAvailable {
    // NSLog(@"playRefAudioIfAvailable play ref if avail");
    
    NSString *current = [self getCurrentExID];
    [_synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    if ([self hasRefAudio]) {
        // NSLog(@"\tplay ref if avail");
        if ([self notAQuiz]) {
            //[self postEvent:[NSString stringWithFormat:@"EAFReco :  not a quiz - has ref audio for exid %@",current] widget:@"playRefAudioIfAvailable" type:@"Button"];
            
            [_myAudioPlayer playRefAudio];
        }
        else if (_playAudio) {
            NSLog(@"\t\tplay first ref if avail");
            //  [self postEvent:[NSString stringWithFormat:@"EAFReco :  quiz just play first ref for exid %@",current] widget:@"playRefAudioIfAvailable" type:@"Button"];
            
            [_myAudioPlayer playFirstRefAudio];
        }
    }
    else {
        [self postEvent:[NSString stringWithFormat:@"EAFReco :  no ref audio for exid %@",current] widget:@"playRefAudioIfAvailable" type:@"Button"];
        NSLog(@"HUH? no ref audio exid %@",current);
    }
}

- (IBAction)tapOnForeignDetected:(UITapGestureRecognizer *)sender{
    _myAudioPlayer.volume = 1;
    NSLog(@"foreign lang taped");
    [self playRefAudioIfAvailable];
    [self postEvent:@"playAudioTouchForeign" widget:_english.text type:@"UILabel"];
}

- (IBAction)tapOnEnglishDetected:(id)sender {
    NSLog(@"tap on english---");
    [self postEvent:@"playAudioTouchEnglish" widget:_english.text type:@"UILabel"];
    [self stopPlayingAudio];
    [self speakEnglish:true];
}

- (IBAction)tapOnTlDetected:(id)sender {
    NSLog(@"TL Pinyin taped");
    if([_tlAtIndex length] != 0){
        [self playRefAudioIfAvailable];
        [self postEvent:@"playAudioTouchTransliteration" widget:_english.text type:@"UILabel"];
    }
}

- (void)hideWithDashes:(NSString *)exercise {
    NSString *trim = [self trim:exercise];
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[^\\s]" options:NSRegularExpressionCaseInsensitive error:&error];
    NSString *modifiedString = [regex stringByReplacingMatchesInString:trim options:0 range:NSMakeRange(0, [trim length]) withTemplate:@"-"];
    
    [_foreignLang setText:modifiedString];
    [_tl setText:@""];
}

- (void)hideAndShowText {
    long selected = _languageSegmentIndex;
    // NSLog(@"recoflashcard : hideAndShowText %ld", selected);
    if (selected == 0) { // english
        _foreignLang.hidden = true;
        _tl.hidden = true;
        _english.hidden = false;
        _pageControl.hidden = false;
        _pageControl.currentPage = 0;
        NSLog(@"recoflashcard : hideAndShowText - stop audio %ld", selected);
        [_myAudioPlayer stopAudio];
        [self setForeignLang];
    }
    else if (selected == 1) {  // fl
        _foreignLang.hidden = false;
        _tl.hidden = false;
        _english.hidden = true;
        _pageControl.hidden = false;
        _pageControl.currentPage = 1;
        
        [self setForeignLang];
        [_synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    }
    else if (selected == 2){
        _foreignLang.hidden = false;
        _tl.hidden = false;
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

- (NSString *)clean39:(NSString *)exercise {
    return [exercise stringByReplacingOccurrencesOfString:@"&#39;" withString:@"'"];
}

- (NSMutableAttributedString *)getTextWithAudioIcon:(NSString *)toShow {
    NSTextAttachment *imageAttachment = [[NSTextAttachment alloc] init];
    imageAttachment.image = [UIImage imageNamed:@"audioOn"];
    
    CGFloat imageOffsetY = +10.0;
    BOOL isRTL =  [_siteGetter.rtlLanguages containsObject:_language];
    
    CGFloat imageOffsetX = isRTL? -5.0 : +5.0;
    CGFloat height = imageAttachment.image.size.height*0.8;
    
    // stringBoundingBox.height-height,
    imageAttachment.bounds = CGRectMake(imageOffsetX, imageOffsetY, imageAttachment.image.size.width*0.8, height);
    NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:imageAttachment];
    NSMutableAttributedString *completeText= [[NSMutableAttributedString alloc] initWithString:@""];
    NSMutableAttributedString *textAfterIcon= [[NSMutableAttributedString alloc] initWithString:toShow];
    [completeText appendAttributedString:textAfterIcon];
    [completeText appendAttributedString:attachmentString];
    return completeText;
}

- (void)setForeignLangWith:(NSString *)exercise {
    NSString *toShow = [self trim:[self clean39:exercise]];
    if (([self isAQuiz] && _playAudio) || ([self notAQuiz] && _isAudioOnSelected)) {
        _foreignLang.attributedText=[self getTextWithAudioIcon:toShow];
    }
    else {
        _foreignLang.text=toShow;
    }
}

- (void)setForeignLang {
    if ([_jsonItems count] > 0) {
        NSDictionary *jsonObject = [self getCurrentJson];
        NSString *exercise       = [jsonObject objectForKey:@"fl"];
        if (exercise != nil) {
            [self setForeignLangWith:exercise];
        }
    }
}

-(void)whatToShowSelect{
    [self hideAndShowText];
    
    long selected = _languageSegmentIndex;
    
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
    _speedButton.layer.borderColor = _speedButton.selected ? [UIColor npDarkBlueBorder].CGColor : [UIColor npLightBlueBorder].CGColor;
    _speedButton.backgroundColor = _speedButton.selected ?[UIColor npLightBlue]:[UIColor npDarkBlue];
    
    if (!_autoPlayButton.selected) {
        [self respondToSwipe];
    }
}

- (void)audioOnSelection {
    [SSKeychain setPassword:(_isAudioOnSelected ? @"Yes":@"No")
                 forService:@"mitll.proFeedback.device" account:@"audioOn"];
    _myAudioPlayer.volume = _isAudioOnSelected ? 1: 0;
    
    if (_isAudioOnSelected) {
        [self postEvent:@"turnOnAudio" widget:@"_identityRestoreID" type:@"Button"];
    }
    else {
        [self postEvent:@"turnOffAudio" widget:@"_identityRestoreID" type:@"Button"];
    }
    
    if (!_autoPlayButton.selected) {
        if (!_isAudioOnSelected) {
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
    // [self postEvent:[NSString stringWithFormat:@"EAFReco : playStarted exid %@",[self getCurrentExID]] widget:@"playStarted" type:@"Button"];
    
    [self highlightFLWhilePlaying];
}

- (void) playStopped {
    //   NSLog(@"playStopped - ");
    //    [self postEvent:[NSString stringWithFormat:@"EAFReco : playStopped exid %@",[self getCurrentExID]] widget:@"playStopped" type:@"Button"];
    
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
            if (_languageSegmentIndex == 0 || _languageSegmentIndex == 1) { // already played english, so now at end of fl, go to next
                [self doAutoAdvance];
            }
            else { // haven't played english yet, so play it
                [self speakEnglish:false];
            }
        }
    }
    else {
        //    [self postEvent:[NSString stringWithFormat:@"EAFReco : playGotToEnd exid %@",[self getCurrentExID]] widget:@"playGotToEnd" type:@"Button"];
        //  NSLog(@"playGotToEnd - no op");
    }
}

// set the text color of all the labels in the scoreDisplayContainer
- (void)setTextColor:(UIColor *)color {
    for (UIView *subview in [_scoreDisplayContainer subviews]) {
        if ([subview isKindOfClass:[UILabel class]]) {
            UILabel *asLabel = (UILabel *) subview;
            asLabel.textColor = color;
            //  NSLog(@"initial hit %@ %@",asLabel,asLabel.text);
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

- (void)updateMeteringConstraint: (float) height {
    if (meteringConstraint != NULL) {
        [_metering removeConstraint: meteringConstraint]; //all constraints
    }
    meteringConstraint = [NSLayoutConstraint constraintWithItem:_metering
                                                      attribute:NSLayoutAttributeHeight
                                                      relatedBy:NSLayoutRelationEqual
                                                         toItem:nil
                                                      attribute: NSLayoutAttributeNotAnAttribute
                                                     multiplier:1
                                                       constant:height];
    
    [_metering addConstraint:meteringConstraint];
}

- (void)updatePeakConstraint: (float) height {
    if (peakConstraint != NULL) {
        [_recordButtonContainer removeConstraint: peakConstraint]; //all constraints
    }
    
    peakConstraint = [NSLayoutConstraint constraintWithItem:_peak
                                                  attribute:NSLayoutAttributeBottom
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:_metering
                                                  attribute: NSLayoutAttributeBottom
                                                 multiplier:1
                                                   constant:-height];
    
    [_recordButtonContainer addConstraint:peakConstraint];
}

- (void)audioRecorderDidFinishRecording:
(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    if (_meteringTimer != NULL) {
        [_meteringTimer invalidate];
        [self updateMeteringConstraint:0];
        [self updatePeakConstraint:0];
        [_peak setHidden:TRUE];
    }
    
    if (debugRecord)  NSLog(@"audioRecorderDidFinishRecording time = %f",CFAbsoluteTimeGetCurrent());
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:_audioRecorder.url options:nil];
    NSLog(@"audioRecorderDidFinishRecording - url %@", _audioRecorder.url);
    
    double durationInSeconds = CMTimeGetSeconds(asset.duration);
    
    NSLog(@"audioRecorderDidFinishRecording : file duration was %f vs event       %f diff %f",durationInSeconds, (_now-_then2), (_now-_then2)-durationInSeconds );
    NSLog(@"audioRecorderDidFinishRecording : file duration was %f vs gesture end %f diff %f",durationInSeconds, (_gestureEnd-_then2), (_gestureEnd-_then2)-durationInSeconds );
    
    if (durationInSeconds > 20) {
        [self setDisplayMessage:@"Recording too long."];
    }
    else if (durationInSeconds > 0.3) {
        [self postAudio];
    }
    else {
        [self setDisplayMessage:@"Recording too short."];
        if (_audioRecorder.recording)
        {
            if (debugRecord || TRUE)  NSLog(@"audioRecorderDidFinishRecording : audio recorder stop time = %f",CFAbsoluteTimeGetCurrent());
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
    
    /*
     long selected = [_whatToShow selectedSegmentIndex];
     */
    long selected = _languageSegmentIndex;
    if (selected == 0 || selected == 1 || selected == 3) {
        [self flipCard];
    }
}

- (void)stopPlayingAudio {
    //NSLog(@" stopPlayingAudio ---- ");
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
    //if (_foreignLang.textColor == [UIColor npMedPurple]) {
    _foreignLang.textColor = [UIColor npDarkBlue];
    //}
}

- (void)highlightFLWhilePlaying
{
    //    NSLog(@" highlightFLWhilePlaying - show fl");
    _foreignLang.textColor = [UIColor npMedPurple];
    //    _pageControl.currentPage = 1;
}

- (void)logError:(NSError *)error {
    NSLog(@"Domain:      %@", error.domain);
    NSLog(@"Error Code:  %ld", (long)error.code);
    NSLog(@"Description: %@", [error localizedDescription]);
    NSLog(@"Reason:      %@", [error localizedFailureReason]);
}

bool debugRecord = false;

// only called on startQuiz and if don't have a session id - i.e. after the end of a quiz
- (void)startNewSession {
    _sessionTimeStamp= (long) CFAbsoluteTimeGetCurrent() * 1000;
    _lastSessionTimeStamp = _sessionTimeStamp;
}

// when the user says OK out of the welcome dialog.
- (void)startQuiz {
    _timeRemainingMillis = _quizMinutes.intValue*60000;
    [self startNewSession];
    //    NSLog(@"recordAudio set new session to %ld",_sessionTimeStamp);
    _quizTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerCalled) userInfo:nil repeats:YES];
}

- (void)stopQuiz {
    [_quizTimer invalidate];
    _quizTimer = NULL;
    
    _sessionTimeStamp = -1;
    NSLog(@"recordAudio set new session to %ld vs last %ld",_sessionTimeStamp, _lastSessionTimeStamp);
}

- (IBAction)recordAudio:(id)sender {
    [self stopAutoPlay];
    
    _then2 = CFAbsoluteTimeGetCurrent();
    if (debugRecord) NSLog(@"recordAudio time = %f",_then2);
    
    [_myAudioPlayer stopAudio];
    
    if (!_audioRecorder.recording)
    {
        if (debugRecord) NSLog(@"recordAudio time = %f",CFAbsoluteTimeGetCurrent());
        _english.textColor = [UIColor npDarkBlue];
        _meteringTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(doMeteringUpdate) userInfo:nil repeats:YES];
        [_peak setHidden:FALSE];
        
        for (UIView *v in [_scoreDisplayContainer subviews]) {
            [v removeFromSuperview];
        }
        
        NSError *error = nil;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord error:&error];
        
        // try to avoid weird bug where the audio file would have lots of zeroes after it
        if (_audioRecorder.deleteRecording) {
          //  NSLog(@"recordAudio deleted any old recording...");
        }
        else {
            NSLog(@"huh? couldn't delete old recording...");
        }
        
        [_audioRecorder record];
        
        if (_audioRecorder.recording)
        {
            if (debugRecord) {
                CFAbsoluteTime recordingBegins = CFAbsoluteTimeGetCurrent();
                NSLog(@"recordAudio -recording %f vs begin %f diff %f ",_then2,recordingBegins,(recordingBegins-_then2));
            }
            
            if (_quizTimer == NULL && [self isAQuiz] && _sessionTimeStamp == -1) {  // start a new session if we don't have one...
                [self startNewSession];
            }
        }
        else {
            NSLog(@"recordAudio -DUDE NOT recording");
            [self logError:error];
        }
    }
}
- (NSString *)getTimeRemaining:(int)l {
    NSString *value;
    if (l > 0) {
        int ONE_MIN = 60000;
        int min = l / ONE_MIN;
        int sec = (l - (min * ONE_MIN))/1000;
        NSString *prefix = min < 10 ? @"0" : @"";
        NSString *secPrefix = (sec < 10 ? @"0" : @"");
        value = [NSString stringWithFormat:@"%@%d:%@%d",prefix,min,secPrefix,sec];
        
        float fminMillis = _quizMinutes.floatValue*60000.0;
        float fremain = (float)_timeRemainingMillis;
        float percent = fremain/fminMillis;
        //   NSLog(@"Timer Called %d total %f  remain %f percent %f",_timeRemaining,fmin,fremain,fremain/fmin);
        
        if (_timeRemainingMillis > 10000) {
            percent = ((float)((int)(percent*20)))/20.0;
        }
        [_timerProgress setProgress:percent];
        
        if (percent < 0.10) {
            [_timerProgress setTintColor:[UIColor redColor]];
        }
        else if (percent < 0.20) {
            [_timerProgress setTintColor:[UIColor yellowColor]];
        }
        
        // TODO : consider coloring it
        //  prefix + min + @":" + (sec < 10 ? @"0" : @"") + sec;
        //            if (min == 0) {
        //                if (sec < 30) {
        //                    timeLeft.setType(LabelType.IMPORTANT);
        //                } else {
        //                    timeLeft.setType(LabelType.WARNING);
        //                }
        //            } else {
        //                timeLeft.setType(LabelType.SUCCESS);
        //            }
    } else {
        value = @"Times up!";
        [_timerProgress setProgress:0];
    }
    return value;
}

- (void)setTimeRemainingLabel {
    [_timeRemainingLabel setText:[self getTimeRemaining:_timeRemainingMillis]];
}


-(void)timerCalled
{
    //    NSLog(@"Timer Called %d",_timeRemaining);
    _timeRemainingMillis -=1000;
    
    if (!_isPostingAudio) {
        if (_timeRemainingMillis <= 0) {
            [self stopQuiz];
            [self showQuizComplete];
        }
        
        [self setTimeRemainingLabel];
    }
}

- (void)postRecordAudioStart {
    [self postEvent:@"record audio start" widget:@"record audio" type:@"Button"];
}

- (void)flipCard {
    [self unselectAutoPlay];
    [self stopPlayingAudio];
    
    _pageControl.currentPage = _pageControl.currentPage == 0 ? 1 : 0;
    long selected = _languageSegmentIndex;
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
    
    if (_isAudioOnSelected) {
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
        /*
         long selected = [_whatToShow selectedSegmentIndex];
         */
        long selected = _languageSegmentIndex;
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
    /*
     if ([_whatToShow selectedSegmentIndex] == 2) {
     */
    if(_languageSegmentIndex == 2){
        [self swipeRightDetected:sender];
    }
    else {
        [self swipeUp:sender ];
    }
}

- (IBAction)longPressAction:(id)sender {
    //  if (debugRecord)  NSLog(@"longPressAction   state %ul vs %ul", (long)_longPressGesture.state, (long)UIGestureRecognizerStateBegan);
    
    if (_longPressGesture.state == UIGestureRecognizerStateBegan) {
        if (debugRecord)  NSLog(@"longPressAction got state begin");
        
        _gestureStart = CFAbsoluteTimeGetCurrent();
        
        [self invalidateStopRecordingLater];
        
        _recordButtonContainer.backgroundColor =[UIColor npRecordBG];
        _recordButton.enabled = NO;
        
        [_correctFeedback setHidden:true];
        _answerAudioOn.hidden = true;
        _scoreProgress.hidden = true;
        
        [self setDisplayMessage:@""];
        [self recordAudio:nil];
    }
    else if (_longPressGesture.state == UIGestureRecognizerStateEnded) {
        _gestureEnd = CFAbsoluteTimeGetCurrent();
        
        _recordButtonContainer.backgroundColor =[UIColor whiteColor];
        _recordButton.enabled = YES;
        
        if (debugRecord)  NSLog(@"longPressAction now time = %f",_gestureEnd);
        double gestureDiff = _gestureEnd - _gestureStart;
        
        // NSLog(@"diff %f",gestureDiff);
        if (gestureDiff < 0.4) {
            [self setDisplayMessage:@"Press and hold to record."];
            if (_audioRecorder.recording)
            {
                if (debugRecord)  NSLog(@"longPressAction : audio recorder stop time = %f",CFAbsoluteTimeGetCurrent());
                [_audioRecorder stop];
            }
        }
        else {
            //           [self stopRecordingAudio:nil];
            [self stopRecordingWithDelay:nil];
        }
    }
    //    else {
    //        NSLog(@"longPressAction got other event %ld", (long)_longPressGesture.state);
    //    }
}

- (void)getAltPlayerFromPreviousAudio:(NSNumber *)exid{
    //    NSData *pastAudio= [_exToRecordedAudio objectForKey:exid];
    //    if (pastAudio == NULL) {
    //   NSLog(@"playAudio got null for %@",exid);
    NSData *pastAudio= [_exToRecordedAudio objectForKey:exid];
    
    if (pastAudio == NULL) {
        NSLog(@"playAudio 2 got null for %@",exid);
        
        for(id key in _exToRecordedAudio)
            NSLog(@"key=%@ value=%@", key, [_exToRecordedAudio objectForKey:key]);
    }
    
    //    }
    
    //            NSLog(@"playAudio using prev audio for %@ of size %lu",exid,(unsigned long)[pastAudio length]);
    //            NSLog(@"postAudio   address is <NSData: %p>",pastAudio);
    //            if ([pastAudio isKindOfClass:[NSData class]]) {
    //                NSLog(@"postAudio   address for NSDATA is <NSData: %p>",pastAudio);
    //            }
    //            else {
    //                NSLog(@"postAudio   address for something else is <?: %p>",pastAudio);
    //            }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *myPathDocs = [documentsDirectory stringByAppendingPathComponent:@"myAudio.wav"];
    BOOL isFileWriteComplete = [pastAudio writeToFile:myPathDocs atomically:YES];
    if(isFileWriteComplete)
    {
        //                NSLog(@"AVPlayer for %@ with %@",exid,myPathDocs);
        NSURL *url = [[NSURL alloc] initFileURLWithPath: myPathDocs];
        _altPlayer = [[AVPlayer alloc] initWithURL:url];
    }
}

- (id _Nullable)getCurrentExID {
    return [[self getCurrentJson] objectForKey:@"id"];
}

- (void)doBouncingBallHighlight:(NSMutableDictionary *)prevWordAttr {
    CMTime tm = CMTimeMakeWithSeconds(0.01, 100);
    UIColor *hColor = [EAFRecoFlashcardController colorFromHexString:@"#007AFF"];
    __weak typeof(self) weakSelf = self;
    
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
}

// called when touch on highlighted word
- (IBAction)playAudio:(id)sender {
    if (!_audioRecorder.recording)
    {
        if ([self isAQuiz]) {
            [self stopTimer];
        }
        
        NSNumber *exid= [self getCurrentExID];
        
        //        NSLog(@"playAudio playAudio %@ vs %@ audio url %@", exid, _lastRecordedAudioExID, _audioRecorder.url);
        [self stopPlayingAudio];
        
        NSError *error;
        AVAudioSession *session = [AVAudioSession sharedInstance];
        
        [session setCategory:AVAudioSessionCategoryPlayback error:nil];
        // what does this do?
        [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
        
        if (_lastRecordedAudioExID == NULL || [exid isEqualToNumber:_lastRecordedAudioExID]) {
            _altPlayer = [[AVPlayer alloc] initWithURL:_audioRecorder.url];
        }
        else {
            // NSLog(@"playAudio  size %lu",[_exToRecordedAudio count]);
            [self getAltPlayerFromPreviousAudio:exid];
        }
        
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
        
        [self doBouncingBallHighlight:prevWordAttr];
        
        if (error)
        {
            NSLog(@"Error: %@", [error localizedDescription]);
        } else {
            //  NSLog(@"OK let's play the audio");
            [_altPlayer play];
        }
        // [self postEvent:@"playUserAudio" widget:@"userScoreDisplay" type:@"UIView"];
    }
}

+ (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

- (IBAction)stopRecordingAudio:(id)sender {
    _stopRecordingLaterTimer = NULL;
    
    _now = CFAbsoluteTimeGetCurrent();
    if (debugRecord)  NSLog(@"stopAudio Event duration was %f",(_now-_then2));
    if (debugRecord)  NSLog(@"stopAudio now  time =        %f",_now);
    
    _recordButton.enabled = YES;
    
    if (_audioRecorder.recording)
    {
        if (debugRecord)  NSLog(@"stopAudio stop time = %f",CFAbsoluteTimeGetCurrent());
        [_audioRecorder stop];
        
    } else {
        NSLog(@"stopAudio not recording?");
    }
}

- (void)invalidateStopRecordingLater {
    if (_stopRecordingLaterTimer != NULL && _stopRecordingLaterTimer.isValid) {
        [_stopRecordingLaterTimer invalidate];
    }
}

//
- (IBAction)stopRecordingWithDelay:sender {
    [self invalidateStopRecordingLater];
    _stopRecordingLaterTimer = [NSTimer scheduledTimerWithTimeInterval:0.20
                                                                target:self
                                                              selector:@selector(stopRecordingAudio:)
                                                              userInfo:nil
                                                               repeats:NO];
}

- (void)doShuffle {
    _randSequence = [[NSMutableArray alloc] initWithCapacity:_jsonItems.count];
    
    for (unsigned long i = 0; i < _jsonItems.count; i++) {
        [_randSequence addObject:[NSNumber numberWithUnsignedLong:i]];
    }
    
    unsigned int max = (int)_jsonItems.count;
    unsigned int firstIndex;
    for (unsigned int ii = 0; ii < max; ++ii) {
        unsigned int remainingCount = max - ii;
        unsigned int r = arc4random_uniform(remainingCount)+ii;
        if (ii == 0){
            firstIndex = r;
        }
        [_randSequence exchangeObjectAtIndex:ii withObjectAtIndex:r];
        
    }
    
    _index = firstIndex;
}

- (void)showConnectionError:(NSError *)error {
    NSString *msg= [NSString stringWithFormat:@"Network connection problem, please try again.\nError Code (%ld) : %@",(long)error.code,error.localizedDescription];
    [self showError:msg];
    [self dismissLoadingContentAlert];
}

// Posts audio with current fl field
- (void)postAudio {
    [_recoFeedbackImage startAnimating];
    
    _isPostingAudio=TRUE;  // so if we have count down timer, what time to not include in total
    
    NSData *postData = [NSData dataWithContentsOfURL:_audioRecorder.url];
    
    //  NSLog(@"postAudio data length %lu",(unsigned long)[postData length]);
    
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
    
    NSString *host = [_siteGetter.nameToHost objectForKey:_language];
    NSString *baseurl = [NSString stringWithFormat:@"%@scoreServlet", _url];
    if ([host length] != 0) {
        baseurl = [NSString stringWithFormat:@"%@scoreServlet/%@", _url, host];
    }
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:_audioRecorder.url options:nil];
    //NSLog(@"postAudio audioRecorderDidFinishRecording - url %@", _audioRecorder.url);
    
    double durationInSeconds = CMTimeGetSeconds(asset.duration);
    
    NSLog(@"Reco : postAudio talking to %@ file length %@ dur %f",baseurl, postLength, durationInSeconds);
    int maxTime = 30;
    if (durationInSeconds > maxTime) {
        NSLog(@"Reco : long dur : dur %f",  durationInSeconds);
        
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Too long"
                                     message:[NSString stringWithFormat:@"Audio recordings should be no more than %d seconds.",maxTime]
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        //Add Buttons
        
        UIAlertAction* yesButton = [UIAlertAction
                                    actionWithTitle:@"OK"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action) {
                                        
                                    }];
        
        [alert addAction:yesButton];
        [self presentViewController:alert animated:YES completion:nil];
        [self->_recoFeedbackImage stopAnimating];
        
        return;
    }
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:baseurl]];
    [urlRequest setHTTPMethod: @"POST"];
    [urlRequest setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [urlRequest setValue:@"application/x-www-form-urlencoded"      forHTTPHeaderField:@"Content-Type"];
    //[urlRequest setTimeoutInterval:TIMEOUT];
    
    // add request parameters
    
    NSString *deviceType = [NSString stringWithFormat:@"%@_%@_%@",[UIDevice currentDevice].model,[UIDevice currentDevice].systemName,[UIDevice currentDevice].systemVersion];
    [urlRequest setValue:deviceType forHTTPHeaderField:@"deviceType"];
    
    NSString *retrieveuuid = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"UUID"];
    if (_sessionTimeStamp > 0) {
        retrieveuuid = [NSString stringWithFormat:@"%ld",_sessionTimeStamp] ;
    }
    // NSLog(@"postAudio session is %@",[NSString stringWithFormat:@"%ld",_sessionTimeStamp]);
    
    [urlRequest setValue:retrieveuuid forHTTPHeaderField:@"device"];
    
    NSNumber *exid= [self getCurrentExID];
    
    // so we can play it later if we want
    [_exToRecordedAudio setObject:[NSData dataWithData:postData] forKey:exid];
    
    //    NSData *audioData2= [_exToRecordedAudio objectForKey:exid];
    //    NSLog(@"postAudio   remembered for %@ (%lu)",exid,(unsigned long)[audioData2 length]);
    //   NSLog(@"postAudio   now %ld",[_exToRecordedAudio count]);
    //    NSLog(@"postAudio   address is <NSData: %p>",audioData2);
    
    _lastRecordedAudioExID = exid;
    
    [urlRequest setValue:[NSString stringWithFormat:@"%@",exid]        forHTTPHeaderField:@"exercise"];
    [urlRequest setValue:@"decode" forHTTPHeaderField:@"request"];
    
    [urlRequest setValue:[NSString stringWithFormat:@"%@",[self getProjectID]] forHTTPHeaderField:@"projid"];
    
    [urlRequest setValue:[NSString stringWithFormat:@"%d",_reqid] forHTTPHeaderField:@"reqid"];
    _reqid++;
    
    // post the audio
    [urlRequest setHTTPBody:postData];
    // NSLog(@"posting to %@",_url);
    
    NSURLSessionDataTask *downloadTask =
    [[NSURLSession sharedSession] dataTaskWithRequest:urlRequest
                                    completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
     {
         dispatch_async(dispatch_get_main_queue(), ^{
             [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];
             [self->_recoFeedbackImage stopAnimating];
         });
         
         //    NSLog(@"resself->ponse to post of audio...");
         if (error != nil) {
             NSLog(@"postAudio : Got error %@",error);
             dispatch_async(dispatch_get_main_queue(), ^{
                 if (error.code == NSURLErrorNotConnectedToInternet) {
                     [self setDisplayMessage:@"Make sure your wifi or cellular connection is on."];
                 }
                 else {
                     [self->_poster postError:urlRequest error:error];
                     [self showConnectionError:error];
                 }
             });
         }
         else {
             self->_responseData = data;
             [self performSelectorOnMainThread:@selector(connectionDidFinishLoading)
                                    withObject:nil
                                 waitUntilDone:YES];
         }
     }];
    [downloadTask resume];
    
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

// previous score lets the progress bar grow from old to new score
- (void)showScoreToUser:(NSDictionary *)json previousScore:(NSNumber *)previousScore {
    BOOL correct = [[json objectForKey:@"isCorrect"] boolValue] && [[json objectForKey:@"fullmatch"] boolValue];
    NSString *valid = [json objectForKey:@"valid"];
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
            [self setDisplayMessage:valid];
        }
    }
    _scoreProgress.hidden = false;
    
    if (previousScore != nil) {
        [_scoreProgress setProgress:[previousScore floatValue]];
        [_scoreProgress setProgressTintColor:[self getColor2:[previousScore floatValue]]];
        [self performSelector:@selector(showProgressAnimated:) withObject:overallScore afterDelay:0.5];
    }
    else {
        [_scoreProgress setProgress:[overallScore floatValue]];
        [_scoreProgress setProgressTintColor:[self getColor2:[overallScore floatValue]]];
    }
    
    if (correct) {
        float theScore = [overallScore floatValue];
        NSString *emoji = [self getEmojiForScore:theScore*100];
      //  NSLog(@"theScore was %@ = %@",overallScore,emoji);
        [_correctFeedback setText:emoji];
    }
    else {
        [_correctFeedback setText:@"\U0000274C"];  // red x
    }
    
    [_correctFeedback setHidden:false];
    [_answerAudioOn setHidden:false];
}

- (void)doAfterScoreReceived:(BOOL)isFullMatch score:(NSNumber *)score {
    if ([self isAQuiz] && score.floatValue*100 >= _minScoreToAdvance.floatValue && isFullMatch) {
        BOOL onLast = _index+1 == _jsonItems.count;
        //  NSLog(@"check got %lu vs total %lu",_index, (unsigned long)_jsonItems.count);
        if (onLast) {
            _index = 0;
            _preventPlayAudio = TRUE;
            [self showQuizComplete];
        }
        else {
            _autoAdvanceTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(doAutoAdvance) userInfo:nil repeats:NO];
        }
    }
}

// TODO : consider how to do streaming audio
- (void)connectionDidFinishLoading {
    _isPostingAudio=FALSE;
    
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    CFAbsoluteTime diff = (now-_startPost);
    CFAbsoluteTime millis = diff * 1000;
    int iMillis = (int) millis;
    
    
    if ([self isAQuiz]) {
        _timeRemainingMillis += iMillis;  // put the time back - don't count round trip wait against completion time...
    }
    
    {
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:_audioRecorder.url options:nil];
        double durationInSeconds = CMTimeGetSeconds(asset.duration);
        
        NSLog(@"connectionDidFinishLoading - round trip time was %f %d dur %.3f sec ",diff, iMillis, durationInSeconds);
        
        [self postEvent:[NSString stringWithFormat:@"round trip was %.3f sec for file of dur %.3f sec",diff,durationInSeconds]
                 widget:[NSString stringWithFormat:@"rt %.3f",diff]
                   type:[NSString stringWithFormat:@"file %.3f",durationInSeconds] ];
    }
    
    NSError * error;
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:_responseData
                          options:NSJSONReadingMutableContainers
                          error:&error];
    
    //    NSString *string = [NSString stringWithUTF8String:[_responseData bytes]];
    //    NSLog(@"connectionDidFinishLoading data was \n%@",string);
    
    if (error != nil) {
        NSLog(@"connectionDidFinishLoading - url %@ got error %@",NULL, error);
        [_poster postError:NULL error:error];
        // NSLog(@"data was %@",_responseData);
    }
    // else {
    //     NSLog(@"JSON was %@",json);
    // }
    //  NSLog(@"score was %@",overallScore);
    //     NSLog(@"correct was %@",[json objectForKey:@"isCorrect"]);
    //     NSLog(@"saidWord was %@",[json objectForKey:@"saidWord"]);
    NSNumber *exid = [json objectForKey:@"exid"];
    
    NSNumber *resultID = [json objectForKey:@"resultID"];
    BOOL isFullMatch = [[json objectForKey:@"fullmatch"] boolValue];
    
    // Post a RT value for the result id
    NSString * roundTrip =[NSString stringWithFormat:@"%d",(int) millis];
    NSLog(@"connectionDidFinishLoading - roundTrip  %@ %@",roundTrip, [resultID stringValue]);
    
    if (resultID != NULL) {
        [[self getPoster] postRT:[resultID stringValue] rtDur:roundTrip];
    }
    
    NSNumber *score = [json objectForKey:@"score"];
    //   NSLog(@"score was %@ class %@",[json objectForKey:@"score"], [[json objectForKey:@"score"] class]);
    if ([score isEqualToNumber:[NSNumber numberWithInt:-1]]) {
        [self setDisplayMessage:@"Score low, try again."];
        return;
    }
    
    NSNumber *previousScore;
    if (exid != nil) {
        previousScore = [_exToScore objectForKey:exid];
        //BOOL saidWord = [[json objectForKey:@"saidWord"] boolValue];
        if (score != nil && isFullMatch) {
            [_exToScore setObject:score forKey:exid];
            [_exToScoreJson setObject:json forKey:exid];
            [self setTitleWithScore];
           // NSLog(@"_exToScore %@ %@ now %lu",exid,score,(unsigned long)[_exToScore count]);
        }
    }
    
    if ([[json objectForKey:@"reqid"] intValue] < _reqid-1) {
        NSString *reqid = [json objectForKey:@"reqid"];
        NSLog(@"got back reqid %@",reqid);
        NSLog(@"json was       %@",json);
        NSLog(@"discarding old response - got back %@ latest %d",reqid ,_reqid);
        return;
    }
    
    if (![exid isEqualToNumber:[self getCurrentExID]]) {
        NSLog(@"response exid not same as current - got %@ vs expecting %@",exid,[self getCurrentExID]);
        return;
    }
    
    [self showScoreToUser:json previousScore:previousScore];
    
    [self doAfterScoreReceived:isFullMatch score:score];
}

- (void)sortWorstFirstStartOver {
    NSArray *sortedArray;
    sortedArray = [_jsonItems sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSNumber *firstExID = [(NSDictionary*)a objectForKey:@"id"];
        NSNumber *secondExID = [(NSDictionary*)b objectForKey:@"id"];
        
        NSNumber *firstScore = [self->_exToScore objectForKey:firstExID];
        NSNumber *secondScore = [self->_exToScore objectForKey:secondExID];
        
        if (firstScore == NULL) {
            if (secondScore == NULL) {
                NSString *firstFL = [(NSDictionary*)a objectForKey:@"fl"];
                NSString *secondFL = [(NSDictionary*)b objectForKey:@"fl"];
                return [firstFL compare:secondFL];
            }
            else {
                return -1;
            }
        }
        else {
            if (secondScore == NULL) {
                return +1;
            }
            else {
                return [firstScore compare:secondScore];
            }
        }
        
    }];
    _jsonItems = sortedArray;
    _index = 0;
    
    [self respondToSwipe];
}

- (NSString *)getEmojiForScore:(float)theScore {
    NSString *emoji1 =@"\U0001F601";   // grinning
    NSString *emoji2 =@"\U0001F600";   // smiling
    NSString *emoji3 =@"\U0001F610";   // neutral
    NSString *emoji4 =@"\U0001F914";   // thinking
    NSString *emoji5 =@"\U0001F615";   // confused
    NSString *emoji6 =@"\U00002639";   // frown
    
    // private static final List<Float> koreanThresholds = new ArrayList<>(Arrays.asList(0.31F, 0.43F, 0.53F, 0.61F, 0.70F));
    // private static final List<Float> englishThresholds = new ArrayList<>(Arrays.asList(0.23F, 0.36F, 0.47F, 0.58F, NATIVE_HARD_CODE));  // technically last is 72
    
    NSArray *array = @[ @0.31f, @0.43f, @0.53f, @0.61f, @0.70f];
    NSArray *emoji = @[ emoji6, emoji5, emoji4, emoji3, emoji2, emoji1];
    
    NSString *s = emoji1;  // default is grinning
    
    for (int i = 0; i < [array count];i++) {
        NSNumber *num = [array objectAtIndex:i];
        if (theScore < [num floatValue]*100) {
         //   NSLog(@"1 - getEmojiForScore : (%f) %d = %@",theScore, i,num);
            s=[emoji objectAtIndex:i];
            break;
        }
    }
    
 //   NSLog(@"getEmojiForScore : (%f) = %@",theScore, s);

    return s;
}

- (NSString *)getEmoji:(float *)overall {
    float total=0.0;
    for(id key in _exToScore) {
        total+= [[_exToScore objectForKey:key] floatValue];
    }
    
    NSUInteger completedCount = [_exToScore count];
    if (completedCount == 0) {
        *overall = 0;
    }
    else {
        *overall = (100.0f*total)/(float)completedCount;
    }
    
    return [self getEmojiForScore:*overall];
}

- (void) setTitleWithScore {
    float overall;
    NSString *emoji= [self getEmoji:&overall];
    
    NSString *score = [NSString stringWithFormat:@"Score is %@ (%d) for %lu items", emoji, (int)overall,(unsigned long)[_exToScore count]];
    [self setTitle:score];
}

- (void) showQuizComplete {
    //NSLog(@"showQuizComplete _exToScore now %lu",(unsigned long)[_exToScore count]);
    self.navigationItem.rightBarButtonItem.enabled = true;
    
    unsigned long done=[_exToScore count];
    float overall;
    NSString *emoji= [self getEmoji:&overall];
    NSString *score = [NSString stringWithFormat:@"Score was a %@ (%d) for %lu items", emoji, (int)overall,done];
    
    //    NSString *score = [NSString stringWithFormat:@"Your score was a %d.",(int)overall];
    
    if (done < _jsonItems.count) {
        score = [NSString stringWithFormat:@"%@\nYou completed %lu of %lu items.",score,done,(unsigned long)_jsonItems.count];
    }
    if (_timeRemainingMillis > 0) {         // if you have time, it jumps back with sorted order worst to best
        score = [NSString stringWithFormat:@"%@\nYou have time, do you want to try again on low score items?",score];
        
        NSMutableAttributedString *hogan = [[NSMutableAttributedString alloc] initWithString:score];
        [hogan addAttribute:NSFontAttributeName
                      value:[UIFont systemFontOfSize:50.0]
                      range:NSMakeRange(0, [score length])];
        
        [self quizCompleteYesNo:hogan.string];
        // TODO : instead, sort the items by score
        // jump back to first
    } else {
        NSMutableAttributedString *hogan = [[NSMutableAttributedString alloc] initWithString:score];
        [hogan addAttribute:NSFontAttributeName
                      value:[UIFont systemFontOfSize:50.0]
                      range:NSMakeRange(0, [score length])];
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Quiz Complete!"
                                                                       message:hogan.string
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  [self showScoresClick:nil];
                                                              }];
        
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:^{
            [self showScoresClick:nil];
        }];
    }
    
}

- (void)quizCompleteYesNo:(NSString *) msg
{
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"Quiz Complete!"
                                 message:msg
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    //Add Buttons
    
    UIAlertAction* yesButton = [UIAlertAction
                                actionWithTitle:@"Yes"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
                                    //Handle your yes please button action here
                                    [self sortWorstFirstStartOver];
                                    
                                }];
    
    UIAlertAction* noButton = [UIAlertAction
                               actionWithTitle:@"No"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                   self->_timeRemainingLabel.text = @"00:00";
                                   [self showScoresClick:nil];
                               }];
    
    [alert addAction:yesButton];
    [alert addAction:noButton];
    
    [self presentViewController:alert animated:YES completion:nil];
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
    
    [wordLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    wordLabel.adjustsFontForContentSizeCategory = YES;
    wordLabel.adjustsFontSizeToFitWidth=YES;
    
    wordLabel.minimumScaleFactor=0.1;
    
    
    return wordLabel;
}

// try to de-emphasize phones you score well on
- (NSMutableAttributedString *)getColoredPhones:(NSString *)phoneToShow wend:(NSNumber *)wend wstart:(NSNumber *)wstart phoneAndScore:(NSArray *)phoneAndScore {
    // now mark the ranges in the string with colors
    
    NSMutableAttributedString *coloredPhones = [[NSMutableAttributedString alloc] initWithString:phoneToShow];
    
    int pstart = 0;
    UIColor *gray = [UIColor grayColor];
    
    for (NSDictionary *event in phoneAndScore) {
        NSString *phoneText = [event objectForKey:@"event"];
        if ([phoneText isEqualToString:@"sil"]) continue;
        
        NSNumber *pscore = [event objectForKey:@"score"];
        NSNumber *start  = [event objectForKey:@"start"];
        NSNumber *end    = [event objectForKey:@"end"];
        
        if ([start floatValue] >= [wstart floatValue] && [end floatValue] <= [wend floatValue]) {
            NSRange range = NSMakeRange(pstart, [phoneText length]);
            pstart += range.length + (_addSpaces ? 1 : 0);
            float score = [pscore floatValue];
            UIColor *color = [self getColorPhones:score];
            //        NSLog(@"%@ %f %@ range at %lu length %lu", phoneText, score,color,(unsigned long)range.location,(unsigned long)range.length);
            [coloredPhones addAttribute:NSBackgroundColorAttributeName
                                  value:color
                                  range:range];
            
            if (score > 0.53) {
                [coloredPhones addAttribute:NSForegroundColorAttributeName
                                      value:gray
                                      range:range];
            }
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
            pstart += range.length + (_addSpaces ? 1 : 0);
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
            if (_addSpaces) {
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
    
    // bottom
    [exampleView addConstraint:[NSLayoutConstraint
                                constraintWithItem:phoneLabel
                                attribute:NSLayoutAttributeBottom
                                relatedBy:NSLayoutRelationEqual
                                toItem:exampleView
                                attribute:NSLayoutAttributeBottom
                                multiplier:1.0
                                constant:2.0]];
}

- (void)addWordLabelConstraints:(UIView *)exampleView wordLabel:(UILabel *)wordLabel {
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
    phoneLabel.minimumScaleFactor=0.1;
    
    phoneLabel.textAlignment = isRTL ? NSTextAlignmentRight : NSTextAlignmentLeft;
    phoneLabel.attributedText = coloredPhones;
    [phoneLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    phoneLabel.adjustsFontForContentSizeCategory = YES;
    
    return phoneLabel;
}

- (UIFont *)getWordFont {
    float len = [NSNumber numberWithUnsignedLong:_foreignLang.text.length].floatValue;
    // NSLog(@"len %lu",(unsigned long)len);
    float slen = [self isiPhone] ? 10 : 20;
    float scale = slen/len;
    scale = fmin(1,scale);
    
    //    int largest  = [self isiPhone] ? 24 : 48;
    //    int smallest = [self isiPhone] ? 7  : 14;
    
    int largest  = [self isiPhone] ? 36 : 48;
    int smallest = [self isiPhone] ? 14 : 24;
    
    float newFont = smallest + floor((largest-smallest)*scale);
    //   float newFont = largest;//36;//smallest + floor((largest-smallest)*scale);
    //NSLog(@"getWordFont len %lu font is %f",(unsigned long)len,newFont);
    
    UIFont *wordFont = [UIFont systemFontOfSize:[NSNumber numberWithFloat:newFont].intValue];
    return wordFont;
}

// worries about RTL languages
// super complicated and finicky - tries to do center alignment and word wrap
- (void)updateScoreDisplay:(NSDictionary*) json {
    NSArray *wordAndScore  = [json objectForKey:@"WORD_TRANSCRIPT"];
    NSArray *phoneAndScore = [json objectForKey:@"PHONE_TRANSCRIPT"];
    
    //    NSLog(@"updateScoreDisplay size for words %lu",(unsigned long)wordAndScore.count);
    //    NSLog(@"word  json %@",wordAndScore);
    //    NSLog(@"phone json %@",phoneAndScore);
    for (UIView *v in [_scoreDisplayContainer subviews]) {
        [v removeFromSuperview];
    }
    
    UIFont *wordFont = [self getWordFont];
    
    [_scoreDisplayContainer removeConstraints:_scoreDisplayContainer.constraints];
    _scoreDisplayContainer.translatesAutoresizingMaskIntoConstraints = NO;
    _scoreDisplayContainer.clipsToBounds = YES;
    //   _scoreDisplayContainer.backgroundColor = [UIColor yellowColor];
    
    UIView *leftView  = nil;
    
    BOOL isRTL = [_siteGetter.rtlLanguages containsObject:_language];
    if (isRTL) {
        //  wordAndScore  = [self reversedArray:wordAndScore];
        //   NSLog(@"\n\n\nisRTL !");
        //NSLog(@"now word  json %@",wordAndScore);
        if (!_showPhonesLTRAlways) {
            phoneAndScore = [self reversedArray:phoneAndScore];
        }
    }
    
    UIView *spacerLeft  = [[UIView alloc] init];
    UIView *spacerRight = [[UIView alloc] init];
    
    //       spacerLeft.backgroundColor = [UIColor redColor];
    //        spacerRight.backgroundColor = [UIColor blueColor];
    
    spacerLeft.translatesAutoresizingMaskIntoConstraints = NO;
    spacerRight.translatesAutoresizingMaskIntoConstraints = NO;
    
    [_scoreDisplayContainer addSubview:spacerLeft];
    [_scoreDisplayContainer addSubview:spacerRight];
    
    leftView = spacerLeft;
    
    UIView *lineStart = leftView;
    
    // width of spacers on left and right are equal
    [_scoreDisplayContainer addConstraint:[NSLayoutConstraint
                                           constraintWithItem:spacerLeft
                                           attribute:NSLayoutAttributeWidth
                                           relatedBy:NSLayoutRelationEqual
                                           toItem:spacerRight
                                           attribute:NSLayoutAttributeWidth
                                           multiplier:1.0
                                           constant:0.0]];
    
    // height is equal
    [_scoreDisplayContainer addConstraint:[NSLayoutConstraint
                                           constraintWithItem:spacerLeft
                                           attribute:NSLayoutAttributeHeight
                                           relatedBy:NSLayoutRelationEqual
                                           toItem:spacerRight
                                           attribute:NSLayoutAttributeHeight
                                           multiplier:1.0
                                           constant:1.0]];
    
    [_scoreDisplayContainer addConstraint:[NSLayoutConstraint
                                           constraintWithItem:spacerLeft
                                           attribute:NSLayoutAttributeWidth
                                           relatedBy:NSLayoutRelationGreaterThanOrEqual
                                           toItem:NULL
                                           attribute:NSLayoutAttributeWidth
                                           multiplier:1.0
                                           constant:10.0]];
    
    [_scoreDisplayContainer addConstraint:[NSLayoutConstraint
                                           constraintWithItem:spacerRight
                                           attribute:NSLayoutAttributeWidth
                                           relatedBy:NSLayoutRelationGreaterThanOrEqual
                                           toItem:NULL
                                           attribute:NSLayoutAttributeWidth
                                           multiplier:1.0
                                           constant:10.0]];
    
    
    
    // right edge of right spacer
    [_scoreDisplayContainer addConstraint:[NSLayoutConstraint
                                           constraintWithItem:spacerRight
                                           attribute:NSLayoutAttributeRight
                                           relatedBy:NSLayoutRelationEqual
                                           toItem:_scoreDisplayContainer
                                           attribute:NSLayoutAttributeRight
                                           multiplier:1.0
                                           constant:0.0]];
    
    // bottom of right spacer
    [_scoreDisplayContainer addConstraint:[NSLayoutConstraint
                                           constraintWithItem:spacerRight
                                           attribute:NSLayoutAttributeBottom
                                           relatedBy:NSLayoutRelationEqual
                                           toItem:spacerLeft
                                           attribute:NSLayoutAttributeBottom
                                           multiplier:1.0
                                           constant:0.0]];
    // left edge of left spacer = left of container
    [_scoreDisplayContainer addConstraint:[NSLayoutConstraint
                                           constraintWithItem:spacerLeft
                                           attribute:NSLayoutAttributeLeft
                                           relatedBy:NSLayoutRelationEqual
                                           toItem:_scoreDisplayContainer
                                           attribute:NSLayoutAttributeLeft
                                           multiplier:1.0
                                           constant:5.0]];
    
    // top of spacer left = top of container
    [_scoreDisplayContainer addConstraint:[NSLayoutConstraint
                                           constraintWithItem:spacerLeft
                                           attribute:NSLayoutAttributeTop
                                           relatedBy:NSLayoutRelationEqual
                                           toItem:_scoreDisplayContainer
                                           attribute:NSLayoutAttributeTop
                                           multiplier:1.0
                                           constant:0.0]];
    
    // bottom of left = bottom of container
    [_scoreDisplayContainer addConstraint:[NSLayoutConstraint
                                           constraintWithItem:spacerLeft
                                           attribute:NSLayoutAttributeBottom
                                           relatedBy:NSLayoutRelationEqual
                                           toItem:_scoreDisplayContainer
                                           attribute:NSLayoutAttributeBottom
                                           multiplier:1.0
                                           constant:0.0]];
    
    //    NSLog(@"address of score display %p", _scoreDisplayContainer);
    //    NSLog(@"address of left spacer   %p", spacerLeft    );
    //    NSLog(@"address of right spacer   %p", spacerRight    );
    
    _wordLabels  = [NSMutableArray new];
    _phoneLabels = [NSMutableArray new];
    _wordTranscript = wordAndScore;
    _phoneTranscript = phoneAndScore;
    
    NSString *sofar = @"";
    BOOL onFirstLine=true;
    int numLines = 0;
    
    int max = 250;
    if ([self isiPad]) max =2*275;
    
    for (NSDictionary *wordEvent in wordAndScore) {
        NSString *word = [wordEvent objectForKey:@"event"];
        if ([word isEqualToString:@"sil"] || [word isEqualToString:@"<s>"] || [word isEqualToString:@"</s>"]) continue;
        NSNumber *score = [wordEvent objectForKey:@"score"];
        
        NSNumber *wstart = [wordEvent objectForKey:@"start"];
        NSNumber *wend = [wordEvent objectForKey:@"end"];
        
        sofar = [sofar stringByAppendingString:word];
        
        // NSLog(@"wordEvent for %@ len = %lu",sofar, (unsigned long)[sofar length]);
        
        BOOL startNewLine = false;//[sofar length] > max;
        
        NSDictionary *userAttributes = @{NSFontAttributeName: wordFont,
                                         NSForegroundColorAttributeName: [UIColor blackColor]};
        
        
        CGSize textSize = [sofar sizeWithAttributes: userAttributes];
        if (textSize.width > max) {
            NSLog(@"wordEvent width %@ len = %f",sofar, textSize.width);
            startNewLine = true;
            sofar = word;
            numLines++;
        }
        sofar = [sofar stringByAppendingString:@" "];
        
        UIView *exampleView = [[UIView alloc] init];
        exampleView.translatesAutoresizingMaskIntoConstraints = NO;
        //   exampleView.backgroundColor = [UIColor grayColor];
        [_scoreDisplayContainer addSubview:exampleView];
        
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
        
        
        if (onFirstLine) {
            onFirstLine = false;
            
            // top
            [_scoreDisplayContainer addConstraint:[NSLayoutConstraint
                                                   constraintWithItem:exampleView
                                                   attribute:NSLayoutAttributeTop
                                                   relatedBy:NSLayoutRelationEqual
                                                   toItem:_scoreDisplayContainer
                                                   attribute:NSLayoutAttributeTop
                                                   multiplier:1.0
                                                   constant:0.0]];
            
            if (isRTL) {
                // right - initial right view is the right spacer, but afterwards is the previous word view
                [_scoreDisplayContainer addConstraint:[NSLayoutConstraint
                                                       constraintWithItem:exampleView
                                                       attribute:NSLayoutAttributeRight
                                                       relatedBy:NSLayoutRelationEqual
                                                       toItem:spacerRight
                                                       attribute:NSLayoutAttributeLeft
                                                       multiplier:1.0
                                                       constant:5.0]];
            } else {
                // left - initial left view is the left spacer, but afterwards is the previous word view
                [_scoreDisplayContainer addConstraint:[NSLayoutConstraint
                                                       constraintWithItem:exampleView
                                                       attribute:NSLayoutAttributeLeft
                                                       relatedBy:NSLayoutRelationEqual
                                                       toItem:spacerLeft
                                                       attribute:NSLayoutAttributeRight
                                                       multiplier:1.0
                                                       constant:5.0]];
            }
            lineStart = exampleView;
        }
        else if (startNewLine) {
            if (isRTL) {
                [_scoreDisplayContainer addConstraint:[NSLayoutConstraint
                                                       constraintWithItem:leftView
                                                       attribute:NSLayoutAttributeLeft
                                                       relatedBy:NSLayoutRelationEqual
                                                       toItem:spacerLeft
                                                       attribute:NSLayoutAttributeRight
                                                       multiplier:1.0
                                                       constant:5.0]];
            }
            else {
                // right of prev view = left of right spacer
                [_scoreDisplayContainer addConstraint:[NSLayoutConstraint
                                                       constraintWithItem:leftView
                                                       attribute:NSLayoutAttributeRight
                                                       relatedBy:NSLayoutRelationEqual
                                                       toItem:spacerRight
                                                       attribute:NSLayoutAttributeLeft
                                                       multiplier:1.0
                                                       constant:5.0]];
            }
            
            // top of this view = bottom of prev view
            [_scoreDisplayContainer addConstraint:[NSLayoutConstraint
                                                   constraintWithItem:exampleView
                                                   attribute:NSLayoutAttributeTop
                                                   relatedBy:NSLayoutRelationEqual
                                                   toItem:leftView
                                                   attribute:NSLayoutAttributeBottom
                                                   multiplier:1.0
                                                   constant:5.0]];
            
            if (isRTL) {
                [_scoreDisplayContainer addConstraint:[NSLayoutConstraint
                                                       constraintWithItem:exampleView
                                                       attribute:NSLayoutAttributeRight
                                                       relatedBy:NSLayoutRelationEqual
                                                       toItem:spacerRight
                                                       attribute:NSLayoutAttributeLeft
                                                       multiplier:1.0
                                                       constant:5.0]];
            }
            else {
                // left of this view is right of spacer
                [_scoreDisplayContainer addConstraint:[NSLayoutConstraint
                                                       constraintWithItem:exampleView
                                                       attribute:NSLayoutAttributeLeft
                                                       relatedBy:NSLayoutRelationEqual
                                                       toItem:spacerLeft
                                                       attribute:NSLayoutAttributeRight
                                                       multiplier:1.0
                                                       constant:5.0]];
            }
            
            //    NSLog(@"starting new line with %@",word);
            
            lineStart = exampleView;
            
        }
        else {
            // top
            [_scoreDisplayContainer addConstraint:[NSLayoutConstraint
                                                   constraintWithItem:exampleView
                                                   attribute:NSLayoutAttributeTop
                                                   relatedBy:NSLayoutRelationEqual
                                                   toItem:lineStart
                                                   attribute:NSLayoutAttributeTop
                                                   multiplier:1.0
                                                   constant:0.0]];
            
            // bottom
            [_scoreDisplayContainer addConstraint:[NSLayoutConstraint
                                                   constraintWithItem:exampleView
                                                   attribute:NSLayoutAttributeBottom
                                                   relatedBy:NSLayoutRelationEqual
                                                   toItem:lineStart
                                                   attribute:NSLayoutAttributeBottom
                                                   multiplier:1.0
                                                   constant:0.0]];
            
            if (isRTL) {
                [_scoreDisplayContainer addConstraint:[NSLayoutConstraint
                                                       constraintWithItem:exampleView
                                                       attribute:NSLayoutAttributeRight
                                                       relatedBy:NSLayoutRelationEqual
                                                       toItem:leftView
                                                       attribute:NSLayoutAttributeLeft
                                                       multiplier:1.0
                                                       constant:-5.0]];
            }
            else {
                // left - initial left view is the left spacer, but afterwards is the previous word view
                [_scoreDisplayContainer addConstraint:[NSLayoutConstraint
                                                       constraintWithItem:exampleView
                                                       attribute:NSLayoutAttributeLeft
                                                       relatedBy:NSLayoutRelationEqual
                                                       toItem:leftView
                                                       attribute:NSLayoutAttributeRight
                                                       multiplier:1.0
                                                       constant:5.0]];
            }
        }
        
        //  prevView = exampleView;
        leftView = exampleView;
        
        UILabel *wordLabel = [self getWordLabel:word score:score wordFont:wordFont];
        wordLabel.textAlignment = isRTL ? NSTextAlignmentRight : NSTextAlignmentLeft;
        [_wordLabels addObject:wordLabel];
        
        [exampleView addSubview:wordLabel];
        
        [self addWordLabelConstraints:exampleView wordLabel:wordLabel];
        
        NSString *phoneToShow = [self getPhonesWithinWord:wend wstart:wstart phoneAndScore:phoneAndScore];
        
        //        NSLog(@"phone to show %@",phoneToShow);
        
        NSMutableAttributedString *coloredPhones = [self getColoredPhones:phoneToShow wend:wend wstart:wstart phoneAndScore:phoneAndScore];
        
        UILabel *phoneLabel = [self getPhoneLabel:isRTL coloredPhones:coloredPhones phoneFont:wordFont];
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
    if (leftView != nil)  {
        // the right side of the last word is the same as the left side of the right side spacer
        if (numLines == 0) {
            if (isRTL) {
                [_scoreDisplayContainer addConstraint:[NSLayoutConstraint
                                                       constraintWithItem:leftView
                                                       attribute:NSLayoutAttributeLeft
                                                       relatedBy:NSLayoutRelationEqual
                                                       toItem:spacerLeft
                                                       attribute:NSLayoutAttributeRight
                                                       multiplier:1.0
                                                       constant:-5.0]];
            }
            else {
                [_scoreDisplayContainer addConstraint:[NSLayoutConstraint
                                                       constraintWithItem:leftView
                                                       attribute:NSLayoutAttributeRight
                                                       relatedBy:NSLayoutRelationEqual
                                                       toItem:spacerRight
                                                       attribute:NSLayoutAttributeLeft
                                                       multiplier:1.0
                                                       constant:-5.0]];
            }
        }
        else {
            if (isRTL) {
                [_scoreDisplayContainer addConstraint:[NSLayoutConstraint
                                                       constraintWithItem:leftView
                                                       attribute:NSLayoutAttributeLeft
                                                       relatedBy:NSLayoutRelationLessThanOrEqual
                                                       toItem:spacerLeft
                                                       attribute:NSLayoutAttributeRight
                                                       multiplier:1.0
                                                       constant:5.0]];
            }
            else {
                [_scoreDisplayContainer addConstraint:[NSLayoutConstraint
                                                       constraintWithItem:leftView
                                                       attribute:NSLayoutAttributeRight
                                                       relatedBy:NSLayoutRelationLessThanOrEqual
                                                       toItem:spacerRight
                                                       attribute:NSLayoutAttributeLeft
                                                       multiplier:1.0
                                                       constant:5.0]];
            }
        }
        
        [_scoreDisplayContainer addConstraint:[NSLayoutConstraint
                                               constraintWithItem:lineStart
                                               attribute:NSLayoutAttributeBottom
                                               relatedBy:NSLayoutRelationEqual
                                               toItem:_scoreDisplayContainer
                                               attribute:NSLayoutAttributeBottom
                                               multiplier:1.0
                                               constant:0.0]];
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

- (UIColor *) getColorPhones:(float) score {
    if (score > 1.0) score = 1.0;
    if (score < 0)  score = 0;
    
    float alpha = 1;
    if (score > 0.53) alpha = 0.5;
    
    float red   = fmaxf(0,(255 - (fmaxf(0, score-0.5)*2*255)));
    float green = fminf(255, score*2*255);
    float blue  = 0;
    
    red /= 255;
    green /= 255;
    blue /= 255;
    
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

- (void)cacheAudio:(NSArray *)items
{
    NSLog(@"--- cacheAudio cache for %lu",(unsigned long)[items count]);
    
    if (_url == NULL) {
        _url = [[EAFGetSites new] getServerURL];
    }
    [_audioCache cacheAudio:items url:_url];
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
    popupController.playAudio = _isAudioOnSelected;
    // NSLog(@"ContextEnglish===== %@ ", popupController.fl);
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
- (IBAction)ShowMoreSelectPopup:(id)sender {
    [_myAudioPlayer stopAudio];
    [self stopAutoPlay];
    _moreSelectButton.selected = !_moreSelectButton.selected;
    _moreSelectButton.color = _moreSelectButton.selected ?[UIColor npDarkBlue]:[UIColor npLightBlue];
    _moreSelectionPopupView = [[EAFMoreSelectionPopupViewController alloc] init];
    
    [[MZFormSheetController appearance] setCornerRadius:20.0];
    EAFMoreSelectionPopupViewController *selectionPopupController = [self.storyboard instantiateViewControllerWithIdentifier:@"SelectionPopover"];
    _moreSelectionPopupView = selectionPopupController;
    
    _moreSelectionPopupView.language = [self getProjectLanguage];
    
    _moreSelectionPopupView.fl = [[self getCurrentJson] objectForKey:@"fl"];
    
    _moreSelectionPopupView.customDelegate = self;
    _moreSelection.languageIndex = _languageSegmentIndex;
    _moreSelection.voiceIndex = _voiceSegmentIndex;
    [_moreSelectionPopupView setMoreSelection:_moreSelection];
    
    //    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didDismissPopupViewController) name:@"PopupSelectionViewDissmissed" object:nil];
    
    MZFormSheetController *formSheet = [self isiPhone] ?
    //        [[MZFormSheetController alloc] initWithViewController:popupController] :
    [[MZFormSheetController alloc] initWithSize:CGSizeMake(300, 300) viewController:selectionPopupController] :
    [[MZFormSheetController alloc] initWithSize:CGSizeMake(500, 500) viewController:selectionPopupController];
    
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
    NSLog(@"Reco flashcard - Got segue!!! chapter %@ = %@ ", _chapterTitle, _currentChapter);
    @try {
        EAFScoreReportTabBarController *tabBarController = [segue destinationViewController];
        tabBarController.url = _url;
        
        EAFWordScoreTableViewController *wordReport = [[tabBarController viewControllers] objectAtIndex:0];
        wordReport.tabBarItem.image = [[UIImage imageNamed:@"rightAndWrong_26h-unselected"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        wordReport.tabBarItem.selectedImage = [[UIImage imageNamed:@"rightAndWrong_26h-selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        [wordReport.tabBarItem setTitleTextAttributes:@{ NSForegroundColorAttributeName : [UIColor npDarkBlue] }
                                             forState:UIControlStateSelected];
        
        wordReport.language = _language;
        wordReport.projid = [self getProjectID];
        wordReport.chapterName = _chapterTitle;
        wordReport.chapterSelection = _currentChapter;
        
        wordReport.unitName = _unitTitle;
        wordReport.unitSelection = _currentUnit;
        
        wordReport.jsonItems = _jsonItems;
        wordReport.url = _url;
        wordReport.listid = _listid;
        wordReport.showSentences = _showSentences;
        wordReport.isQuiz = [self isAQuiz];
        
        
        NSMutableDictionary *exToFL = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *exToEnglish = [[NSMutableDictionary alloc] init];
        
        for (NSDictionary *jsonObject in _jsonItems) {
            NSString *id = [jsonObject objectForKey:@"id"];
            NSString *exercise = [jsonObject objectForKey:@"fl"];
            NSString *englishPhrases = [jsonObject objectForKey:@"en"];
            //         NSString *tlExercise = [jsonObject objectForKey:@"tl"];
            [exToFL setValue:exercise forKey:id];
            [exToEnglish setValue:englishPhrases forKey:id];
        }
        
        // NSLog(@"setting exToFl to %lu",(unsigned long)exToFL.count);
        wordReport.exToFL = exToFL;
        wordReport.exToEnglish = exToEnglish;
        
        EAFPhoneScoreTableViewController *phoneReport = [[tabBarController viewControllers] objectAtIndex:1];
        phoneReport.tabBarItem.selectedImage = [[UIImage imageNamed:@"checkAndEar.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        phoneReport.tabBarItem.image = [[UIImage imageNamed:@"ear-unselected_32.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        
        [phoneReport.tabBarItem setTitleTextAttributes:@{ NSForegroundColorAttributeName : [UIColor npDarkBlue] }
                                              forState:UIControlStateSelected];
        
        phoneReport.language = _language;
        
        
        phoneReport.projid = [self getProjectID];
        
        phoneReport.chapterName = _chapterTitle;
        phoneReport.chapterSelection = _currentChapter;
        
        phoneReport.unitName = _unitTitle;
        phoneReport.unitSelection = _currentUnit;
        
        phoneReport.url = _url;
        phoneReport.isRTL = [_siteGetter.rtlLanguages containsObject:_language];
        
        phoneReport.listid = _listid;
        NSLog(@"\n\tusing session id %ld",_lastSessionTimeStamp);
        phoneReport.sessionid = [NSNumber numberWithLong:_lastSessionTimeStamp];
        phoneReport.sentencesOnly = _showSentences;
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
