/*
 * DISTRIBUTION STATEMENT C. Distribution authorized to U.S. Government Agencies
 * and their contractors; 2015. Other request for this document shall be referred
 * to DLIFLC.
 *
 * WARNING: This document may contain technical data whose export is restricted
 * by the Arms Export Control Act (AECA) or the Export Administration Act (EAA).
 * Transfer of this data by any means to a non-US person who is not eligible to
 * obtain export-controlled data is prohibited. By accepting this data, the consignee
 * agrees to honor the requirements of the AECA and EAA. DESTRUCTION NOTICE: For
 * unclassified, limited distribution documents, destroy by any method that will
 * prevent disclosure of the contents or reconstruction of the document.
 *
 * This material is based upon work supported under Air Force Contract No.
 * FA8721-05-C-0002 and/or FA8702-15-D-0001. Any opinions, findings, conclusions
 * or recommendations expressed in this material are those of the author(s) and
 * do not necessarily reflect the views of the U.S. Air Force.
 *
 * © 2015 Massachusetts Institute of Technology.
 *
 * The software/firmware is provided to you on an As-Is basis
 *
 * Delivered to the US Government with Unlimited Rights, as defined in DFARS
 * Part 252.227-7013 or 7014 (Feb 2014). Notwithstanding any copyright notice,
 * U.S. Government rights in this work are defined by DFARS 252.227-7013 or
 * DFARS 252.227-7014 as detailed above. Use of this work other than as specifically
 * authorized by the U.S. Government may violate any copyrights that exist in this work.
 *
 */

//
//  EAFLoginViewController.m
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 11/14/14.
//  Copyright (c) 2011-2016 Massachusetts Institute of Technology, Lincoln Laboratory
//

#import "EAFForgotPasswordViewController.h"
#import <CommonCrypto/CommonDigest.h>
#import "SSKeychain.h"

@interface EAFForgotPasswordViewController ()
@property (nonatomic, assign) id currentResponder;

@end

@implementation EAFForgotPasswordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setTitle:[NSString stringWithFormat:@"Forgot password for %@",_language]];
    _username.text = _userFromLogin;
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserver:self
                           selector:@selector (emailChanged:)
                               name:UITextFieldTextDidChangeNotification
                             object:_username];
    
    [notificationCenter addObserver:self
                           selector:@selector (emailChanged:)
                               name:UITextFieldTextDidChangeNotification
                             object:_email];
}

- (void) emailChanged:(id)notification {
    _usernameFeedback.text = @"";
    _emailFeedback.text = @"";
}

- (IBAction)gotClick:(id)sender {
    BOOL valid = true;
    
    if (_username.text.length == 0) {
        _usernameFeedback.text = @"Please enter a username";
        valid = false;
    }
    
    if (_email.text.length == 0) {
        _emailFeedback.text = @"Please enter your email.";
        _emailFeedback.textColor = [UIColor redColor];
        valid = false;
    }

    if (![self validateEmail:_email.text]) {
        _emailFeedback.text = @"Please enter a valid email.";
        _emailFeedback.textColor = [UIColor redColor];
        valid = false;
    }

    if (valid) {
        [self forgotUsername:_email.text language:_language];
    }
}


- (IBAction)gotSingleTap:(id)sender {
    NSLog(@"dismiss keyboard! %@",_currentResponder);
    [_currentResponder resignFirstResponder];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    //   NSLog(@"got text field start on %@",textField);
    _currentResponder = textField;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSLog(@"Got return!");
    // done button was pressed - dismiss keyboard
    [textField resignFirstResponder];
    
    if (_username.text.length > 0) {
        _usernameFeedback.text = @"";
    }
    if (_email.text.length > 0) {
        _emailFeedback.text = @"";
    }
    
    if ([self validateEmail:_email.text]) {
        _emailFeedback.text = @"";
    }
    
    return YES;
}

- (BOOL) validateEmail: (NSString *) candidate {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    
    return [emailTest evaluateWithObject:candidate];
}

#pragma mark NSURLConnection Delegate Methods

- (void) forgotUsername:(NSString *)email language:(NSString *)lang {
    NSString *baseurl = [NSString stringWithFormat:@"%@/scoreServlet?resetPassword=%@&email=%@", _url, _username.text, email];
    
    NSLog(@"url %@",baseurl);
    
    NSURL *url = [NSURL URLWithString:baseurl];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
  //  [urlRequest setCachePolicy:NSURLRequestReturnCacheDataElseLoad];
    
    [urlRequest setHTTPMethod: @"GET"];
    [urlRequest setValue:@"application/x-www-form-urlencoded"
      forHTTPHeaderField:@"Content-Type"];
    
    NSURLConnection *connection = [NSURLConnection connectionWithRequest:urlRequest delegate:self];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:true];
    
    [connection start];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:TRUE];
}

#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // A response has been received, this is where we initialize the instance var you created
    // so that we can append data to it in the didReceiveData method
    // Furthermore, this method is called each time there is a redirect so reinitializing it
    // also serves to clear it
    
    _responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // NSLog(@"didReceiveData ----- ");
    
    // Append the new data to the instance variable you declared
    [_responseData appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
}

//
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];
    NSError * error;
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:_responseData
                          options:NSJSONReadingAllowFragments
                          error:&error];
    
    if (error) {
        NSLog(@"connectionDidFinishLoading error %@",error.description);
    }
    
    NSLog(@"connectionDidFinishLoading got %@ ",json);
    NSString *validEmail = [json objectForKey:@"token"];
   
    if ([validEmail isEqualToString:@"PASSWORD_EMAIL_SENT"]) {
        _emailFeedback.text = @"Please check your email";
        _emailFeedback.textColor = [UIColor blackColor];
    }
    else {
        _emailFeedback.text = @"Unknown email address for user.";
        _emailFeedback.textColor = [UIColor redColor];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // The request has failed for some reason!
    // Check the error var
    NSLog(@"Download content failed with %@",error);

    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];
    
    NSString *message = @"Couldn't connect to server.";
    if (error.code == NSURLErrorNotConnectedToInternet) {
        message = @"NetProF needs a wifi or cellular internet connection.";
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Connection problem"
                                                    message: message
                                                   delegate: nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];

    [alert show];
}

#pragma mark - Navigation
//
//// In a storyboard-based application, you will often want to do a little preparation before navigation
//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//}
//
//
@end
