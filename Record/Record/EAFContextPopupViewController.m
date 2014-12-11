//
//  EAFLoginViewController.m
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 11/14/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import "EAFContextPopupViewController.h"
#import <CommonCrypto/CommonDigest.h>
#import "SSKeychain.h"
#import "MZFormSheetController.h"
//#import "FAImageView.h"

@interface EAFContextPopupViewController ()

@end

@implementation EAFContextPopupViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _audioPlayer = [[EAFAudioPlayer alloc] init];

    NSLog(@"view did load %@",_contextFL.text);

    _contextFL.text = _fl;
    _contextTranslation.text = _en;
    _itemFL.text = _item;
    
    NSMutableArray *audioCuts = [[NSMutableArray alloc] init];
    
    BOOL hasMale = false;
    if (_mref == nil || _mref.length == 0 || [_mref isEqualToString:@"NO"]) {
     //  UIImage * male = [_maleFemale imageForSegmentAtIndex:0];
        [[_maleFemale.subviews objectAtIndex:0] setTintColor:[UIColor grayColor]];
        
        NSLog(@"no male audio");
        [_maleFemale setEnabled:NO forSegmentAtIndex:0];
    }
    else {
        [audioCuts addObject:_mref];
        hasMale = true;
    }
    
    if (_fref == nil || _fref.length == 0 || [_fref isEqualToString:@"NO"]) {
        //  UIImage * male = [_maleFemale imageForSegmentAtIndex:0];
        [[_maleFemale.subviews objectAtIndex:1] setTintColor:[UIColor grayColor]];
        [_maleFemale setEnabled:NO forSegmentAtIndex:1];

      //  NSLog(@"no female audio");
    }
    else {
        if (!hasMale) {
            _maleFemale.selectedSegmentIndex = 1;
            [audioCuts addObject:_fref];
        }
    }
    _audioPlayer.audioPaths = audioCuts;
    _audioPlayer.viewToAddIconTo = _contextFL;
    _audioPlayer.url = _url;
    _audioPlayer.language = _language;
    _maleFemale.enabled = audioCuts.count > 0;
    
    [_playingIcon initWithFrame:CGRectMake(0.0f, 0.0f, 32.0f, 32.0f)
                             color:[UIColor colorWithWhite:1.0f alpha:0.0f]
                             style:BButtonStyleBootstrapV3
                              icon:FAVolumeUp
                          fontSize:20.0f];
    [_playingIcon setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    
    _audioPlayer.playingIcon = _playingIcon;
   // NSLog(@"Audio paths now %@",_audioPlayer.audioPaths);
}

- (IBAction)tapOnSentence:(id)sender {
    [_audioPlayer playRefAudio];
}

- (IBAction)gotOK:(id)sender {
    // [self dismissViewControllerAnimated:YES completion:nil];
    
    [self mz_dismissFormSheetControllerAnimated:YES completionHandler:^(MZFormSheetController *formSheetController) {
        
    }];
}

- (IBAction)gotTouchInside:(id)sender {
    [self onClick:sender];
}

- (IBAction)onClick:(id)sender {
    NSLog(@"Got click %@",sender);
    
    NSMutableArray *audioCuts = [[NSMutableArray alloc] init];
    if (_maleFemale.selectedSegmentIndex == 0) {
        [audioCuts addObject:_mref];
    }
    else {
        [audioCuts addObject:_fref];
    }
    _audioPlayer.audioPaths = audioCuts;

    [_audioPlayer playRefAudio];
}

@end
