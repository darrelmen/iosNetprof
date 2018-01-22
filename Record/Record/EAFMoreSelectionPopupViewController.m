//
//  EAFMoreselectionPopupViewController.m
//  Record
//
//  Created by Zebin Xia on 5/11/17.
//  Copyright © 2017 MIT Lincoln Laboratory. All rights reserved.
//

#import "EAFMoreSelectionPopupViewController.h"
#import "UIFont+FontAwesome.h"
#import "MZFormSheetController.h"
#import "NSString+FontAwesome.h"
#import "BButton.h"
#import "SSKeychain.h"

@interface EAFMoreSelectionPopupViewController ()

@end

@implementation EAFMoreSelectionPopupViewController

- (void)configureWhatToShow
{
    [_voiceSelection setSelectedSegmentIndex:_moreSelection.voiceIndex];
    [_languageSelection setSelectedSegmentIndex:_moreSelection.languageIndex];
    
    [_languageSelection setTitle:_language forSegmentAtIndex:1];
    
    if ([_language isEqualToString:@"English"]) {
        [_languageSelection setTitle:@"Def." forSegmentAtIndex:0];
    }
    else if ([_language isEqualToString:@"Sudanese"]) {
        [_languageSelection setTitle:@"Sudan" forSegmentAtIndex:1];
    }
    else if ([_language isEqualToString:@"Pashto1"] || [_language isEqualToString:@"Pashto2"] || [_language isEqualToString:@"Pashto3"]) {
        [_languageSelection setTitle:@"Pashto" forSegmentAtIndex:1];
    }
    
    if (![self isiPad] && ![_language isEqualToString:@"English"]) {
        [_languageSelection setTitle:@"Eng" forSegmentAtIndex:0];
    }
/*
    _audioOnBtn.selected = !_audioOnBtn.selected;
    _audioOnBtn.color = _audioOnBtn.selected ?[UIColor blueColor]:[UIColor whiteColor];
*/
    NSString *audioOn = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"audioOn"];
    if (audioOn != nil) {
        _audioOnBtn.selected = [audioOn isEqualToString:@"Yes"] ? 1:0;
        _audioOnBtn.color = _audioOnBtn.selected ?[UIColor blueColor]:[UIColor whiteColor];
    }
     _moreSelection.isAudioSelected = _audioOnBtn.selected;
}



- (void)viewDidLoad {
    
//     [self.view setBackgroundColor:[UIColor lightGrayColor]];
  //  [super viewDidLoad];
    // Do any additional setup after loading the view.
    UIFont *font = [UIFont boldSystemFontOfSize:32.0f];
    if([self isiPhone]){
        font = [UIFont boldSystemFontOfSize:22.0f];
    }
    NSDictionary *attributes = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
    [_languageSelection setTitleTextAttributes:attributes forState:UIControlStateNormal];
    [_voiceSelection setTitleTextAttributes:attributes forState:UIControlStateNormal];
    
// CGRect frame= _languageSelection.frame;
    [_languageSelection setFrame:CGRectMake(0, 90, 300, 50)];
     [_voiceSelection setFrame:CGRectMake(0, 150, 225, 50)];
    
    [_audioOnBtn initWithFrame:CGRectMake(0.0f, 0.0f, 40.0f, 40.0f)
     //        color:[UIColor colorWithWhite:1.0f alpha:0.0f]
                            color:[UIColor whiteColor]
                            style:BButtonStyleBootstrapV3
                             icon:FAVolumeUp
                         fontSize:20.0f];
    _moreSelection.identityRestorationID = _audioOnBtn.restorationIdentifier;
   
     [self configureWhatToShow];
    
    _voiceSelection.enabled = _moreSelection.hasTwoGenders;
    [_voiceSelection setEnabled:(_moreSelection.hasMaleReg || _moreSelection.hasMaleSlow) forSegmentAtIndex:0];
    [_voiceSelection setEnabled:(_moreSelection.hasFemaleReg || _moreSelection.hasFemaleSlow) forSegmentAtIndex:1];
    [_voiceSelection setEnabled:_moreSelection.hasTwoGenders forSegmentAtIndex:2];
  
}

- (IBAction)audioSelection:(id)sender {
    
    _audioOnBtn.selected = !_audioOnBtn.selected;
    _audioOnBtn.color = _audioOnBtn.selected ?[UIColor blueColor]:[UIColor whiteColor];
    
    _moreSelection.isAudioSelected = _audioOnBtn.selected;

}


- (void) viewWillDisappear:(BOOL) animated {
     [super viewWillDisappear:animated];
 //   NSLog(@"Popup View will disappear");
  //   [_moreSelection setLanguageIndex:_languageSelection.selectedSegmentIndex];
    _moreSelection.languageIndex = _languageSelection.selectedSegmentIndex;
    _moreSelection.voiceIndex = _voiceSelection.selectedSegmentIndex;
    
    //Is anyone listening
    if([[self customDelegate] respondsToSelector:@selector(getSelection:)])
    {
        //send the delegate function with the country information
        [[self customDelegate] getSelection:_moreSelection];

    }
    
//    _audioOnBtn.selected = !_audioOnBtn.selected;
//    _audioOnBtn.color = _audioOnBtn.selected ?[UIColor blueColor]:[UIColor whiteColor];
}
- (IBAction)closePopup:(id)sender {
    [self mz_dismissFormSheetControllerAnimated:YES completionHandler:^(MZFormSheetController *formSheetController) {
    }];

}

- (BOOL)isiPhone
{
    //  NSLog(@"dev %@",[UIDevice currentDevice].model);
    return [[UIDevice currentDevice].model rangeOfString:@"iPhone"].location != NSNotFound;
}

- (BOOL)isiPad
{
    return ![self isiPhone];
}



@end
