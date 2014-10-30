//
//  EAFViewController.m
//  Record
//
//  Created by Ferme, Elizabeth - 0553 - MITLL on 4/2/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import "EAFRecoFlashcardController.h"
#import "EAFFlashcardViewController.h"
#import "math.h"
#import <AudioToolbox/AudioServices.h>
#import "SSKeychain.h"
#import "UIFont+FontAwesome.h"
#import "NSString+FontAwesome.h"
#import "BButton.h"

@interface EAFRecoFlashcardController ()

@end

@implementation UIProgressView (customView)
- (CGSize)sizeThatFits:(CGSize)size {
    CGSize newSize = CGSizeMake(self.frame.size.width, 9);
    return newSize;
}
@end

@implementation EAFRecoFlashcardController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    _playButton.enabled = NO;
    
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
    
    [session setCategory:AVAudioSessionCategoryRecord error:&error];
    
    if (error)
    {
        NSLog(@"error: %@", [error localizedDescription]);
    } else {
        [session requestRecordPermission:^(BOOL granted) {
            //NSLog(@"record permission is %d", granted);
        } ];
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
        _recordButtonContainer.hidden = true;
    }

    _scoreProgress.hidden = true;
    
    [self respondToSwipe];
    
    [_whatToShow setSelectedSegmentIndex:2];
    [_whatToShow setTitle:_language forSegmentAtIndex:1];
    if ([_language isEqualToString:@"English"]) {
        [_whatToShow setTitle:@"Def." forSegmentAtIndex:0];
    }
    
     _showScores = [BButton awesomeButtonWithOnlyIcon:FATrophy
                                  type: BButtonTypeDefault
                                 style:BButtonStyleBootstrapV3];
   // [_showScores sizeToFit];
    CGRect frame = CGRectMake(32.0f + (0 * 144.0f),
                              40.0f + (1 * 60.0f),
                              112.0f,
                              44.0f);
    
   // _showScores.frame = CGRectMake(_showScores.frame.origin.x, _showScores.frame.origin.y, 112.0f, 44.0f);

    
    BButton * btn = [BButton awesomeButtonWithOnlyIcon:FATrophy
                                                type: BButtonTypeDefault
                                               style:BButtonStyleBootstrapV3];
    [btn addTarget:self action:@selector(showScoresClick:) forControlEvents:UIControlEventTouchUpInside];

    //btn.frame = CGRectMake(frame.origin.x, frame.origin.y, btn.frame.size.width, btn.frame.size.width);
    [_scoreButtonView addSubview:btn];

}

- (IBAction)showScoresClick:(id)sender {
    NSLog(@"got click on show scores");
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
    
    [_foreignLang setText:exercise];
    [_english setText:englishPhrases];
    
 //   _english.lineBreakMode = NSLineBreakByWordWrapping;
 //   _english.numberOfLines = 0;
    
//    _foreignLang.lineBreakMode = NSLineBreakByWordWrapping;
//    _foreignLang.numberOfLines = 0;
    
    _foreignLang.adjustsFontSizeToFitWidth=YES;
    _english.adjustsFontSizeToFitWidth=YES;
   // _english.minimumScaleFactor=0.5;
    
    _scoreDisplay.lineBreakMode = NSLineBreakByWordWrapping;
    _scoreDisplay.numberOfLines = 0;
}

- (unsigned long)getItemIndex {
    unsigned long toUse = _index;
    if ([_shuffleSwitch isOn]) {
        //   NSLog(@"current %lu",_index);
        toUse = [[_randSequence objectAtIndex:_index] integerValue];
        //   NSLog(@"output %lu",toUse);
    }
    else {
      //  NSLog(@"current %lu",_index);

    }
    return toUse;
}

- (BOOL)isTooBig:(UILabel *) label {
    float h;
    h = [self getHeight:label];
    if (h > label.bounds.size.height) {
        NSLog(@"TOO MUCH %f %f",h,label.bounds.size.height);
        return true;
    }
    else {
        NSLog(@"NOT TOO MUCH %f %f",h,label.bounds.size.height);
        return false;
    }
}

- (float)getHeight:(UILabel *)label {
    //NSLog(@"one line height %f", [self expectedHeight:_english]);
    
    CGSize perfectSize = [label.text sizeWithFont:label.font constrainedToSize:CGSizeMake(label.bounds.size.width, NSIntegerMax) lineBreakMode:label.lineBreakMode];
    float h = perfectSize.height;
    return h;
}

- (void)scaleHeight:(UILabel *)label {
    float height = [self getHeight:label];
    float allowed = label.bounds.size.height;
    float newFont = 38*(allowed/height);
    label.font = [UIFont systemFontOfSize:newFont];
}

// so if we swipe while the ref audio is playing, remove the observer that will tell us when it's complete
- (void)respondToSwipe {
    [self removePlayObserver];
    
    [_correctFeedback setHidden:true];
    [_scoreProgress     setProgress:0 ];
    
    unsigned long toUse = [self getItemIndex];
    
    NSDictionary *jsonObject =[_jsonItems objectAtIndex:toUse];

    NSString *refAudio = [[self getCurrentJson] objectForKey:@"ref"];
    NSLog(@"refAudio %@",refAudio);
    
    if ([_genderMaleSelector isOn]) {
        if ([_speedSelector isOn]) {
           NSString *test =  [[self getCurrentJson] objectForKey:@"msr"];
            if (test != NULL && ![test isEqualToString:@"NO"]) {
                refAudio = test;
            }
        }
        else {
            NSString *test =  [[self getCurrentJson] objectForKey:@"mrr"];
            if (test != NULL && ![test isEqualToString:@"NO"]) {
                refAudio = test;
            }
        }
    }
    else {
        if ([_speedSelector isOn]) {
            NSString *test =  [[self getCurrentJson] objectForKey:@"fsr"];
            if (test != NULL && ![test isEqualToString:@"NO"]) {
                refAudio = test;
            }
        }
        else {
            NSString *test =  [[self getCurrentJson] objectForKey:@"frr"];
            if (test != NULL && ![test isEqualToString:@"NO"]) {
                refAudio = test;
            }
        }
    }
    
    NSLog(@"after refAudio %@",refAudio);
        NSString *refPath = refAudio;
        if (refPath) {
            refPath = [refPath stringByReplacingOccurrencesOfString:@".wav"
                                                         withString:@".mp3"];
    
            NSMutableString *mu = [NSMutableString stringWithString:refPath];
            [mu insertString:_url atIndex:0];
            _refAudioPath = mu;
            _rawRefAudioPath = refPath;
        }
        else {
            _refAudioPath = @"NO";
            _rawRefAudioPath = @"NO";
        }
    
    NSString *flAtIndex = [jsonObject objectForKey:@"fl"];
    NSString *enAtIndex = [jsonObject objectForKey:@"en"];
    
    
   // _foreignLang.font = [UIFont systemFontOfSize:38];
  //  _english.font = [UIFont systemFontOfSize:38];

    [_foreignLang setText:flAtIndex];
    [_english setText:enAtIndex];
    
  // [_foreignLang sizeToFit];
  // [_english sizeToFit];
    
    if ([[UIDevice currentDevice].model containsString:@"iPhone"] &&
        [flAtIndex length] > 15) {
        _foreignLang.font = [UIFont systemFontOfSize:24];
    }
    
    if ([[UIDevice currentDevice].model containsString:@"iPhone"] &&
        [enAtIndex length] > 15) {
        _english.font = [UIFont systemFontOfSize:24];
    }

    // final experiment
    // this seems to work on iphone simultor but not on ipad
    
//    NSLog(@"fl height %f", [self expectedHeight:_foreignLang]);
//    NSLog(@"en height %f", [self expectedHeight:_english]);
//    
//    float heightForFL = 2*[self heightOfLabelForText:_foreignLang withText:@"test"];
//    float currHeightFL = [self expectedHeight:_foreignLang];
//    if (currHeightFL > heightForFL) {
//        float newFont = 38*(heightForFL/currHeightFL);
//        _foreignLang.font = [UIFont systemFontOfSize:newFont];
//    }
//    
//    float heightForEN = 2*[self heightOfLabelForText:_english withText:@"test"];
//    float currHeightEN = [self expectedHeight:_english];
//    if (currHeightEN > heightForEN) {
//        float newFont = 38*(heightForEN/currHeightEN);
//        _english.font = [UIFont systemFontOfSize:newFont];
//    }
//    
//    NSLog(@"after fl height %f", [self expectedHeight:_foreignLang]);
//    NSLog(@"after en height %f", [self expectedHeight:_english]);
//    

    
    //if ([self isTooBig:_foreignLang]) {
    //    [self scaleHeight:_foreignLang];
   // }
   // if ([self isTooBig:_english]) {
   //     [self scaleHeight:_english];
   // }
    
//    while ([self isTooBig:_english]) {
//        CGFloat current = _english.font.pointSize;
//        NSLog(@"before %f",current);
//        current -=2;
//        NSLog(@"after %f",current);
//        if (current < 10) break;
//        _english.font = [UIFont systemFontOfSize:current];
//        [_english sizeToFit];
//    }
    
//    perfectSize = [_english.text sizeWithFont:_english.font constrainedToSize:CGSizeMake(_english.bounds.size.width, NSIntegerMax) lineBreakMode:_english.lineBreakMode];
//    if (perfectSize.height > _english.bounds.size.height) {
//        NSLog(@"EN TOO MUCH %f %f",perfectSize.height,_english.bounds.size.height);
//    }
//    else {
//        NSLog(@"EN NOT TOO MUCH %f %f",perfectSize.height,_english.bounds.size.height);
//    }
//    
    [_scoreDisplay setText:@" "];
    _scoreProgress.hidden = true;
    
    if ([_audioOnSelector isOn] && [self hasRefAudio]) {
        [self playRefAudio:nil];
    }
    else {
        NSLog(@"not playing audio at path %@",_refAudioPath);
      //  NSLog(@"audio on %@",[_audioOnSelector isOn]? @"YES" : @"NO");
    }
}

- (float)heightOfLabelForText:(UILabel *)label withText:(NSString *)withText {
    UIFont *font = [UIFont systemFontOfSize:38]; //Warning! It's an example, set the font, you need
    
    NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                          font, NSFontAttributeName,
                                          nil];
    
    CGSize maximumLabelSize = CGSizeMake(label.frame.size.width,9999);
    
    CGRect expectedLabelRect = [withText boundingRectWithSize:maximumLabelSize
                                                      options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                                   attributes:attributesDictionary
                                                      context:nil];
    CGSize *expectedLabelSize = &expectedLabelRect.size;
    
    return expectedLabelSize->height;
}

-(float)expectedHeight:(UILabel *)label{
//    [label setNumberOfLines:0];
//    [label setLineBreakMode:NSLineBreakByWordWrapping];
//    
//    CGSize maximumLabelSize = CGSizeMake(label.frame.size.width,9999);
//    CGSize expectedLabelSize = [[label text] sizeWithFont:[label font]
//                                       constrainedToSize:maximumLabelSize
//                                           lineBreakMode:[label lineBreakMode]];
//    return expectedLabelSize.height;
    
    NSString *withText = [label text];
    return [self heightOfLabelForText:label withText:withText];
}

- (IBAction)swipeRightDetected:(UISwipeGestureRecognizer *)sender {
    _index--;
    if (_index == -1) _index = _jsonItems.count  -1UL;

    [self respondToSwipe];
}

- (IBAction)swipeLeftDetected:(UISwipeGestureRecognizer *)sender {
    _index++;
    if (_index == _jsonItems.count) _index = 0;
    
    [self respondToSwipe];
}


- (IBAction)tapOnForeignDetected:(UITapGestureRecognizer *)sender{
     NSLog(@"tabOnForeignDetected");
    
    if ([_audioOnSelector isOn] && [self hasRefAudio]) {
        [self playRefAudio:nil];
    }
}

- (IBAction)whatToShowSelection:(id)sender {
    long selected = [_whatToShow selectedSegmentIndex];
    if (selected == 0) {
        [_foreignLang setHidden:true];
        [_english setHidden:false];
    }
    else if (selected == 1) {
        [_foreignLang setHidden:false];
        [_english setHidden:true];
    }
    else {
        [_foreignLang setHidden:false];
        [_english setHidden:false];
    }
}

- (IBAction)genderSelection:(id)sender {
    [self respondToSwipe];
}

- (IBAction)speedSelection:(id)sender {
    [self respondToSwipe];
}

- (IBAction)audioOnSelection:(id)sender {
    [self respondToSwipe];
}


//- (void)setPlayRefEnabled
//{
//   // NSLog(@"checking path %@",_refAudioPath);
//    
//    if ([self hasRefAudio]) {
//        _playRefAudioButton.enabled = YES;
//    } else {
//        NSLog(@"disabling button since path %@",_refAudioPath);
//
//        _playRefAudioButton.enabled = NO;
//    }
//}

- (BOOL) hasRefAudio
{
    return _refAudioPath && ![_refAudioPath hasSuffix:@"NO"];
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
    _playButton.enabled = YES;
}

- (void)audioPlayerDecodeErrorDidOccur:
(AVAudioPlayer *)player error:(NSError *)error
{
    NSLog(@"Decode Error occurred");
    
}

- (void)audioRecorderDidFinishRecording:
(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    NSLog(@"audioRecorderDidFinishRecording time = %f",CFAbsoluteTimeGetCurrent());
    _recordButtonContainer.backgroundColor = [UIColor whiteColor];
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:_audioRecorder.url options:nil];
    CMTime time = asset.duration;
    double durationInSeconds = CMTimeGetSeconds(time);
    
    NSLog(@"audioRecorderDidFinishRecording : file duration was %f vs event       %f diff %f",durationInSeconds, (now-then2), (now-then2)-durationInSeconds );
    NSLog(@"audioRecorderDidFinishRecording : file duration was %f vs gesture end %f diff %f",durationInSeconds, (gestureEnd-then2), (gestureEnd-then2)-durationInSeconds );
    
    if (durationInSeconds > 0.3) {
        if (_hasModel) {
           // [self postAudio2];
            [self postAudio];
        }
        else {
            NSLog(@"audioRecorderDidFinishRecording not posting audio since no model...");
        }
    }
    else {
        [_scoreDisplay setText:@"Recording too short."];
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
    //NSLog(@" remove observer");
    
    @try {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:[_player currentItem]];
        [_player removeObserver:self forKeyPath:@"status"];
    }
    @catch (NSException *exception) {
       // NSLog(@"initial create - got exception %@",exception.description);
    }
}

// look for local file with mp3 and use it if it's there.
- (IBAction)playRefAudio:(id)sender {
    NSURL *url = [NSURL URLWithString:_refAudioPath];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];

    NSString *audioDir = [NSString stringWithFormat:@"%@_audio",_language];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:audioDir];
    
    NSString *destFileName = [filePath stringByAppendingPathComponent:_rawRefAudioPath];

    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:destFileName];
    if (fileExists) {
        NSLog(@"playRefAudio Raw URL %@", _rawRefAudioPath);
        NSLog(@"using local url %@",destFileName);
        url = [[NSURL alloc] initFileURLWithPath: destFileName];
    }
    else {
        NSLog(@"can't find local url %@",destFileName);
        NSLog(@"playRefAudio URL     %@", _refAudioPath);
    }
    NSString *PlayerStatusContext;
    
    if (_player) {
        [self removePlayObserver];
    }
    
    UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
    AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
    AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,sizeof (audioRouteOverride),&audioRouteOverride);
    
    _player = [AVPlayer playerWithURL:url];
        
    [_player addObserver:self forKeyPath:@"status" options:0 context:&PlayerStatusContext];
    _playRefAudioButton.enabled = NO;
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    NSLog(@" playerItemDidReachEnd");
   _playRefAudioButton.enabled = YES;
    
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:[_foreignLang text]];
    NSRange range= NSMakeRange(0, [result length]);
    [result removeAttribute:NSBackgroundColorAttributeName range:range];
    [_foreignLang setAttributedText:result];
}

// So this is more complicated -- we have to wait until the mp3 has arrived from the server before we can play it
// we remove the observer, or else we will later get a message when the player discarded
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    //NSLog(@" observeValueForKeyPath %@",keyPath);

    if (object == _player && [keyPath isEqualToString:@"status"]) {
        if (_player.status == AVPlayerStatusReadyToPlay) {
            NSLog(@" audio ready so playing...");
            
            NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:[_foreignLang text]];
 
            NSRange range= NSMakeRange(0, [result length]);
            [result addAttribute:NSBackgroundColorAttributeName
                           value:[UIColor yellowColor]
                           range:range];
            [_foreignLang setAttributedText:result];
            
            [_player play];

            AVPlayerItem *currentItem = [_player currentItem];
            
            [[NSNotificationCenter defaultCenter]
             addObserver:self
             selector:@selector(playerItemDidReachEnd:)
             name:AVPlayerItemDidPlayToEndTimeNotification
             object:currentItem];
            
            @try {
                [_player removeObserver:self forKeyPath:@"status"];
            }
            @catch (NSException *exception) {
                NSLog(@"observeValueForKeyPath : got exception %@",exception.description);
            }

        } else if (_player.status == AVPlayerStatusFailed) {
            // something went wrong. player.error should contain some information
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Connection problem" message: @"Couldn't play audio file." delegate: nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            
            NSLog(@"player status failed");

            [_player removeObserver:self forKeyPath:@"status"];
            _playRefAudioButton.enabled = YES;
        }
    }
    else {
        NSLog(@"ignoring value... %@",keyPath);
    }
}

CFAbsoluteTime then2 ;
CFAbsoluteTime now;

- (void)showRecordingFeedback {
   if (debugRecord) NSLog(@"showRecordingFeedback time = %f",CFAbsoluteTimeGetCurrent());

    _playButton.enabled = NO;
    _recordButton.enabled = NO;
 //   _recordFeedbackImage.hidden = NO;
    _recordButtonContainer.backgroundColor =[UIColor redColor];
}

- (void)logError:(NSError *)error {
    NSLog(@"Domain:      %@", error.domain);
    NSLog(@"Error Code:  %ld", (long)error.code);
    NSLog(@"Description: %@", [error localizedDescription]);
    NSLog(@"Reason:      %@", [error localizedFailureReason]);
}

bool debugRecord = false;

- (IBAction)recordAudio:(id)sender {
    then2 = CFAbsoluteTimeGetCurrent();
    if (debugRecord) NSLog(@"recordAudio time = %f",then2);
  //  _recordInstructions.hidden = YES;
    
    if (!_audioRecorder.recording)
    {
        if (debugRecord) NSLog(@"startRecordingFeedbackWithDelay time = %f",CFAbsoluteTimeGetCurrent());
        [_scoreDisplay setText:@""];

        [self startRecordingFeedbackWithDelay];
        
        NSError *error = nil;
        AVAudioSession *session = [AVAudioSession sharedInstance];
        
        [session setCategory:AVAudioSessionCategoryRecord error:nil];
        [_audioRecorder record];
        
        if (_audioRecorder.recording)
        {
            CFAbsoluteTime recordingBegins = CFAbsoluteTimeGetCurrent();

            if (debugRecord) NSLog(@"recordAudio -recording %f vs begin %f diff %f ",then2,recordingBegins,(recordingBegins-then2));

        }
        else {
           // _recordFeedbackImage.hidden = YES;
            _recordButtonContainer.backgroundColor =[UIColor whiteColor];

            NSLog(@"recordAudio -DUDE NOT recording");
            
            [self logError:error];
        }
    }
}

- (IBAction)swipeUp:(id)sender {
    long selected = [_whatToShow selectedSegmentIndex];
    if (selected == 0 || selected == 1) {
        [_foreignLang setHidden:!_foreignLang.hidden];
        [_english setHidden:!_english.hidden];
    }
}

- (IBAction)swipeDown:(id)sender {
    long selected = [_whatToShow selectedSegmentIndex];
    if (selected == 0 || selected == 1) {
        [_foreignLang setHidden:!_foreignLang.hidden];
        [_english setHidden:!_english.hidden];
    }
}

double gestureEnd;
- (IBAction)longPressAction:(id)sender {
    if (_longPressGesture.state == UIGestureRecognizerStateBegan) {
       [self recordAudio:nil];
    }
    else if (_longPressGesture.state == UIGestureRecognizerStateEnded) {
       // [self stopAudio:nil];
        gestureEnd = CFAbsoluteTimeGetCurrent();
       if (debugRecord)  NSLog(@"longPressAction now  time = %f",gestureEnd);

       [self stopRecordingWithDelay:nil];
    }
}

- (IBAction)playAudio:(id)sender {
    if (!_audioRecorder.recording)
    {
        NSLog(@"playAudio %@",_audioRecorder.url);
        //_recordButton.enabled = NO;
        _playButton.enabled = NO;
        
        NSError *error;
        AVAudioSession *session = [AVAudioSession sharedInstance];

        [session setCategory:AVAudioSessionCategoryPlayback error:nil];
        [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];

        _audioPlayer = [[AVAudioPlayer alloc]
                        initWithContentsOfURL:_audioRecorder.url
                        error:&error];
        
        _audioPlayer.delegate = self;
        
        if (error)
        {
            NSLog(@"Error: %@",
                  [error localizedDescription]);
        } else {
            [_audioPlayer setVolume:3];
            NSLog(@"volume %f",[_audioPlayer volume]);
            [_audioPlayer play];
        }
    }
}

//- (IBAction)singleTap:(id)sender {
//    [self playRefAudio:nil];
//}

- (IBAction)stopAudio:(id)sender {
    now = CFAbsoluteTimeGetCurrent();
  if (debugRecord)  NSLog(@"stopAudio Event duration was %f",(now-then2));
  if (debugRecord)  NSLog(@"stopAudio now  time =        %f",now);
    
    _playButton.enabled = YES;
    _recordButton.enabled = YES;
//    _recordFeedbackImage.hidden = YES;
//    _recordButtonContainer.backgroundColor =[UIColor whiteColor];
    
    if (_audioRecorder.recording)
    {
        NSLog(@"stopAudio stop time = %f",CFAbsoluteTimeGetCurrent());
        [_audioRecorder stop];
        
    } else {
        NSLog(@"stopAudio not recording");
        if (_audioPlayer.playing) {
            [_audioPlayer stop];
        }
    }
}

- (IBAction)stopRecordingWithDelay:sender {
    [NSTimer scheduledTimerWithTimeInterval:0.33
                                     target:self
                                   selector:@selector(stopAudio:)
                                   userInfo:nil
                                    repeats:NO];
    
}

- (IBAction)startRecordingFeedbackWithDelay {
    [NSTimer scheduledTimerWithTimeInterval:0.1
                                     target:self
                                   selector:@selector(showRecordingFeedback)
                                   userInfo:nil
                                    repeats:NO];
    
}

- (NSDictionary *)userInfo {
    return @{ @"StartDate" : [NSDate date] };
}

- (void)invocationMethod:(NSDate *)date {
    NSLog(@"Invocation for timer started on %@", date);
}

- (IBAction)shuffleChange:(id)sender {
    NSLog(@"got shuffleChange");
    
    BOOL value = [_shuffleSwitch isOn];
    if (value) {
        [self doShuffle];
    }
    [self respondToSwipe];
}

- (void)doShuffle {
    _randSequence = [[NSMutableArray alloc] initWithCapacity:_jsonItems.count];
    
    for (unsigned long i = 0; i < _jsonItems.count; i++) {
        [_randSequence addObject:[NSNumber numberWithUnsignedLong:i]];
    }
    
//    NSUInteger count = [newArray count];
//    for (NSUInteger i = 0; i < count; ++i) {
//        // Select a random element between i and end of array to swap with.
//        NSInteger remainingCount = count - i;
//        NSInteger exchangeIndex = i + arc4random_uniform(remainingCount);
//        [newArray exchangeObjectAtIndex:i withObjectAtIndex:exchangeIndex];
//    }
    
    unsigned int max = _jsonItems.count-1;
//    for (unsigned int ii = max; ii > 0; --ii) {
//        unsigned int r = arc4random_uniform(ii)+1;
//        [_randSequence exchangeObjectAtIndex:ii withObjectAtIndex:r];
//    }
    
    for (unsigned int ii = 0; ii < max; ++ii) {
        // Select a random element between i and end of array to swap with.
  //      NSInteger remainingCount = count - i;
    //    NSInteger exchangeIndex = i + arc4random_uniform(remainingCount);
        unsigned int remainingCount = max - ii;

        unsigned int r = arc4random_uniform(remainingCount)+ii;

//        [newArray exchangeObjectAtIndex:i withObjectAtIndex:exchangeIndex];
        
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
    NSLog(@"talking to %@",_url);

   // NSURL *url = [NSURL URLWithString:baseurl];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:baseurl]];
    [urlRequest setHTTPMethod: @"POST"];
    [urlRequest setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [urlRequest setValue:@"application/x-www-form-urlencoded"
      forHTTPHeaderField:@"Content-Type"];
    
    // add request parameters
    
    // old style
    [urlRequest setValue:@"MyAudioMemo.wav" forHTTPHeaderField:@"fileName"];
//    NSString *escapedString = [fl stringByReplacingOccurrencesOfString:@"/" withString:@" "];
 //   NSLog(@"word is %@",escapedString);
  //  [urlRequest setValue:escapedString forHTTPHeaderField:@"word"];
  
//    httpConn.setRequestProperty("fileName", uploadFile.getName());
//    httpConn.setRequestProperty("user", "1");
//    httpConn.setRequestProperty("deviceType", "iPad");
//    httpConn.setRequestProperty("device", "01234567890");
//    httpConn.setRequestProperty("exercise", ""+2549);
//    httpConn.setRequestProperty("request", decode ? "decode" :"align");
    [urlRequest setValue:@"1" forHTTPHeaderField:@"user"]; // TODO : just testing!  Need to find out user id
    [urlRequest setValue:[UIDevice currentDevice].model forHTTPHeaderField:@"deviceType"];
    NSString *retrieveuuid = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"UUID"];

    [urlRequest setValue:retrieveuuid forHTTPHeaderField:@"device"];
    [urlRequest setValue:[[self getCurrentJson] objectForKey:@"id"]
      forHTTPHeaderField:@"exercise"];
    [urlRequest setValue:@"decode" forHTTPHeaderField:@"request"];

    // post the audio
    
    [urlRequest setHTTPBody:postData];
    
    NSURLConnection *connection = [NSURLConnection connectionWithRequest:urlRequest delegate:self];
    [connection start];
    
    NSLog(@"posting to %@",_url);
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:true];
}

-(void)postAudio2 {
    NSString *baseurl = [NSString stringWithFormat:@"%@/scoreServlet", _url];
    //NSLog(@"talking to %@",_url);
    
    [_recoFeedbackImage startAnimating];
    
    NSData *postData = [NSData dataWithContentsOfURL:_audioRecorder.url];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:baseurl]];
    
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setHTTPShouldHandleCookies:NO];
    [request setTimeoutInterval:60];
    [request setHTTPMethod:@"POST"];
    NSString *boundary = @"unique-consistent-string---BOUNDARY---BOUNDARY---BOUNDARY---";
    // set Content-Type in HTTP header
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
    // post body
    NSMutableData *body = [NSMutableData data];
    // add params (all params are strings)
    
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=%@\r\n\r\n", @"word"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSString *escapedString = [[[self getCurrentJson] objectForKey:@"fl"] stringByReplacingOccurrencesOfString:@"/" withString:@" "];
    
    [body appendData:[[NSString stringWithFormat:@"%@\r\n", escapedString] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=%@; filename=MyAudioMemo.wav\r\n", @"audio"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: audio/x-wav\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:postData];
    [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    // setting the body of the post to the reqeust
    [request setHTTPBody:body];
    // set the content-length
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[body length]];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    
    
    NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:self];
    NSLog(@"posting to %@",_url);
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:true];

    [connection start];
}

#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // A response has been received, this is where we initialize the instance var you created
    // so that we can append data to it in the didReceiveData method
    // Furthermore, this method is called each time there is a redirect so reinitializing it
    // also serves to clear it
    _responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // Append the new data to the instance variable you declared
    [_responseData appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // The request is complete and data has been received
    // You can parse the stuff in your instance variable now
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];

    [_recoFeedbackImage stopAnimating];
    //NSString *stringVersion = [[NSString alloc] initWithData:_responseData encoding:NSASCIIStringEncoding];  
    //NSLog(@"go response %@",stringVersion);
    
    NSError * error;
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:_responseData
                          options:NSJSONReadingMutableContainers
                          error:&error];
    
    NSNumber *overallScore = [json objectForKey:@"score"];
    BOOL correct = [[json objectForKey:@"isCorrect"] boolValue];
    NSLog(@"score was %@",overallScore);
    NSLog(@"correct was %@",[json objectForKey:@"isCorrect"]);
    NSLog(@"saidWord was %@",[json objectForKey:@"saidWord"]);
    NSString *valid = [json objectForKey:@"valid"];
    NSLog(@"validity was %@",valid);
    
    // show text highlighted with score per word
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:[_foreignLang text]];
    NSString * lower =[[_foreignLang text] lowercaseString];
    
    NSArray *wordAndScore = [json objectForKey:@"WORD_TRANSCRIPT"];
    
    int offset = 0;
    
    for (NSDictionary *event in wordAndScore) {
        NSString *word = [event objectForKey:@"event"];
        NSNumber *score = [event objectForKey:@"score"];
        NSString *lowerWord = [word lowercaseString];
        NSRange range, searchCharRange;
        
        searchCharRange = NSMakeRange(offset, [lower length]-offset);
        
        range = [lower rangeOfString:lowerWord options:0 range:searchCharRange];
       
        if (range.length > 0) {
            UIColor *color = [self getColor2:score.floatValue];
            if (wordAndScore.count == 1) { // TODO : hack to make score consistent
                color = [self getColor2:overallScore.floatValue];
            }
            [result addAttribute:NSBackgroundColorAttributeName
                           value:color
                           range:range];
            offset += range.length;
        }
    }
    
    if ([valid containsString:@"OK"]) {
        [_scoreDisplay setAttributedText:result];
    }
    else {
        if ([valid containsString:@"MIC"]) {
            [_scoreDisplay setText:@"Please speak louder"];
        }
        else {
            [_scoreDisplay setText:[json objectForKey:@"valid"]];
        }
    }
    _scoreProgress.hidden = false;
    [_scoreProgress setProgress:[overallScore floatValue]];
    [_scoreProgress setProgressTintColor:[self getColor2:[overallScore floatValue]]];
    
    if (correct) {
//        NSLog(@"using checkmark!");
        [_correctFeedback setImage:[UIImage imageNamed:@"checkmark32.png"]];
    }
    else {
  //      NSLog(@"using redx!");
        [_correctFeedback setImage:[UIImage imageNamed:@"redx32.png"]];
    }
    [_correctFeedback setHidden:false];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // The request has failed for some reason!
    // Check the error var
    [_recoFeedbackImage stopAnimating];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Connection problem" message: @"Couldn't connect to server." delegate: nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}


- (UIColor *) getColor2:(float) score {
    if (score > 1.0) score = 1.0;
    if (score < 0)  score = 0;
    
  //  NSLog(@"getColor2 score %f",score);
    
    float red   = fmaxf(0,(255 - (fmaxf(0, score-0.5)*2*255)));
    float green = fminf(255, score*2*255);
    float blue  = 0;
    
    red /= 255;
    green /= 255;
    blue /= 255;
    
    return [UIColor colorWithRed:red green:green blue:blue alpha:1];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
//    NSLog(@"Got segue!!! ");
//    EAFFlashcardViewController *itemController = [segue destinationViewController];
//    
//   // NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
//    //  NSLog(@"row %d",indexPath.row  );
//    //NSString *foreignLanguageItem = [self.items objectAtIndex:indexPath.row];
//   /// NSString *englishItem = [self.englishWords objectAtIndex:indexPath.row];
//    
//    [itemController setForeignText:fl];
//    [itemController setEnglishText:en];
//
//    //[itemController setEnglish:englishItem];
////    [itemController setTranslitText:[self.translitPhrases objectAtIndex:indexPath.row]];
//    itemController.refAudioPath = _refAudioPath;
//    itemController.rawRefAudioPath = _rawRefAudioPath;
//    itemController.index = _index;
//    itemController.items = _items;
//    itemController.language = _language;
//    itemController.englishWords = _englishWords;
//  //  itemController.translitWords = [self translitPhrases];
//    itemController.paths = _paths;
//    itemController.rawPaths = _rawPaths;
//  //  itemController.url = [self getURL];
//    
//    [itemController setTitle:[self title]];
}
@end
