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
//  EAFAudioPlayer.m
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 12/10/14.
//  Copyright (c) 2011-2016 Massachusetts Institute of Technology, Lincoln Laboratory
//

#import "EAFAudioPlayer.h"
#import "EAFEventPoster.h"

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
    NSLog(@"EAFAudioPlayer : stopAudio ---- %@",self);
    [self postEvent:@"EAFAudio : stopAudio" widget:@"stopAudio" type:@"Button"];
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

- (IBAction)playFirstRefAudio {
    _currentIndex = 0;
    
    [self playRefAudioInternal];
    _currentIndex = 99;

}

// @see #makePlayerGivenURL
- (void)makeAVPlayer:(NSURL *)url {
    NSLog(@"EAFAudioPlayer : makeAVPlayer ---- %@",url);
    if (url != nil) {
        _player = [AVPlayer playerWithURL:url];
        NSString *PlayerStatusContext;
        [_player addObserver:self forKeyPath:@"status" options:0 context:&PlayerStatusContext];
        _player.volume = _volume;
    }
    else {
        [self postEvent:@"EAFAudio : makeAVPlayer null url?" widget:@"makeAVPlayer" type:@"Button"];
    }
}

// Maybe this is overkill, but try to read from the url and if it fails, try the waveURL
// for the original wav file on the server (somehow perhaps an mp3 file was not created?)
//
- (void)makePlayerGivenURL:(NSURL *)url waveURL:(NSURL *)waveURL {
   // NSLog(@"makePlayerGivenURL checking %@ scheme %@",url, [url scheme]);

    BOOL isValid;
    
    if ([[url scheme] hasPrefix:@"file"]) {
      //  NSLog(@"makePlayerGivenURL reading file %@",url);
        NSDictionary * dict = [self id3TagsForURL:url];
        isValid = dict != nil;
    }
    else {
        //NSLog(@"makePlayerGivenURL reading url %@",url);
        isValid  = [self webFileExists:url];
    }

//    NSLog(@"reading %@ header - %@",url,dict);
    if (!isValid) {
        BOOL val  = [self webFileExists:waveURL];
        if (val) {
//            NSLog(@"trying again - reading %@ header - %@",waveURL,dict);
            [self makeAVPlayer:waveURL];
        }
        else {
            [self postEvent:[NSString stringWithFormat:@"EAFAudio : can't find %@ on server",waveURL] widget:@"makePlayerGivenURL" type:@"Button"];
            NSLog(@"makePlayerGivenURL can't find %@ on server",waveURL);
        }
    }
    else {
        [self makeAVPlayer:url];
    }
}

// The purpose here is defensive - if the mp3 is truncated, you can't read the header, so you can't get the tags dictionary
// if you can get the dictionary, the mp3 file is valid and can be played.

- (NSDictionary *)id3TagsForURL:(NSURL *)resourceUrl
{
    AudioFileID fileID;
    
 //   NSLog(@"id3TagsForURL get tags for '%@'", resourceUrl);
 //   CFURLRef test = (__bridge CFURLRef)resourceUrl;
   // NSLog(@"id3TagsForURL get tags for test '%@'", test);

    OSStatus result = AudioFileOpenURL((__bridge CFURLRef)resourceUrl, kAudioFileReadPermission, 0, &fileID);
    
    if (result != noErr) {
        NSLog(@"id3TagsForURL Error reading tags for %@: %i", resourceUrl, (int)result);
        return nil;
    }
    
    CFDictionaryRef piDict = nil;
    UInt32 piDataSize = sizeof(piDict);
    
    result = AudioFileGetProperty(fileID, kAudioFilePropertyInfoDictionary, &piDataSize, &piDict);
    if (result != noErr)
        NSLog(@"Error reading tags. AudioFileGetProperty failed");
    
    AudioFileClose(fileID);
    
    NSDictionary *tagsDictionary = [NSDictionary dictionaryWithDictionary:(__bridge NSDictionary*)piDict];
    CFRelease(piDict);
    
    return tagsDictionary;
}

-(BOOL) webFileExists:(NSURL *) url
{
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5.0];
    [request setHTTPMethod:@"HEAD"];
    NSHTTPURLResponse* response = nil;
    NSError* error = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
   // NSLog(@"statusCode = %ld", (long)[response statusCode]);
    return [response statusCode] == 404 ? NO : YES;
}

- (NSString *)getCacheMP3:(NSString *)rawRefAudioPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *audioDir = [NSString stringWithFormat:@"%@_audio",_language];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:audioDir];
    
    NSString *destFileName = [filePath stringByAppendingPathComponent:rawRefAudioPath];
    return destFileName;
}

- (void)postEvent:(NSString *) message widget:(NSString *) widget type:(NSString *) type {
    [_poster postEvent:message exid:@"unk" widget:widget widgetType:type];
}

- (NSString *)getRefAudioPathURL:(NSString *)mp3RefPath {
    NSMutableString *mu = [NSMutableString stringWithString:mp3RefPath];
    [mu insertString:_url atIndex:0];
    NSString *refAudioPathURL = mu;
    return refAudioPathURL;
}

// look for local file with mp3 and use it if it's there.
// otherwise hit the URL on the server.
- (IBAction)playRefAudioInternal {
  //  NSLog(@"playRefAudioInternal using paths %@",_audioPaths);
    [self postEvent:[NSString stringWithFormat:@"EAFAudio : playRefAudioInternal using paths %@",_audioPaths] widget:@"playRefAudioInternal" type:@"Button"];

    if (_audioPaths.count == 0) {
        return;
    }
    NSString *origRefPath = [_audioPaths objectAtIndex:_currentIndex];
    
    NSString *wavAudioPath;
    NSString *rawRefAudioPath;
    
    NSString *mp3RefPath = [origRefPath stringByReplacingOccurrencesOfString:@".wav"
                                                 withString:@".mp3"];
    wavAudioPath = [NSString stringWithFormat:@"%@%@",_url,origRefPath];
    rawRefAudioPath = mp3RefPath;
    
    NSURL *url = [NSURL URLWithString:[self getRefAudioPathURL:mp3RefPath]];
    NSURL *waveUrl = [NSURL URLWithString:wavAudioPath];
    NSLog(@"playRefAudioInternal default URL %@",url);
    NSLog(@"playRefAudioInternal waveUrl URL %@",waveUrl);

    NSString *destFileName = [self getCacheMP3:rawRefAudioPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:destFileName]) {
        //NSLog(@"playRefAudio Raw URL %@", _rawRefAudioPath);
        //      NSError *attributesError = nil;
        //NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:destFileName error:&attributesError];
        //NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
        
      //  NSLog(@"playRefAudio using local url %@ size %@",destFileName,fileSizeNumber);
       // NSLog(@"playRefAudio using local url %@",destFileName);
        
        NSURL *testURL = [[NSURL alloc] initFileURLWithPath: destFileName];
     
      //  NSLog(@"playRefAudioInternal testURL - %@",testURL);
        [self postEvent:[NSString stringWithFormat:@"playRefAudioInternal found local url %@",testURL] widget:@"playRefAudioInternal" type:@"Button"];

        NSDictionary * dict = [self id3TagsForURL:testURL];
      //  NSLog(@"file exists - checking header - %@",dict);
        if (dict == nil) {
            [self postEvent:[NSString stringWithFormat:@"playRefAudioInternal mp3 at %@ was corrupt?",testURL] widget:@"playRefAudioInternal" type:@"Button"];
            NSLog(@"warning : mp3 at %@ was corrupt?", testURL);
        } else {
          //  NSLog(@"playRefAudio using local header %@ url %@",dict,destFileName);
            url = testURL;
        }
    }
    else {
        [self postEvent:[NSString stringWithFormat:@"playRefAudioInternal can't find local url %@",destFileName] widget:@"playRefAudioInternal" type:@"Button"];

        NSLog(@"playRefAudio can't find local url %@",destFileName);
        NSLog(@"playRefAudio URL     %@", url);
    }
    
    if (_player) {
        [_player pause];
     //   NSLog(@" playRefAudioInternal : removing current observer");
        [self removePlayObserver];
    }
    
    UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
    AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
    AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,sizeof (audioRouteOverride),&audioRouteOverride);
    
    [self makePlayerGivenURL:url waveURL:waveUrl];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    //NSLog(@" playerItemDidReachEnd for this %@ ",self);
    
    [self.delegate playStopped];
    [self.delegate playGotToEnd];
    
   // NSLog(@" - playerItemDidReachEnd called self delegate - play stopped");

    [self postEvent:[NSString stringWithFormat:@"EAFAudio playerItemDidReachEnd got to end of item #%lu",_currentIndex] widget:@"playerItemDidReachEnd" type:@"Button"];

    if (_currentIndex < _audioPaths.count-1) {
       // NSLog(@" - playerItemDidReachEnd playing next audio...");
        _currentIndex++;
        [self playRefAudioInternal];
    }
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    NSLog(@"Got error %@", error);
    [self postEvent:@"EAFAudio audioPlayerDecodeErrorDidOccur" widget:@"audioPlayerDecodeErrorDidOccur" type:@"Button"];
    [self.delegate playStopped];
}

// So this is more complicated -- we have to wait until the mp3 has arrived from the server before we can play it
// we remove the observer, or else we will later get a message when the player discarded
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
   // NSLog(@" observeValueForKeyPath %@",keyPath);
    
    if (object == _player && [keyPath isEqualToString:@"status"]) {
        if (_player.status == AVPlayerStatusReadyToPlay) {
            [self removeStatusObserver];
            
            NSLog(@"observeValueForKeyPath audio ready so playing...");
            
            [self postEvent:@"EAFAudio observeValueForKeyPath audio ready" widget:@"observeValueForKeyPath" type:@"Button"];

            // GAH what thread should we do this on???
            [self.delegate playStarted];
            
            AVPlayerItem *currentItem = [_player currentItem];
            
            [self postEvent:[NSString stringWithFormat:@"EAFAudio before current item %@",currentItem] widget:@"observeValueForKeyPath" type:@"Button"];
            [self postEvent:[NSString stringWithFormat:@"EAFAudio before current item status %ld",(long)[currentItem status]] widget:@"observeValueForKeyPath" type:@"Button"];
            [self postEvent:[NSString stringWithFormat:@"EAFAudio before player status %ld",(long)[_player status]] widget:@"observeValueForKeyPath" type:@"Button"];
            
            [_player play];
            
            [self postEvent:[NSString stringWithFormat:@"EAFAudio after current item %@",currentItem] widget:@"observeValueForKeyPath" type:@"Button"];
            [self postEvent:[NSString stringWithFormat:@"EAFAudio after current item status %ld",(long)[currentItem status]] widget:@"observeValueForKeyPath" type:@"Button"];

            
            [[NSNotificationCenter defaultCenter]
             addObserver:self
             selector:@selector(playerItemDidReachEnd:)
             name:AVPlayerItemDidPlayToEndTimeNotification
             object: [_player currentItem]];
        } else if (_player.status == AVPlayerStatusFailed) {
            // something went wrong. player.error should contain some information
            [self removeStatusObserver];
            
            [self.delegate playStopped];

            UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Connection problem" message: @"Couldn't play audio file." delegate: nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            NSLog(@"observeValueForKeyPath player status failed %ld",(long)_player.status);
            [self postEvent:@"EAFAudio observeValueForKeyPath audio failed" widget:@"observeValueForKeyPath" type:@"Button"];

        }
        else {
            NSLog(@"observeValueForKeyPath player status unk? %ld",(long)_player.status);
            [self postEvent:@"EAFAudio observeValueForKeyPath audio unk" widget:@"observeValueForKeyPath" type:@"Button"];
  }
    }
    else {
        NSLog(@"observeValueForKeyPath ignoring value... %@",keyPath);
        [self postEvent:@"EAFAudio observeValueForKeyPath audio ignoring status" widget:@"observeValueForKeyPath" type:@"Button"];

    }
}

- (void)removeStatusObserver
{
    @try {
     //   NSLog(@" remove status observer...");
        [_player removeObserver:self forKeyPath:@"status"];
    }
    @catch (NSException *exception) {
       // NSLog(@"removeStatusObserver observeValueForKeyPath : got exception %@",exception.description);
    }
}

// called from stopAudio and playRefAudioInternal
- (void)removePlayObserver {
   // NSLog(@"paths were %@, remove observer %@",_audioPaths,self);
    
    @try {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:[_player currentItem]];
//        [_player removeObserver:self forKeyPath:@"status"];
        [self removeStatusObserver];
    }
    @catch (NSException *exception) {
        if ([exception.description rangeOfString:@"registered"].location != NSNotFound) {
            NSLog(@"removePlayObserver - got registration exception %@",exception.description);
        }
        else {
            NSLog(@"removePlayObserver - got exception %@",exception.description);
        }
    }
}

@end
