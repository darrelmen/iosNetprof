//
//  EAFMoreselectionPopupViewController.h
//  Record
//
//  Created by Zebin Xia on 5/11/17.
//  Copyright © 2017 MIT Lincoln Laboratory. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MoreSelection.h"
#import "BButton.h"
//#import "EAFRecoFlashcardController.h"

@protocol PassSelection <NSObject>
-(void) getSelection:(MoreSelection *)selection;
@end


@interface EAFMoreSelectionPopupViewController :UIViewController


@property MoreSelection *moreSelection;

@property (nonatomic, assign) id<PassSelection> customDelegate;


@property (strong, nonatomic) IBOutlet UISegmentedControl *languageSelection;

@property (strong, nonatomic) IBOutlet UISegmentedControl *voiceSelection;

@property NSString *language;
@property NSString *fl;
@property NSString *en;
@property NSString *mref;
@property NSString *fref;
@property NSString *url;

@property (strong, nonatomic) IBOutlet BButton *audioOnBtn;


@end
