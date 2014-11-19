//
//  EAFAudioView.h
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 11/13/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SplunkMint-iOS/SplunkMint-iOS.h>

@interface EAFAudioView : UIView<UIGestureRecognizerDelegate>

@property (nonatomic, weak) NSString* refAudio;
@property (nonatomic, weak) NSString* answer;
- (IBAction)gotClick:(id)sender;
- (IBAction)handleGesture:(UITapGestureRecognizer *)gestureRecognizer;

@end

