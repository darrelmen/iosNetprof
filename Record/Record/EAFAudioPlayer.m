//
//  EAFAudioPlayer.m
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 12/10/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import "EAFAudioPlayer.h"

@interface EAFAudioPlayer ()

@property AVPlayer *player;
@end

@implementation EAFAudioPlayer

- (instancetype)init
{
    self = [super init];
    if (self) {
        _currentIndex = 0;
        _volume = 1;
    }
    return self;
}

- (IBAction)stopAudio {
    NSLog(@"stopAudio ---- %@",self);
    _currentIndex = _audioPaths.count;
    if (_player != nil) {
        [_player pause];
        [self removePlayObserver];
    }
    [self.delegate playStopped];
}

- (IBAction)playRefAudio {
    _currentIndex = 0;
   
    [self playRefAudioInternal];
}

// look for local file with mp3 and use it if it's there.
- (IBAction)playRefAudioInternal {
   // NSLog(@"playRefAudioInternal using paths %@",_audioPaths);

    if (_audioPaths.count == 0) {
        return;
    }
    NSString *refPath = [_audioPaths objectAtIndex:_currentIndex];
    
    NSString *refAudioPath;
    NSString *rawRefAudioPath;
    
    refPath = [refPath stringByReplacingOccurrencesOfString:@".wav"
                                                 withString:@".mp3"];
    
    NSMutableString *mu = [NSMutableString stringWithString:refPath];
    [mu insertString:_url atIndex:0];
    refAudioPath = mu;
    rawRefAudioPath = refPath;
    
    NSURL *url = [NSURL URLWithString:refAudioPath];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *audioDir = [NSString stringWithFormat:@"%@_audio",_language];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:audioDir];
    
    NSString *destFileName = [filePath stringByAppendingPathComponent:rawRefAudioPath];
    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:destFileName];
    if (fileExists) {
        //NSLog(@"playRefAudio Raw URL %@", _rawRefAudioPath);
        NSLog(@"playRefAudio using local url %@",destFileName);
        url = [[NSURL alloc] initFileURLWithPath: destFileName];
    }
    else {
        NSLog(@"playRefAudio can't find local url %@",destFileName);
        NSLog(@"playRefAudio URL     %@", url);
    }
    NSString *PlayerStatusContext;
    
    if (_player) {
        [_player pause];
        //NSLog(@" playRefAudioInternal : removing current observer");
        [self removePlayObserver];
    }
    
    UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
    AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
    AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,sizeof (audioRouteOverride),&audioRouteOverride);
    
    _player = [AVPlayer playerWithURL:url];
     _player.volume = _volume;
    [_player addObserver:self forKeyPath:@"status" options:0 context:&PlayerStatusContext];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
  //  NSLog(@" playerItemDidReachEnd for this %@ for %@",self,_audioPaths);
    NSLog(@" playerItemDidReachEnd for this %@ ",self);
    
    [self.delegate playStopped];
    
   // NSLog(@" - playerItemDidReachEnd called self delegate - play stopped");

    if (_currentIndex < _audioPaths.count-1) {
       // NSLog(@" - playerItemDidReachEnd playing next audio...");
        _currentIndex++;
        [self playRefAudioInternal];
    }
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    NSLog(@"Got error %@", error);
    [self.delegate playStopped];
}

// So this is more complicated -- we have to wait until the mp3 has arrived from the server before we can play it
// we remove the observer, or else we will later get a message when the player discarded
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
   // NSLog(@" observeValueForKeyPath %@",keyPath);
    
    if (object == _player && [keyPath isEqualToString:@"status"]) {
        if (_player.status == AVPlayerStatusReadyToPlay) {
            NSLog(@" audio ready so playing...");
            [self.delegate playStarted];

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
            [self.delegate playStopped];

            UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Connection problem" message: @"Couldn't play audio file." delegate: nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            
            //  NSLog(@"player status failed %@",_player.status);
            
            [_player removeObserver:self forKeyPath:@"status"];
        }
    }
    else {
        NSLog(@"ignoring value... %@",keyPath);
    }
}

- (void)removePlayObserver {
   // NSLog(@"paths were %@, remove observer %@",_audioPaths,self);
    
    @try {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:[_player currentItem]];
        [_player removeObserver:self forKeyPath:@"status"];
    }
    @catch (NSException *exception) {
        if (![exception.description containsString:@"registered"]) {
            NSLog(@"removePlayObserver - got exception %@",exception.description);
        }
    }
}

@end
