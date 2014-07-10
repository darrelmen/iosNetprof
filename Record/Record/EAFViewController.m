//
//  EAFViewController.m
//  Record
//
//  Created by Ferme, Elizabeth - 0553 - MITLL on 4/2/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import "EAFViewController.h"

@interface EAFViewController ()

@end

@implementation EAFViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    _playButton.enabled = NO;
    _stopButton.enabled = NO;
    
    
    NSLog(@"viewDidLoad");

    
    NSArray *dirPaths;
    NSString *docsDir;
    
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES);
    docsDir = dirPaths[0];
    
    NSString *soundFilePath = [docsDir stringByAppendingPathComponent:@"sound.caf"];
    NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
    
    NSDictionary *recordSettings = [NSDictionary
                                    dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithInt:AVAudioQualityMin],
                                    AVEncoderAudioQualityKey,
                                    [NSNumber numberWithInt:16],
                                    AVEncoderBitRateKey,
                                    [NSNumber numberWithInt: 2],
                                    AVNumberOfChannelsKey,
                                    [NSNumber numberWithFloat:44100.0],
                                    AVSampleRateKey,
                                    nil];
    
    NSError *error = nil;
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    _audioRecorder = [[AVAudioRecorder alloc]
                      initWithURL:soundFileURL
                      settings:recordSettings
                      error:&error];
    if (error)
    {
        NSLog(@"error: %@", [error localizedDescription]);
    } else {
        [audioSession requestRecordPermission:^(BOOL granted) {
            NSLog(@"record permission is %hhd", granted);
        } ];
        //[_audioRecorder prepareToRecord];
    }
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

- (IBAction)recordAudio:(id)sender {
    if (!_audioRecorder.recording)
    {
        
        NSLog(@"recordAudio");

        _playButton.enabled = NO;
        _stopButton.enabled = YES;
        [_audioRecorder record];
        
        if (_audioRecorder.recording)
        {
            NSLog(@"recordAudio -recording");
        }
        else {
            NSLog(@"recordAudio -DUDE NOT recording");

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
        
        NSString *myString = [_audioRecorder.url absoluteString];
        
        NSLog(@"help %@",_audioRecorder.url.baseURL);
        NSLog(@"url %@",myString);
        
        _audioPlayer = [[AVAudioPlayer alloc]
                        initWithContentsOfURL:_audioRecorder.url
                        error:&error];
        
        _audioPlayer.delegate = self;
        
        if (error)
        {
            
//            NSString *myString2 = [self NSStringFromOSStatus];

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
    
    NSLog(@"stopAudio");
    
    if (_audioRecorder.recording || TRUE)
    {
        NSLog(@"stopAudio -stop");

        [_audioRecorder stop];
        NSString *myString = [_audioRecorder.url absoluteString];

        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:myString];
        
        if (fileExists) NSLog(@"found file %@",myString);
        else {
            NSLog(@"couldn't find file");
        }
        
    } else {
        NSLog(@"stopAudio not recording");

    if (_audioPlayer.playing) {
        [_audioPlayer stop];
    }
    }
}
@end
