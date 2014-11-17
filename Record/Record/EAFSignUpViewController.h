//
//  EAFLoginViewController.h
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 11/14/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EAFSignUpViewController : UIViewController<NSURLConnectionDelegate,UITextFieldDelegate>
@property (strong, nonatomic) IBOutlet UITextField *username;
@property (strong, nonatomic) IBOutlet UITextField *password;
@property (strong, nonatomic) IBOutlet UITextField *email;
@property (strong, nonatomic) IBOutlet UIButton *signUp;
@property (strong, nonatomic) IBOutlet UILabel *usernameFeedback;
@property (strong, nonatomic) IBOutlet UILabel *passwordFeedback;
@property (strong, nonatomic) IBOutlet UILabel *emailFeedback;

@property (strong, nonatomic) IBOutlet UIPickerView *languagePicker;
@property (strong, nonatomic) NSArray *languages;
@property (strong, nonatomic) NSMutableData *responseData;
@property (strong, nonatomic) NSString *userFromLogin;
@property long languageIndex;
@property (nonatomic, assign) id currentResponder;

@end
