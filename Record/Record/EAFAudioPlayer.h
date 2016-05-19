//
//  EAFAudioPlayer.h
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 12/10/14.
//  Copyright (c) 2011-2016 Massachusetts Institute of Technology, Lincoln Laboratory
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol AudioPlayerNotification <NSObject>

@optional
- (void) playStarted;

@optional
- (void) playStopped;

@optional
- (void) playGotToEnd;

@end

@interface EAFAudioPlayer : NSObject

@property NSString *language;

@property NSString *url;
@property NSArray *audioPaths;
@property unsigned long currentIndex;

- (IBAction)playRefAudio;
- (IBAction)stopAudio;
@property float volume;

@property(assign) id<AudioPlayerNotification> delegate;

@end

