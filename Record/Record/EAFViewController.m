//
//  EAFViewController.m
//  Record
//
//  Created by Ferme, Elizabeth - 0553 - MITLL on 4/2/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import "EAFViewController.h"
#import "MRoundedButton.h"
#import "math.h"
#import <AudioToolbox/AudioServices.h>

@interface EAFViewController ()

@end

@implementation EAFViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    _playButton.enabled = NO;
    
   // _stopButton.enabled = NO;
    [self setPlayRefEnabled];
    
    // Load images
    NSArray *imageNames = @[@"media-record-3_32x32.png", @"media-record-4_32x32.png"];
    
    NSMutableArray *images = [[NSMutableArray alloc] init];
    for (int i = 0; i < imageNames.count; i++) {
        [images addObject:[UIImage imageNamed:[imageNames objectAtIndex:i]]];
    }
    
    _recordFeedbackImage.animationImages = images;
    _recordFeedbackImage.animationDuration = 1;
    _recordFeedbackImage.hidden = YES;
    [_recordFeedbackImage startAnimating];

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
            NSLog(@"record permission is %d", granted);
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
    
    _annotatedGauge2.minValue = 0;
    _annotatedGauge2.maxValue = 100;
//    _annotatedGauge2.startRangeLabel.text = @"0";
//    _annotatedGauge2.endRangeLabel.text = @"100";
    _annotatedGauge2.fillArcFillColor = [UIColor colorWithRed:.41 green:.76 blue:.73 alpha:1];
    _annotatedGauge2.fillArcStrokeColor = [UIColor colorWithRed:.41 green:.76 blue:.73 alpha:1];
    _annotatedGauge2.value = 0;
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

- (void)configureTextFields
{
    [_foreignLang setText:fl];
    [_english setText:en];
    
    _english.lineBreakMode = NSLineBreakByWordWrapping;
    _english.numberOfLines = 0;
    
    [_transliteration setText:tr];
    
    _transliteration.lineBreakMode = NSLineBreakByWordWrapping;
    _transliteration.numberOfLines = 0;
    
    _foreignLang.lineBreakMode = NSLineBreakByWordWrapping;
    _foreignLang.numberOfLines = 0;
    
    _scoreDisplay.lineBreakMode = NSLineBreakByWordWrapping;
    _scoreDisplay.numberOfLines = 0;
}

- (void)respondToSwipe {
    NSString *flAtIndex = [_items objectAtIndex:_index];
    NSString *enAtIndex = [_englishWords objectAtIndex:_index];
    NSString *trAtIndex = [_translitWords objectAtIndex:_index];
    [_foreignLang setText:flAtIndex];
    [_transliteration setText:trAtIndex];
    [_english setText:enAtIndex];
    _refAudioPath =[_paths objectAtIndex:_index];
    _rawRefAudioPath =[_rawPaths objectAtIndex:_index];
    fl = flAtIndex;
    en = enAtIndex;
    tr  = trAtIndex;
    [self setPlayRefEnabled];
    
    [_scoreDisplay setText:@" "];
}

- (IBAction)swipeRightDetected:(UISwipeGestureRecognizer *)sender {
    _index--;
    if (_index == -1) _index = _items.count  -1UL;

    [self respondToSwipe];
}

- (IBAction)swipeLeftDetected:(UISwipeGestureRecognizer *)sender {
    _index++;
    if (_index == _items.count) _index = 0;
    
    [self respondToSwipe];
}

- (void)setPlayRefEnabled
{
    if (_refAudioPath && ![_refAudioPath hasSuffix:@"NO"]) {
        _playRefAudioButton.enabled = YES;
    } else {
        _playRefAudioButton.enabled = NO;
    }
}

NSString *fl = @"";
NSString *en = @"";
NSString *tr = @"";

-(void) setForeignText:(NSString *)foreignLangText
{
//    NSLog(@"setForeignText now %@",foreignLangText);
    fl = foreignLangText;
}

-(void) setEnglishText:(NSString *)english
{
//    NSLog(@"setEnglishText now %@",english);
    en = english;
}

-(void) setTranslitText:(NSString *)translit
{
 //   NSLog(@"setTranslitText now %@",translit);
    tr = translit;
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

    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:_audioRecorder.url options:nil];
    CMTime time = asset.duration;
    double durationInSeconds = CMTimeGetSeconds(time);
    
    NSLog(@"audioRecorderDidFinishRecording : file duration was %f vs event       %f diff %f",durationInSeconds, (now-then2), (now-then2)-durationInSeconds );
    NSLog(@"audioRecorderDidFinishRecording : file duration was %f vs gesture end %f diff %f",durationInSeconds, (gestureEnd-then2), (gestureEnd-then2)-durationInSeconds );
    
    if (durationInSeconds > 0.3) {
        [self postAudio2];
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
        //NSLog(@" remove observer");
        
        @try {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:[_player currentItem]];
            [_player removeObserver:self forKeyPath:@"status"];
        }
        @catch (NSException *exception) {
            NSLog(@"initial create - got exception %@",exception.description);
        }
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
//    NSLog(@" playerItemDidReachEnd");
   _playRefAudioButton.enabled = YES;
}

// So this is more complicated -- we have to wait until the mp3 has arrived from the server before we can play it
// we remove the observer, or else we will later get a message when the player discarded
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    //NSLog(@" observeValueForKeyPath %@",keyPath);

    if (object == _player && [keyPath isEqualToString:@"status"]) {
        if (_player.status == AVPlayerStatusReadyToPlay) {
            NSLog(@" audio ready so playing...");
            
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
    NSLog(@"showRecordingFeedback time = %f",CFAbsoluteTimeGetCurrent());

    _playButton.enabled = NO;
    _recordButton.enabled = NO;
    _recordFeedbackImage.hidden = NO;
}

- (void)logError:(NSError *)error {
    NSLog(@"Domain:      %@", error.domain);
    NSLog(@"Error Code:  %ld", (long)error.code);
    NSLog(@"Description: %@", [error localizedDescription]);
    NSLog(@"Reason:      %@", [error localizedFailureReason]);
}

- (IBAction)recordAudio:(id)sender {
    then2 = CFAbsoluteTimeGetCurrent();
    NSLog(@"recordAudio time = %f",then2);

    if (!_audioRecorder.recording)
    {
        NSLog(@"startRecordingFeedbackWithDelay time = %f",CFAbsoluteTimeGetCurrent());

        [self startRecordingFeedbackWithDelay];
        
        NSError *error = nil;
        AVAudioSession *session = [AVAudioSession sharedInstance];
        
        [session setCategory:AVAudioSessionCategoryRecord error:nil];
        [_audioRecorder record];
        
        if (_audioRecorder.recording)
        {
            CFAbsoluteTime recordingBegins = CFAbsoluteTimeGetCurrent();

            NSLog(@"recordAudio -recording %f vs begin %f diff %f ",then2,recordingBegins,(recordingBegins-then2));

        }
        else {
            _recordFeedbackImage.hidden = YES;
            
            NSLog(@"recordAudio -DUDE NOT recording");
            
            [self logError:error];
        }
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
        NSLog(@"longPressAction now  time = %f",gestureEnd);

         [self stopRecordingWithDelay:nil];
    }
}

- (IBAction)playAudio:(id)sender {
    if (!_audioRecorder.recording)
    {
        
        NSLog(@"playAudio %@",_audioRecorder.url);
        //_stopButton.enabled = YES;
        //_recordButton.enabled = NO;
        
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


- (IBAction)stopAudio:(id)sender {
    now = CFAbsoluteTimeGetCurrent();
    NSLog(@"stopAudio Event duration was %f",(now-then2));
    NSLog(@"stopAudio now  time =        %f",now);
    
    _playButton.enabled = YES;
    _recordButton.enabled = YES;
    _recordFeedbackImage.hidden = YES;
    
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

// Posts audio with current fl field
- (void)postAudio {
    // create request
   // NSString *myString = [_audioRecorder.url absoluteString];
 //   NSLog(@"postAudio file %@",myString);
    [_recoFeedbackImage startAnimating];
    
    NSData *postData = [NSData dataWithContentsOfURL:_audioRecorder.url];
    
   // NSLog(@"data %d",[postData length]);
    
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
    
   // NSLog(@"file length %@",postLength);
    NSString *baseurl = [NSString stringWithFormat:@"%@/scoreServlet", _url];
    NSLog(@"talking to %@",_url);

    NSURL *url = [NSURL URLWithString:baseurl];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    [urlRequest setHTTPMethod: @"POST"];
    [urlRequest setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [urlRequest setValue:@"application/x-www-form-urlencoded"
      forHTTPHeaderField:@"Content-Type"];
    [urlRequest setValue:@"MyAudioMemo.wav" forHTTPHeaderField:@"fileName"];
    
    NSLog(@"word is %@",fl);
    [urlRequest setValue:fl forHTTPHeaderField:@"word"];
    [urlRequest setHTTPBody:postData];
    
    NSURLConnection *connection = [NSURLConnection connectionWithRequest:urlRequest delegate:self];
    [connection start];
}

-(void)postAudio2 {
    NSString *baseurl = [NSString stringWithFormat:@"%@/scoreServlet", _url];
    NSLog(@"talking to %@",_url);
    
    [_recoFeedbackImage startAnimating];
    
    NSData *postData = [NSData dataWithContentsOfURL:_audioRecorder.url];

  //  NSURL *url = [NSURL URLWithString:baseurl];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:baseurl]];
   // NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
    
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
    //[request setValue:@"MyAudioMemo.wav" forHTTPHeaderField:@"fileName"];

    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=%@\r\n\r\n", @"word"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"%@\r\n", fl] dataUsingEncoding:NSUTF8StringEncoding]];
    // add image data
//    if (imageData) {
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=%@; filename=MyAudioMemo.wav\r\n", @"audio"] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Type: audio/x-wav\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:postData];
        [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
  //  }
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    // setting the body of the post to the reqeust
    [request setHTTPBody:body];
    // set the content-length
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[body length]];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    
    
    NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:self];
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
    
    [_recoFeedbackImage stopAnimating];
    //NSString *stringVersion = [[NSString alloc] initWithData:_responseData encoding:NSASCIIStringEncoding];  
    //NSLog(@"go response %@",stringVersion);
    
    NSError * error;
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:_responseData
                          options:NSJSONReadingMutableContainers
                          error:&error];
    
    NSNumber *value = [json objectForKey:@"score"];
    //    NSLog(@"value is %@",value);
    // this doesn't seem to work...
    _annotatedGauge2.titleLabel.text = [value stringValue];
    [_annotatedGauge2 setFillArcFillColor:[self getColor2:value.floatValue]];
    _annotatedGauge2.value =value.floatValue*100;
    
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
        
        //NSLog(@"in %@ looking for %@ and searching at %d %d", lower,lowerWord,searchCharRange.location, searchCharRange.length);

        range = [lower rangeOfString:lowerWord options:0 range:searchCharRange];
       
       // NSLog(@"in %@ looking for %@ and found at %d", lower, lowerWord, range.location);
        if (range.length > 0) {
            UIColor *color = [self getColor2:score.floatValue];
            if (wordAndScore.count == 1) {
                color = [self getColor2:value.floatValue];
            }
            [result addAttribute:NSBackgroundColorAttributeName
                           value:color
                           range:range];
            offset += range.length;
        }
    }
    
    [_scoreDisplay setAttributedText:result];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // The request has failed for some reason!
    // Check the error var
    [_recoFeedbackImage stopAnimating];

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

@end
