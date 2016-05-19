//
//  EAFLoginViewController.h
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 11/14/14.
//  Copyright (c) 2011-2016 Massachusetts Institute of Technology, Lincoln Laboratory
//

#import <UIKit/UIKit.h>
//#import <SplunkMint-iOS/SplunkMint-iOS.h>
#import "BButton.h"
#import "EAFGetSites.h"


@interface EAFLoginViewController : UIViewController<UITextFieldDelegate,UIGestureRecognizerDelegate,SitesNotification>
@property (strong, nonatomic) IBOutlet UITextField *username;
@property (strong, nonatomic) IBOutlet UITextField *password;
@property (strong, nonatomic) IBOutlet UIButton *logIn;
@property (strong, nonatomic) IBOutlet UIButton *signUp;
@property (strong, nonatomic) IBOutlet UILabel *usernameFeedback;
@property (strong, nonatomic) IBOutlet UILabel *passwordFeedback;
@property (strong, nonatomic) IBOutlet UILabel *signUpFeedback;
@property (strong, nonatomic) IBOutlet UIPickerView *languagePicker;
@property (strong, nonatomic) NSData *responseData;
@property (nonatomic, assign) id currentResponder;
@property (strong, nonatomic) IBOutlet BButton *forgotUsername;
@property (strong, nonatomic) IBOutlet BButton *forgotPassword;

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property NSString *token;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;

@end
