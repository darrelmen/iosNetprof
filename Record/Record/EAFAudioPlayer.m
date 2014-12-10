//
//  EAFAudioPlayer.m
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 12/10/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import "EAFAudioPlayer.h"
#import "FAImageView.h"

@interface EAFAudioPlayer ()

@property FAImageView *playingIcon;

@end

@implementation EAFAudioPlayer

- (instancetype)init
{
    self = [super init];
    if (self) {
        _playingIcon = [[FAImageView alloc] initWithFrame:CGRectMake(0.f, 0.f, 22.f, 22.f)];
        _playingIcon.image = nil;
        [_playingIcon setDefaultIconIdentifier:@"fa-volume-up"];
        _playingIcon.defaultView.textColor = [UIColor blueColor];
        _currentIndex = 0;
    }
    return self;
}

//EAFAudioView * currentAudioSelection;
//bool playingRef = TRUE;
FAImageView *audioPlayerplayingIcon;

// look for local file with mp3 and use it if it's there.
- (IBAction)playRefAudio {
   // NSString *refPath = playingRef ? sender.refAudio : sender.answer;
    if (_audioPaths.count == 0) {
        return;
    }
    NSString *refPath = [_audioPaths objectAtIndex:_currentIndex];//playingRef ? sender.refAudio : sender.answer;
    //   NSLog(@"ref path %@ playing ref %@",refPath, (playingRef ? @"YES":@"NO"));
    
    NSString *refAudioPath;
    NSString *rawRefAudioPath;
    
    //if (refPath) {
        //  NSLog(@"has ref path %@",refPath);
        refPath = [refPath stringByReplacingOccurrencesOfString:@".wav"
                                                     withString:@".mp3"];
        
        NSMutableString *mu = [NSMutableString stringWithString:refPath];
        [mu insertString:_url atIndex:0];
        refAudioPath = mu;
        rawRefAudioPath = refPath;
//    }
//    else {
//        //  NSLog(@"does not have ref path %@",refPath);
//        
//        refAudioPath = @"NO";
//        rawRefAudioPath = @"NO";
//        playingRef = FALSE;
//        [self playRefAudio:viewToAddIconTo];
//        return;
//    }
    
    NSURL *url = [NSURL URLWithString:refAudioPath];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *audioDir = [NSString stringWithFormat:@"%@_audio",_language];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:audioDir];
    
    NSString *destFileName = [filePath stringByAppendingPathComponent:rawRefAudioPath];
    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:destFileName];
    if (fileExists) {
        //NSLog(@"playRefAudio Raw URL %@", _rawRefAudioPath);
        NSLog(@"using local url %@",destFileName);
        url = [[NSURL alloc] initFileURLWithPath: destFileName];
    }
    else {
        NSLog(@"can't find local url %@",destFileName);
        NSLog(@"playRefAudio URL     %@", url);
    }
    NSString *PlayerStatusContext;
    
    if (_player) {
        [_player pause];
        NSLog(@"removing current observer");
        
        [self removePlayObserver];
    }
    
    UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
    AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
    AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,sizeof (audioRouteOverride),&audioRouteOverride);
    
    _player = [AVPlayer playerWithURL:url];
    
    [_player addObserver:self forKeyPath:@"status" options:0 context:&PlayerStatusContext];
}

- (void)removePlayingAudioIcon {
    for (UIView *v in [_viewToAddIconTo subviews]) {
        if (v == _playingIcon) {
            [v removeFromSuperview];
        }
    }
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    NSLog(@" playerItemDidReachEnd");
    
    [self removePlayingAudioIcon];
    
    if (_currentIndex < _audioPaths.count-1) {
        _currentIndex++;
        [self playRefAudio];
    }
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    NSLog(@"Got error %@", error);
    [self removePlayingAudioIcon];
}


// So this is more complicated -- we have to wait until the mp3 has arrived from the server before we can play it
// we remove the observer, or else we will later get a message when the player discarded
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    //NSLog(@" observeValueForKeyPath %@",keyPath);
    
    if (object == _player && [keyPath isEqualToString:@"status"]) {
        if (_player.status == AVPlayerStatusReadyToPlay) {
            NSLog(@" audio ready so playing...");
            [_viewToAddIconTo addSubview:_playingIcon];
            
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
            [self removePlayingAudioIcon];
            
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
    NSLog(@" remove observer");
    
    @try {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:[_player currentItem]];
        [_player removeObserver:self forKeyPath:@"status"];
    }
    @catch (NSException *exception) {
        NSLog(@"initial create - got exception %@",exception.description);
    }
}


@end
