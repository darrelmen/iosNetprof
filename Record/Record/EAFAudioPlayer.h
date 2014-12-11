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
@property NSString *language;

@property AVPlayer *player;
@property NSString *url;
@property NSArray *audioPaths;
@property int currentIndex;
@property (strong, nonatomic) IBOutlet UIView *playingIcon;

- (IBAction)playRefAudio;

@end
