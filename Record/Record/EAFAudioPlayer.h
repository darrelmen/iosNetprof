//
//  EAFAudioPlayer.h
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 12/10/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol AudioPlayerNotification <NSObject>
@optional
- (void) playStarted;

@optional
- (void) playStopped;
@end

@interface EAFAudioPlayer : NSObject

@property NSString *language;

@property NSString *url;
@property NSArray *audioPaths;
@property int currentIndex;

- (IBAction)playRefAudio;
- (IBAction)stopAudio;

@property(assign) id<AudioPlayerNotification> delegate;

@end

