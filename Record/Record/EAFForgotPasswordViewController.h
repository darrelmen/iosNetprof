//
//  EAFLoginViewController.h
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 11/14/14.
//  Copyright (c) 2011-2016 Massachusetts Institute of Technology, Lincoln Laboratory
//

#import <UIKit/UIKit.h>

@interface EAFForgotPasswordViewController : UIViewController<NSURLConnectionDelegate,UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITextField *email;
@property (strong, nonatomic) IBOutlet UIButton *sendEmail;
@property (strong, nonatomic) IBOutlet UITextField *username;

@property (strong, nonatomic) IBOutlet UILabel *usernameFeedback;

@property (strong, nonatomic) IBOutlet UILabel *emailFeedback;
@property (strong, nonatomic) NSMutableData *responseData;
@property NSString *language;
- (BOOL) validateEmail: (NSString *) candidate;
@property (strong, nonatomic) NSString *userFromLogin;
@property (strong, nonatomic) NSString *url;

@end
