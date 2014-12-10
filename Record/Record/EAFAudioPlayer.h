//
//  EAFAudioPlayer.h
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 12/10/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface EAFAudioPlayer : NSObject

@property UIView *viewToAddIconTo;
//@property FAImageView *playingIcon;
@property NSString *language;

//@property NSString *chapterName;
//@property NSString *chapterSelection;

@property AVPlayer *player;
@property NSString *url;
@property NSArray *audioPaths;
@property int currentIndex;

- (IBAction)playRefAudio;

@end
