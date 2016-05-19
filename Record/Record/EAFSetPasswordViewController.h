//
//  EAFLoginViewController.h
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 11/14/14.
//  Copyright (c) 2011-2016 Massachusetts Institute of Technology, Lincoln Laboratory
//

#import <UIKit/UIKit.h>
//#import <SplunkMint-iOS/SplunkMint-iOS.h>

@interface EAFSetPasswordViewController : UIViewController<NSURLConnectionDelegate,UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITextField *password;
@property (strong, nonatomic) IBOutlet UIButton *sendEmail;
@property (strong, nonatomic) IBOutlet UITextField *confirmPassword;

@property (strong, nonatomic) IBOutlet UILabel *passwordFeedback;

@property (strong, nonatomic) IBOutlet UILabel *confirmPasswordFeedback;
@property (strong, nonatomic) NSMutableData *responseData;
@property NSString *language;
@property (strong, nonatomic) NSString *userFromLogin;
@property (strong, nonatomic) NSString *token;
@property (strong, nonatomic) NSString *url;

@end
