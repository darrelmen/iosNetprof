//
//  EAFLoginViewController.m
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 11/14/14.
//  Copyright (c) 2011-2016 Massachusetts Institute of Technology, Lincoln Laboratory
//

#import "EAFContextPopupViewController.h"
#import <CommonCrypto/CommonDigest.h>
#import "SSKeychain.h"
#import "MZFormSheetController.h"

@interface EAFContextPopupViewController ()
@property EAFAudioPlayer *audioPlayer;
@property NSString *regex;
@end

@implementation EAFContextPopupViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _regex = @"[\\?\\.,-\\/#!$%\\^&\\*;:{}=\\-_`~()]";
    
    _contextFL.attributedText = [self highlightTerm:_fl refSentence:_item];
    _contextTranslation.text = _en;
    
    if ([_en isEqualToString:_fl]) {  // for english
        _contextTranslation.text = @"";
    }
    
    _itemFL.text = _item;
    
    NSMutableArray *audioCuts = [[NSMutableArray alloc] init];
    
    BOOL hasMale = false;
    if (_mref == nil || _mref.length == 0 || [_mref isEqualToString:@"NO"]) {
        [[_maleFemale.subviews objectAtIndex:0] setTintColor:[UIColor grayColor]];
        //        NSLog(@"no male audio");
        [_maleFemale setEnabled:NO forSegmentAtIndex:0];
    }
    else {
        [audioCuts addObject:_mref];
        hasMale = true;
    }
    
    if (_fref == nil || _fref.length == 0 || [_fref isEqualToString:@"NO"]) {
        [[_maleFemale.subviews objectAtIndex:1] setTintColor:[UIColor grayColor]];
        [_maleFemale setEnabled:NO forSegmentAtIndex:1];
    }
    else {
        if (!hasMale) {
            _maleFemale.selectedSegmentIndex = 1;
            [audioCuts addObject:_fref];
        }
    }
    
    _maleFemale.enabled = audioCuts.count > 0;

    _audioPlayer = [[EAFAudioPlayer alloc] init];
    _audioPlayer.audioPaths = audioCuts;
    _audioPlayer.url = _url;
    _audioPlayer.language = _language;
    _audioPlayer.delegate = self;
}

-(void) viewWillDisappear:(BOOL)animated {
//    NSLog(@"view will disappear.");
   [_audioPlayer stopAudio];
    [super viewWillDisappear:animated];
}

-(NSAttributedString *) highlightTerm:(NSString *) context refSentence:(NSString *)refSentence  {
    NSString *trim = [refSentence stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    NSString *toFind = [self removePunct:trim];
    toFind = [toFind stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    //    NSLog(@"looking for '%@' in %@",toFind,context);
    NSRange range = [context rangeOfString:toFind];
    if (range.length > 0) {
        return [self highlight:context range:range];
    } else {
        NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:context];
        
        NSArray* tokens = [self getTokens:trim];
        NSUInteger endToken = 0;
        for (NSString * token in tokens) {
         //   NSLog(@"  token  %@",token);
            
            NSRange trange = [context rangeOfString:token options:NSCaseInsensitiveSearch range:NSMakeRange(endToken, context.length-endToken)];
            
            if (trange.length > 0) {
                [result addAttribute:NSBackgroundColorAttributeName
                               value:[UIColor greenColor]
                               range:trange];
                endToken = trange.location+trange.length;
            }
        }
        return result;
    }
}

- (NSAttributedString *)highlight:(NSString *) toHighlight range:(NSRange) range
{
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:toHighlight];
    
    [result addAttribute:NSBackgroundColorAttributeName
                   value:[UIColor greenColor]
                   range:range];
    return result;
}

-(NSArray *)getTokens:(NSString *)sentence {
    NSMutableArray * all = [[NSMutableArray alloc] init];
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:_regex options:NSRegularExpressionCaseInsensitive error:&error];
    sentence = [regex stringByReplacingMatchesInString:sentence options:0 range:NSMakeRange(0, [sentence length]) withTemplate:@" "];
    
    for (NSString *untrimedToken in [sentence componentsSeparatedByString:@" "]) { // split on spaces
        NSString *token = [untrimedToken stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if (token.length > 0) {
            [all addObject:token];
        }
    }
    //  NSLog(@"tokens %@", all);
    
    return all;
}

-(NSString *)removePunct:(NSString *) t{
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:_regex options:NSRegularExpressionCaseInsensitive error:&error];
    NSString *modifiedString = [regex stringByReplacingMatchesInString:t options:0 range:NSMakeRange(0, [t length]) withTemplate:@""];
    // NSLog(@"removePunct %@", modifiedString);
    return modifiedString;
}

- (void) playStarted {
    [self highlightFLWhilePlaying];
}

- (void) playStopped {
    [self removePlayingAudioHighlight];
}

- (void) playGotToEnd {
   NSLog(@"playGotToEnd");
}

- (void)highlightFLWhilePlaying
{
    _contextFL.textColor = [UIColor blueColor];
}

- (void)removePlayingAudioHighlight {
    _contextFL.textColor = [UIColor blackColor];
}

- (IBAction)tapOnSentence:(id)sender {
    [_audioPlayer playRefAudio];
}

- (IBAction)gotOK:(id)sender {
    [self mz_dismissFormSheetControllerAnimated:YES completionHandler:^(MZFormSheetController *formSheetController) {
    }];
}

- (IBAction)gotTouchInside:(id)sender {
    [self onClick:sender];
}

- (IBAction)onClick:(id)sender {
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
