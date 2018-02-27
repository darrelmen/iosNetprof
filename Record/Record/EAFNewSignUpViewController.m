
#import <Foundation/Foundation.h>

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
//  Do initial sign up, if there's any cache data from previous attempts, use that to fill
//  in fields in the form.
//
//  EAFNewSignUpViewController.m
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 5/31/17.
//  Copyright © 2017 MIT Lincoln Laboratory. All rights reserved.
//


#import "EAFNewSignUpViewController.h"
#import <CommonCrypto/CommonDigest.h>
#import "SSKeychain.h"
#import "EAFChapterTableViewController.h"
#import "EAFEventPoster.h"
#import "EAFGetSites.h"

@interface EAFNewSignUpViewController ()

//@property (weak, nonatomic) IBOutlet UIPickerView *affiliation;
@property EAFEventPoster *poster;
@property NSArray *pickerData;
@property NSArray *affiliations;

@end

@implementation EAFNewSignUpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _poster = [[EAFEventPoster alloc] init];
    _pickerData = @[@"DLI Foreign Language Center", @"DLI-Washington", @"Language Training Detachment", @"Mobile Training Team", @"Massachusetts Institute of Technology", @"MIT - Lincoln Laboratory", @"Other"];
    
    _affiliations = @[@"DLIFLC", @"DLI-W", @"LTD", @"MTT", @"MIT", @"MIT-LL", @"OTHER"];
    
    self.affiliation.dataSource = self;
    self.affiliation.delegate = self;
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserver:self
                           selector:@selector (textFieldText:)
                               name:UITextFieldTextDidChangeNotification
                             object:_username];
    
    [notificationCenter addObserver:self
                           selector:@selector (emailChanged:)
                               name:UITextFieldTextDidChangeNotification
                             object:_email];
    
    _username.text = _userFromLogin;
    //    _password.text = _passFromLogin;
    //    [_languagePicker selectRow:_languageIndex inComponent:0 animated:false];
    
    _username.delegate = self;
    //    _password.delegate = self;
    _email.delegate = self;
    
    NSString *rememberedEmail = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"chosenEmail"];
    if (rememberedEmail != nil) {
        _email.text = rememberedEmail;
    }
    
    NSString *rememberedUserID = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"chosenUserID"];
    if (_userFromLogin == nil && rememberedUserID != nil) {
        _username.text = rememberedUserID;
    }
    //
    //    NSString *rememberedPass = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"chosenPassword"];
    //    if (_passFromLogin == nil && rememberedPass != nil) {
    //        _password.text = rememberedPass;
    //    }
    
    //    UITapGestureRecognizer* gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pickerViewTapGestureRecognized:)];
    //    gestureRecognizer.cancelsTouchesInView = NO;
    //    gestureRecognizer.delegate = self;
    //    [self.languagePicker addGestureRecognizer:gestureRecognizer];
}

//- (void) sitesReady {
//    [_languagePicker reloadAllComponents ];
//}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return true;
}

// POST request
- (void)addUser:(NSString *)chosenLanguage username:(NSString *)username first:(NSString *)first last:(NSString *)last email:(NSString *)email aff:(NSString *)aff {
    
    NSString *baseurl = [NSString stringWithFormat:@"%@scoreServlet",[_siteGetter.nameToURL objectForKey:chosenLanguage]];
    NSURL *url = [NSURL URLWithString:baseurl];
    
    NSLog(@"addUser url %@",url);
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    [urlRequest setHTTPMethod: @"POST"];
    [urlRequest setValue:@"application/x-www-form-urlencoded"
      forHTTPHeaderField:@"Content-Type"];
    
    [urlRequest setValue:username forHTTPHeaderField:@"user"];
    //  [urlRequest setValue:[[self MD5:password] uppercaseString] forHTTPHeaderField:@"passwordH"];
    //  [urlRequest setValue:[password uppercaseString] forHTTPHeaderField:@"password"];
    
    [urlRequest setValue:[[self MD5:email]    uppercaseString] forHTTPHeaderField:@"emailH"];
    
    [urlRequest setValue:email forHTTPHeaderField:@"email"];
    
    [urlRequest setValue:[UIDevice currentDevice].model forHTTPHeaderField:@"deviceType"];
    NSString *retrieveuuid = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"UUID"];
    [urlRequest setValue:retrieveuuid forHTTPHeaderField:@"device"];
    
    long sel = [_gender selectedSegmentIndex];
    NSString *gender = @"male";
    if (sel == 1) gender = @"female";
    
    [urlRequest setValue:first  forHTTPHeaderField:@"first"];
    [urlRequest setValue:last  forHTTPHeaderField:@"last"];
    [urlRequest setValue:aff  forHTTPHeaderField:@"affiliation"];
    [urlRequest setValue:gender forHTTPHeaderField:@"gender"];
    [urlRequest setValue:@"addUser"    forHTTPHeaderField:@"request"];
    
    [[NSURLConnection connectionWithRequest:urlRequest delegate:self] start];
}

// Only condition on username is that it's longer than 4 characters
// Checks email for validity.
- (IBAction)onClick:(id)sender {
    _signUp.enabled = false;
    
    BOOL valid = true;
    if (_username.text.length == 0) {
        _usernameFeedback.text = @"Please enter a username.";
        valid = false;
    }
    else if (_username.text.length < 5) {
        _usernameFeedback.text = @"Please enter a longer username.";
        valid = false;
    }
    else if (_first.text.length == 0) {
        _usernameFeedback.text = @"Please enter a first name.";
        valid = false;
    }
    else if (_last.text.length == 0) {
        _usernameFeedback.text = @"Please enter a last name.";
        valid = false;
    }
    else if (_email.text.length == 0) {
        _usernameFeedback.text = @"Please enter your email.";
        _usernameFeedback.textColor = [UIColor redColor];
        valid = false;
    }
    else if (![self validateEmail:_email.text]) {
        _usernameFeedback.text = @"Please enter a valid email.";
        _usernameFeedback.textColor = [UIColor redColor];
        valid = false;
    }
    
    if (valid) {
        _usernameFeedback.textColor = [UIColor blackColor];
        
        NSString *username = _username.text;
        NSString *email = _email.text;
        
        
        NSString *affAbbrev =  [_affiliations objectAtIndex:[_affiliation selectedRowInComponent:0]];
        
        [self addUser:_chosenLanguage username:username first:_first.text last:_last.text email:email aff:affAbbrev];
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:true];
        [_activityIndicator startAnimating];
    }
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    //One column
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    //set number of rows
    return _pickerData.count;
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [_pickerData objectAtIndex:row];
}

- (void) textFieldText:(id)notification {
    [self emailChanged:nil];
}

- (void) emailChanged:(id)notification {
    _usernameFeedback.text = @"";
    //   _passwordFeedback.text = @"";
   // _emailFeedback.text = @"";
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

- (NSString*)MD5:(NSString*)toConvert
{
    // Create pointer to the string as UTF8
    const char *ptr = [toConvert UTF8String];
    
    // Create byte array of unsigned chars
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    // Create 16 byte MD5 hash value, store in buffer
    CC_MD5(ptr, strlen(ptr), md5Buffer);
    
    // Convert MD5 value in the buffer to NSString of hex values
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x",md5Buffer[i]];
    
    return output;
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

- (BOOL)useJsonChapterData {
    NSError * error;
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:_responseData
                          options:NSJSONReadingAllowFragments
                          error:&error];
    [_activityIndicator stopAnimating];
    
    if (error) {
        NSLog(@"EAFNewSignUpViewController.useJsonChapterData error %@",error.description);
        NSLog(@"EAFNewSignUpViewController.useJsonChapterData _responseData %@",_responseData);
        _signUp.enabled = true;
        return false;
    }
    
    //   NSLog(@"useJsonChapter got %@ ",json);
    NSString *existing = [json objectForKey:@"ExistingUserName"];
    
    if (existing != nil) {
        // no user with that name
        if ([existing isEqualToString:@"wrongPassword"]) {
            //            _passwordFeedback.text = @"Password incorrect";
        }
        else {
            _usernameFeedback.text = @"Username exists.";
            //          _passwordFeedback.text = @"Password correct?";
        }
    }
    else {
        NSString *userIDExisting = [json objectForKey:@"userid"];
        
        // OK store info and segue
        NSLog(@"userid %@",userIDExisting);
        NSString *converted = [NSString stringWithFormat:@"%@",userIDExisting];  // huh? why is this necessary?
        [SSKeychain setPassword:converted      forService:@"mitll.proFeedback.device" account:@"userid"];
        [SSKeychain setPassword:_username.text forService:@"mitll.proFeedback.device" account:@"chosenUserID"];
        [SSKeychain setPassword:_email.text    forService:@"mitll.proFeedback.device" account:@"chosenEmail"];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Please Check Email"
                                                        message:@"Check your email to set your password."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
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

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    //  EAFChapterTableViewController *chapterController = [segue destinationViewController];
    
    //  NSString *chosenLanguage = [_siteGetter.languages objectAtIndex:[_languagePicker selectedRowInComponent:0]];
    //  [chapterController setLanguage:chosenLanguage];
    //  chapterController.url = [_siteGetter.nameToURL objectForKey:chosenLanguage];
    // [chapterController setTitle:chosenLanguage];
}

@end