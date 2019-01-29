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
//  EAFSignUpViewController
//  Do initial sign up, if there's any cache data from previous attempts, use that to fill
//  in fields in the form.
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 11/14/14.
//  Copyright (c) 2011-2016 Massachusetts Institute of Technology, Lincoln Laboratory
//

#import "EAFSignUpViewController.h"
//#import <CommonCrypto/CommonDigest.h>
#import "SSKeychain.h"
//#import "EAFChapterTableViewController.h"
#import "EAFSetPasswordViewController.h"
#import "EAFEventPoster.h"
#import "EAFGetSites.h"
#import "UIColor_netprofColors.h"

@interface EAFSignUpViewController ()

@property EAFEventPoster *poster;

@property (strong, nonatomic) NSString *resetPassKey;


@end

@implementation EAFSignUpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _poster = [[EAFEventPoster alloc] init];
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserver:self
                           selector:@selector (textFieldText:)
                               name:UITextFieldTextDidChangeNotification
                             object:_username];
    
    [notificationCenter addObserver:self
                           selector:@selector (passwordChanged:)
                               name:UITextFieldTextDidChangeNotification
                             object:_password];
    
    if (_projID != -1) {
        [_password setHidden:true];
    }

    [notificationCenter addObserver:self
                           selector:@selector (emailChanged:)
                               name:UITextFieldTextDidChangeNotification
                             object:_email];
    
    _username.text = _userFromLogin;
    _password.text = _passFromLogin;
    
    _username.delegate = self;
    _password.delegate = self;
    _email.delegate = self;
    
   // NSLog(@"Height %f", [[UIScreen mainScreen] bounds].size.height);
    if ([[UIScreen mainScreen] bounds].size.height < 600) {
        _maxLangPickerHeightConstraint.constant = 150;
        _bottomOffsetConstraint.constant = 32;
    }
    
    NSString *rememberedEmail = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"chosenEmail"];
    if (rememberedEmail != nil) {
        _email.text = rememberedEmail;
    }
    
    NSString *rememberedUserID = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"chosenUserID"];
    if (_userFromLogin == nil && rememberedUserID != nil) {
        _username.text = rememberedUserID;
    }
    
    NSString *rememberedPass = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"chosenPassword"];
    if (_passFromLogin == nil && rememberedPass != nil) {
        _password.text = rememberedPass;
    }
//    UITapGestureRecognizer* gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pickerViewTapGestureRecognized:)];
//    gestureRecognizer.cancelsTouchesInView = NO;
//    gestureRecognizer.delegate = self;
//    [self.languagePicker addGestureRecognizer:gestureRecognizer];
    [_titleLabel setBackgroundColor:[UIColor npLightBlue]];
    [_titleLabel setTextColor:[UIColor npDarkBlue]];
    [_signUp setTitleColor:[UIColor npDarkBlue] forState:UIControlStateNormal];
    [_signUp setTitleColor:[UIColor npDarkBlue] forState:UIControlStateApplication];
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return true;
}


// POST request
- (void)addUser:(NSString *)chosenLanguage username:(NSString *)username password:(NSString *)password email:(NSString *)email {
    
    NSString *baseurl = [NSString stringWithFormat:@"%@scoreServlet",[_siteGetter.nameToURL objectForKey:chosenLanguage]];
    
    if (_projID != -1) {
        //baseurl =_siteGetter.nServer;
        baseurl = [NSString stringWithFormat:@"%@scoreServlet",_siteGetter.nServer];
    }
    
    NSURL *url = [NSURL URLWithString:baseurl];

    NSLog(@"addUser url      %@",url);
    NSLog(@"addUser username %@",username);
    NSLog(@"addUser email    %@",email);
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    [urlRequest setHTTPMethod: @"POST"];
    [urlRequest setValue:@"application/x-www-form-urlencoded"
      forHTTPHeaderField:@"Content-Type"];
    
    [urlRequest setValue:username forHTTPHeaderField:@"user"];
    if (_projID == -1) {
//        [urlRequest setValue:[[self MD5:password] uppercaseString] forHTTPHeaderField:@"passwordH"];
        [urlRequest setValue:[password uppercaseString] forHTTPHeaderField:@"password"];
        NSLog(@"addUser password    %@",password);
    }
  //  [urlRequest setValue:[[self MD5:email]    uppercaseString] forHTTPHeaderField:@"emailH"];
    [urlRequest setValue:email forHTTPHeaderField:@"email"];
    [urlRequest setValue:[UIDevice currentDevice].model forHTTPHeaderField:@"deviceType"];
    
    NSString *retrieveuuid = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"UUID"];
    [urlRequest setValue:retrieveuuid forHTTPHeaderField:@"device"];
    
    [urlRequest setValue:@"addUser"    forHTTPHeaderField:@"request"];
    
    [urlRequest setValue:_firstName.text    forHTTPHeaderField:@"first"];
    [urlRequest setValue:_lastName.text    forHTTPHeaderField:@"last"];
    [urlRequest setValue:_affiliation.selectedSegmentIndex == 0?@"DLIFLC":@"OTHER"    forHTTPHeaderField:@"affiliation"];
    [urlRequest setValue:_gender.selectedSegmentIndex == 0?@"male":@"female"    forHTTPHeaderField:@"gender"];

    [[NSURLConnection connectionWithRequest:urlRequest delegate:self] start];
}

// Only condition on username is that it's longer than 4 characters
// Only condition on password is that it's longer than 4 characters
// Checks email for validity.
- (IBAction)onClick:(id)sender {
    _signUp.enabled = false;
    
    BOOL valid = true;
    if (_username.text.length == 0) {
        _usernameFeedback.text = @"Please enter a username.";
        valid = false;
    }
    if (_username.text.length < 5) {  // domino user  length is 5
        _usernameFeedback.text = @"Please enter a longer username.";
        valid = false;
    }
    
    if (_projID == -1) {
        if (_password.text.length == 0) {
            _passwordFeedback.text = @"Please enter a password.";
            valid = false;
        }
        if (_password.text.length < 8) {  // domino password length is 8
            _passwordFeedback.text = @"Please enter a longer password.";
            valid = false;
        }
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
        _emailFeedback.textColor = [UIColor blackColor];
        
        NSString *username = _username.text;
        NSString *password = _password.text;
        NSString *email = _email.text;
        
        [self addUser:@"" username:username password:password email:email];
        
      //  if (FALSE) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:true];
            [_activityIndicator startAnimating];
            
           // [_poster setURL:[_siteGetter.nameToURL objectForKey:chosenLanguage] projid:[_siteGetter.nameToProjectID objectForKey:chosenLanguage]];
          //  [_poster postEvent:[NSString stringWithFormat:@"signUp by %@",_username.text] exid:@"N/A" widget:@"SignIn" widgetType:@"Button"];
        // }
    }
    else {
        _signUp.enabled = true;
        NSLog(@"not valid...");
    }
}

- (void) textFieldText:(id)notification {
    [self emailChanged:nil];
}

- (void) passwordChanged:(id)notification {
    [self emailChanged:nil];
}

- (void) emailChanged:(id)notification {
    _usernameFeedback.text = @"";
    _passwordFeedback.text = @"";
    _emailFeedback.text = @"";
}

- (IBAction)gotSingleTap:(id)sender {
    //    NSLog(@"dismiss keyboard! %@",_currentResponder);
    [_currentResponder resignFirstResponder];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    _currentResponder = textField;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    _currentResponder = textField;
    return YES;
}

// hide keyboard
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (BOOL) validateEmail: (NSString *) candidate {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    
    return [emailTest evaluateWithObject:candidate];
}

//- (NSString*)MD5:(NSString*)toConvert
//{
//    // Create pointer to the string as UTF8
//    const char *ptr = [toConvert UTF8String];
//
//    // Create byte array of unsigned chars
//    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
//
//    // Create 16 byte MD5 hash value, store in buffer
//    CC_MD5(ptr, strlen(ptr), md5Buffer);
//
//    // Convert MD5 value in the buffer to NSString of hex values
//    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
//    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
//        [output appendFormat:@"%02x",md5Buffer[i]];
//
//    return output;
//}

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

- (BOOL)useJsonChapterData {
    NSError * error;
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:_responseData
                          options:NSJSONReadingAllowFragments
                          error:&error];
    [_activityIndicator stopAnimating];
    
    _signUp.enabled = true;

    if (error) {
        NSLog(@"EAFSignUpViewController.useJsonChapterData error %@",error.description);
        NSString *myString = [[NSString alloc] initWithData:_responseData encoding:NSUTF8StringEncoding];
        
        //NSLog(@"EAFSignUpViewController.useJsonChapterData _responseData %@",_responseData);
        NSLog(@"EAFSignUpViewController.useJsonChapterData myString %@",myString);
        NSLog(@"EAFSignUpViewController.useJsonChapterData json     %@",json);
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"Network problem - please try again."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        
        return false;
    }
    
    NSLog(@"useJsonChapter got %@ ",json);
    NSString *existing = [json objectForKey:@"ExistingUserName"];
    //   NSString *existingUserID = [json objectForKey:@"userid"];
    
    if (existing != nil) {// || existingUserID != nil) {
        _signUp.enabled = true;
        if (_projID == -1) {
            // no user with that name
            if ([existing isEqualToString:@"wrongPassword"]) {
                _passwordFeedback.text = @"Password incorrect";
            }
            else {
                _usernameFeedback.text = @"Username exists.";
                _passwordFeedback.text = @"Password correct?";
            }
        }
        else {
            _usernameFeedback.text = @"Username exists.";
        }
    }
    else {
        NSString *userIDExisting = [json objectForKey:@"userid"];
        NSString *resetPassKey   = [json objectForKey:@"resetPassKey"];

        // OK store info and segue
        NSString *converted = [NSString stringWithFormat:@"%@",userIDExisting];  // huh? why is this necessary?
        [SSKeychain setPassword:converted      forService:@"mitll.proFeedback.device" account:@"userid"];
        [SSKeychain setPassword:_username.text forService:@"mitll.proFeedback.device" account:@"chosenUserID"];
        [SSKeychain setPassword:_email.text    forService:@"mitll.proFeedback.device" account:@"chosenEmail"];
        
        if (resetPassKey != NULL) {
            _resetPassKey = resetPassKey;
            [self performSegueWithIdentifier:@"goToSetPassword" sender:self];
        }
        else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Please Check Email"
                                                            message:@"Check your email to set your password."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
    }
    return true;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // The request is complete and data has been received
    
    [self useJsonChapterData];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // The request has failed for some reason!
    // Check the error var
    NSLog(@"Download content failed with %@",error);
    _signUp.enabled = true;
    [_activityIndicator stopAnimating];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];
    
    NSString *message = error.localizedDescription;// @"Couldn't connect to server.";
    if (error.code == NSURLErrorNotConnectedToInternet) {
        message = @"Netprof needs a wifi or cellular internet connection.";
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Connection problem"
                                                    message: message
                                                   delegate: nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([segue.identifier isEqualToString:@"goToSetPassword"]) {
        EAFSetPasswordViewController *controller = [segue destinationViewController];
        controller.token = _resetPassKey;
    }
}

@end
