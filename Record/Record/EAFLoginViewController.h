//
//  EAFLoginViewController.h
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 11/14/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SplunkMint-iOS/SplunkMint-iOS.h>
#import "BButton.h"

@interface EAFLoginViewController : UIViewController<NSURLConnectionDelegate,UITextFieldDelegate,UIGestureRecognizerDelegate>
@property (strong, nonatomic) IBOutlet UITextField *username;
@property (strong, nonatomic) IBOutlet UITextField *password;
@property (strong, nonatomic) IBOutlet UIButton *logIn;
@property (strong, nonatomic) IBOutlet UIButton *signUp;
@property (strong, nonatomic) IBOutlet UILabel *usernameFeedback;
@property (strong, nonatomic) IBOutlet UILabel *passwordFeedback;
@property (strong, nonatomic) IBOutlet UILabel *signUpFeedback;
@property (strong, nonatomic) IBOutlet UIPickerView *languagePicker;
@property (strong, nonatomic) NSArray *langauges;
@property (strong, nonatomic) NSMutableData *responseData;
@property (nonatomic, assign) id currentResponder;
@property (strong, nonatomic) IBOutlet BButton *forgotUsername;
@property (strong, nonatomic) IBOutlet BButton *forgotPassword;

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property NSString *token;

@end
