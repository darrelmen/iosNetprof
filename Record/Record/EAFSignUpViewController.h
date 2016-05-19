//
//  EAFLoginViewController.h
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 11/14/14.
//  Copyright (c) 2011-2016 Massachusetts Institute of Technology, Lincoln Laboratory
//

#import <UIKit/UIKit.h>
#import "EAFGetSites.h"

@interface EAFSignUpViewController : UIViewController<NSURLConnectionDelegate,UITextFieldDelegate,UIGestureRecognizerDelegate>
@property (strong, nonatomic) IBOutlet UITextField *username;
@property (strong, nonatomic) IBOutlet UITextField *password;
@property (strong, nonatomic) IBOutlet UITextField *email;
@property (strong, nonatomic) IBOutlet UIButton *signUp;
@property (strong, nonatomic) IBOutlet UILabel *usernameFeedback;
@property (strong, nonatomic) IBOutlet UILabel *passwordFeedback;
@property (strong, nonatomic) IBOutlet UILabel *emailFeedback;

@property (strong, nonatomic) IBOutlet UIPickerView *languagePicker;
//@property (strong, nonatomic) NSArray *languages;
@property (strong, nonatomic) NSMutableData *responseData;
@property (strong, nonatomic) NSString *userFromLogin;
@property (strong, nonatomic) NSString *passFromLogin;
@property long languageIndex;
@property (nonatomic, assign) id currentResponder;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property EAFGetSites *siteGetter;

@end
