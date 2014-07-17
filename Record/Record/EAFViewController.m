//
//  EAFViewController.m
//  Record
//
//  Created by Ferme, Elizabeth - 0553 - MITLL on 4/2/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import "EAFViewController.h"
#import "math.h"

@interface EAFViewController ()

@end

@implementation EAFViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    _playButton.enabled = NO;
    _stopButton.enabled = NO;
    [self setPlayRefEnabled];
    
    //UIImageView *slowAnimationImageView = [[UIImageView alloc] initWithFrame:CGRectMake(160, 95, 86, 193)];
    
    // Load images
    NSArray *imageNames = @[@"media-record-3_32x32.png", @"media-record-4_32x32.png"];
    
    NSMutableArray *images = [[NSMutableArray alloc] init];
    for (int i = 0; i < imageNames.count; i++) {
        [images addObject:[UIImage imageNamed:[imageNames objectAtIndex:i]]];
    }
    
    _recordFeedbackImage.animationImages = images;
    _recordFeedbackImage.animationDuration = 1;
    
    //[self.view addSubview:slowAnimationImageView];

    // Set the audio file
    NSArray *pathComponents = [NSArray arrayWithObjects:
                               [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                               @"MyAudioMemo.wav",
                               nil];
    NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];
    NSError *error = nil;
    
    // Setup audio session
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    
    if (error)
    {
        NSLog(@"error: %@", [error localizedDescription]);
    } else {
        [session requestRecordPermission:^(BOOL granted) {
            NSLog(@"record permission is %hhd", granted);
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
    
    [_foreignLang setText:fl];
    [_english setText:en];
    
    
    //self.annotatedGauge = [[MSAnnotatedGauge alloc] initWithFrame:CGRectMake(40, 40, 240, 180)];
    _annotatedGauge2.minValue = 0;
    _annotatedGauge2.maxValue = 100;
    //_annotatedGauge2.titleLabel.text = @"How many widgets?";
    _annotatedGauge2.startRangeLabel.text = @"0";
    _annotatedGauge2.endRangeLabel.text = @"100";
    _annotatedGauge2.fillArcFillColor = [UIColor colorWithRed:.41 green:.76 blue:.73 alpha:1];
    _annotatedGauge2.fillArcStrokeColor = [UIColor colorWithRed:.41 green:.76 blue:.73 alpha:1];
    _annotatedGauge2.value = 0;
}


- (void)respondToSwipe {
    NSString *flAtIndex = [_items objectAtIndex:_index];
    NSString *enAtIndex = [_englishWords objectAtIndex:_index];
    [_foreignLang setText:flAtIndex];
    [_english setText:enAtIndex];
    _refAudioPath =[_paths objectAtIndex:_index];
    fl = flAtIndex;
    en = enAtIndex;
    [self setPlayRefEnabled];
    
    [_scoreDisplay setText:@" "];
}

- (IBAction)swipeRightDetected:(UISwipeGestureRecognizer *)sender {
    _index--;
    if (_index == -1) _index = _items.count -1;

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


NSString *fl = @"Bueller";
NSString *en = @"Bueller";

-(void) setForeignText:(NSString *)foreignLangText
{
    NSLog(@"setForeignText now %@",foreignLangText);
    fl = foreignLangText;
}

-(void) setEnglishText:(NSString *)english
{
    NSLog(@"setEnglishText now %@",english);
    en = english;
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
    _stopButton.enabled = NO;
}

- (void)audioPlayerDecodeErrorDidOccur:
(AVAudioPlayer *)player error:(NSError *)error
{
    NSLog(@"Decode Error occurred");
}

- (void)audioRecorderDidFinishRecording:
(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
}

- (void)audioRecorderEncodeErrorDidOccur:
(AVAudioRecorder *)recorder error:(NSError *)error
{
    NSLog(@"Encode Error occurred");
}


- (IBAction)playRefAudio:(id)sender {
    
    NSURL *url = [NSURL URLWithString:_refAudioPath];
    
    NSLog(@"playRefAudio URL %@", _refAudioPath);
 
   NSString *ItemStatusContext;
   NSString *PlayerStatusContext;
    
    _playerItem = [AVPlayerItem playerItemWithURL:url];

    [_playerItem addObserver:self forKeyPath:@"status" options:0 context:&ItemStatusContext];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(playerItemDidReachEnd:)
     name:AVPlayerItemDidPlayToEndTimeNotification
     object:_playerItem];

    if (ItemStatusContext != nil) {
        NSLog(@" error %@",ItemStatusContext );
    }
    else {
     //   NSLog(@" got here 3");

    }
    
    if (_player) {
        NSLog(@" remove observer");

        @try {
            [_player removeObserver:self forKeyPath:@"status"];
            //_player = nil;
        }
        @catch (NSException *exception) {
            //NSLog(@"got exception %@",exception.description);
        }
    }
    
   _player = [AVPlayer playerWithPlayerItem:_playerItem];
//
    //if (_player) {
       // [_player removeObserver:self forKeyPath:@"status"];
    //}
   // _player = [AVPlayer playerWithURL:url];
    //NSLog(@" got here 4");
    NSLog(@" add observer");

    [_player addObserver:self forKeyPath:@"status" options:0 context:&PlayerStatusContext];
   
    _playRefAudioButton.enabled = NO;
//    if (error)
//    {
//        NSLog(@"playRefAudio Error: %@",
//              [error localizedDescription]);
//    }
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    NSLog(@" playerItemDidReachEnd");
  //  NSLog(@"Sound finishd %@",notification.name);
    
   _playRefAudioButton.enabled = YES;
}

// So this is more complicated -- we have to wait until the mp3 has arrived from the server before we can play it
// we remove the observer, or else we will later get a message when the player discarded
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    if (object == _player && [keyPath isEqualToString:@"status"]) {
        if (_player.status == AVPlayerStatusReadyToPlay) {
            NSLog(@" audio ready so playing...");
            [_player play];
            
            @try {
                [_player removeObserver:self forKeyPath:@"status"];
                //_player = nil;
            }
            @catch (NSException *exception) {
                NSLog(@"got exception %@",exception.description);
            }

        } else if (_player.status == AVPlayerStatusFailed) {
            // something went wrong. player.error should contain some information
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Connection problem" message: @"Couldn't play audio file." delegate: nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            
            NSLog(@"player status failed");

            [_player removeObserver:self forKeyPath:@"status"];
            //_player = nil;

            _playRefAudioButton.enabled = YES;

        }
    }
    else if (object == _playerItem) {
        //NSLog(@"got item status %@ %d",keyPath,_playerItem.status);
    }
    else {
        NSLog(@"ignoring value... %@",keyPath);
        //[super observeValueForKeyPath:object change:change context:context];
    }
}


- (IBAction)recordAudio:(id)sender {
    if (!_audioRecorder.recording)
    {
        //NSLog(@"recordAudio");

        _playButton.enabled = NO;
        _stopButton.enabled = YES;
        
        AVAudioSession *session = [AVAudioSession sharedInstance];
        
        NSError *error = nil;

        [session setActive:YES error:&error];

        [_audioRecorder record];
        
        if (_audioRecorder.recording)
        {
            NSLog(@"recordAudio -recording");
            [_recordFeedbackImage startAnimating];
            _recordFeedbackImage.hidden = NO;
        }
        else {
            NSLog(@"recordAudio -DUDE NOT recording");
            
            NSLog(@"Domain: %@", error.domain);
            NSLog(@"Error Code: %d", error.code);
            NSLog(@"Description: %@", [error localizedDescription]);
            NSLog(@"Reason: %@", [error localizedFailureReason]);
        }
    }
}
    
- (IBAction)playAudio:(id)sender {
    if (!_audioRecorder.recording)
    {
        
        NSLog(@"playAudio");
        _stopButton.enabled = YES;
        _recordButton.enabled = NO;
        
        NSError *error;
        
        _audioPlayer = [[AVAudioPlayer alloc]
                        initWithContentsOfURL:_audioRecorder.url
                        error:&error];
        
        _audioPlayer.delegate = self;
        
        if (error)
        {
            NSLog(@"Error: %@",
                  [error localizedDescription]);
        } else {
            [_audioPlayer play];
        }
    }
}


- (IBAction)stopAudio:(id)sender {
    _stopButton.enabled = NO;
    _playButton.enabled = YES;
    _recordButton.enabled = YES;
    
    NSLog(@"stopAudio --------- ");
    [_recordFeedbackImage startAnimating];
    _recordFeedbackImage.hidden = YES;
    
    if (_audioRecorder.recording)
    {
        NSLog(@"stopAudio -stop");
        
        [_audioRecorder stop];
        [self postAudio2];
        
    } else {
        NSLog(@"stopAudio not recording");
        
        if (_audioPlayer.playing) {
            [_audioPlayer stop];
        }
    }
}


- (void)startRepeatingTimer {
    // Cancel a preexisting timer.
    
    [self.repeatingTimer invalidate];
    
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1
                                                      target:self selector:@selector(targetMethod:)
                                                    userInfo:[self userInfo] repeats:YES];
    
    self.repeatingTimer = timer;
}

- (NSDictionary *)userInfo {
    return @{ @"StartDate" : [NSDate date] };
}

- (void)targetMethod:(NSTimer*)theTimer {
    NSDate *startDate = [[theTimer userInfo] objectForKey:@"StartDate"];
    NSLog(@"Timer started on %@", startDate);
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
    
    NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
    
    NSLog(@"file length %d",[postData length]);
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
    NSString *postLength = [NSString stringWithFormat:@"%d", [body length]];
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
        //NSRange range = [lower rangeOfString:lowerWord];
        
        NSRange range, searchCharRange;
        
        searchCharRange = NSMakeRange(offset, [lower length]-offset);
        
        //NSLog(@"in %@ looking for %@ and searching at %d %d", lower,lowerWord,searchCharRange.location, searchCharRange.length);

        range = [lower rangeOfString:lowerWord options:0 range:searchCharRange];
       
       // NSLog(@"in %@ looking for %@ and found at %d", lower, lowerWord, range.location);
        if (range.length > 0) {
            UIColor *color = [self getColor2:score.floatValue];
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
