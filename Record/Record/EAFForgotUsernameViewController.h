//
//  EAFLoginViewController.h
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 11/14/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EAFForgotUsernameViewController : UIViewController<NSURLConnectionDelegate,UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITextField *email;
@property (strong, nonatomic) IBOutlet UIButton *sendEmail;

@property (strong, nonatomic) IBOutlet UILabel *emailFeedback;
@property (strong, nonatomic) NSMutableData *responseData;
@property NSString *language;
- (BOOL) validateEmail: (NSString *) candidate;
@property (strong, nonatomic) NSString *url;

@end
