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

#import "EAFLoginViewController.h"
#import <CommonCrypto/CommonDigest.h>
#import "SSKeychain.h"
#import "EAFChapterTableViewController.h"
#import "EAFSignUpViewController.h"
#import "EAFForgotUserNameViewController.h"
#import "EAFForgotPasswordViewController.h"
#import "EAFSetPasswordViewController.h"
#import "EAFEventPoster.h"
#import "EAFGetSites.h"
#import "UIColor_netprofColors.h"

@interface EAFLoginViewController ()

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;

@property (strong, nonatomic) NSData *sitesData;
@property EAFGetSites *siteGetter;
@property EAFEventPoster *poster;
@end

@interface NSURLRequest(Private)
+(void)setAllowsAnyHTTPSCertificate:(BOOL)inAllow forHost:(NSString *)inHost;
@end

@implementation EAFLoginViewController

// look at cookie value and set the language picker accordingly
- (void)setLanguagePicker {
    //  NSLog(@"setting language picker language");
    NSString *languageRemembered = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"language"];
    if (languageRemembered != nil) {
        NSUInteger toChoose = [_siteGetter.languages indexOfObject:languageRemembered];
        //        NSLog(@"setLanguagePicker language cookie now %@ = %lu among %@",languageRemembered,(unsigned long)toChoose,_siteGetter.languages);
        if (toChoose > [_languagePicker numberOfRowsInComponent:0]) {
            NSLog(@"LoginViewController : setLanguagePicker choose %lu bigger than num selected is %ld",(unsigned long)toChoose,(long)[_languagePicker numberOfRowsInComponent:0]);
            [_languagePicker selectRow:0 inComponent:0 animated:false];
        }
        else {
            [_languagePicker selectRow:toChoose inComponent:0 animated:false];
            NSLog(@"LoginViewController : setLanguagePicker selected is %ld",(long)[_languagePicker selectedRowInComponent:0]);
        }
    }
    else {
        NSLog(@"LoginViewController : setLanguagePicker no language cookie");
    }
}

- (NSString *)appNameAndVersionNumberDisplayString {
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *minorVersion = [infoDictionary objectForKey:@"CFBundleVersion"];
    return minorVersion;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [_logIn setTitleColor:[UIColor npDarkBlue] forState:UIControlStateNormal];
    [_signUp setTitleColor:[UIColor npDarkBlue] forState:UIControlStateNormal];
    [_titleLabel setBackgroundColor:[UIColor npLightBlue]];
    [_titleLabel setTextColor:[UIColor npDarkBlue]];
    
    _versionLabel.text = [self appNameAndVersionNumberDisplayString];
    
    _siteGetter = [EAFGetSites new];
    _siteGetter.delegate = self;
    [_siteGetter getSites];
    _poster = [[EAFEventPoster alloc] init];
    
    // NSLog(@"viewDidLoad : languages now %@",_siteGetter.languages);
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserver:self
                           selector:@selector (textFieldText:)
                               name:UITextFieldTextDidChangeNotification
                             object:_username];
    
    [notificationCenter addObserver:self
                           selector:@selector (passwordChanged:)
                               name:UITextFieldTextDidChangeNotification
                             object:_password];
    
    
    _username.delegate = self;
    _password.delegate = self;
    
    [_forgotUsername initWithFrame:CGRectMake(0.0f, 0.0f, 32.0f, 32.0f)
                             color:[UIColor colorWithWhite:1.0f alpha:0.0f]
                             style:BButtonStyleBootstrapV3
                              icon:FAQuestion
                          fontSize:20.0f];
    [_forgotUsername setTitleColor:[UIColor npDarkBlue] forState:UIControlStateNormal];
    
    [_forgotPassword initWithFrame:CGRectMake(0.0f, 0.0f, 32.0f, 32.0f)
                             color:[UIColor colorWithWhite:1.0f alpha:0.0f]
                             style:BButtonStyleBootstrapV3
                              icon:FAQuestion
                          fontSize:20.0f];
    [_forgotPassword setTitleColor:[UIColor npDarkBlue] forState:UIControlStateNormal];
    
    UITapGestureRecognizer* gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pickerViewTapGestureRecognized:)];
    gestureRecognizer.cancelsTouchesInView = NO;
    gestureRecognizer.delegate = self;
    [_languagePicker addGestureRecognizer:gestureRecognizer];
}


- (void) sitesReady {
    [_languagePicker reloadAllComponents ];
    [self setLanguagePicker];
    
    // must come after language picker
    NSString *userid = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"userid"];
    if (userid != nil) {
        //  [self performSegueWithIdentifier:@"goToChapter" sender:self];
        NSString *languageRemembered = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"language"];
        if (languageRemembered != nil) {
            [self tryToLogIn:languageRemembered];
        }
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];   //it hides
    
    NSString *rememberedUserID = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"chosenUserID"];
    if (rememberedUserID != nil) {
        _username.text = rememberedUserID;
    }
    NSString *rememberedPass = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"chosenPassword"];
    if (rememberedPass != nil) {
        _password.text = rememberedPass;
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO];    // it shows
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return true;
}

- (void)pickerViewTapGestureRecognized:(UITapGestureRecognizer*)gestureRecognizer
{
    CGPoint touchPoint = [gestureRecognizer locationInView:gestureRecognizer.view.superview];
    
    CGRect frame = _languagePicker.frame;
    CGRect selectorFrame = CGRectInset( frame, 0.0, _languagePicker.bounds.size.height * 0.85 / 2.0 );
    // NSLog( @"Got tap -- Selected Row: %i", [_languagePicker selectedRowInComponent:0] );
    
    if( CGRectContainsPoint( selectorFrame, touchPoint) )
    {
        //  NSLog( @"Selected Row: %i", [_languagePicker selectedRowInComponent:0] );
        [self onClick:nil];
    }
    [self gotSingleTap:nil];
}

// both login and sign up button clicks come here
- (IBAction)onClick:(id)sender {
    //NSLog(@"LoginView : onClick Got click from %@", sender);
    UIButton* button = (UIButton *)sender;
    
    BOOL isLogin = ([[button restorationIdentifier] isEqualToString:@"logIn"]);
    
    NSString *chosenLanguage = [_siteGetter.languages objectAtIndex:[_languagePicker selectedRowInComponent:0]];
    
    NSLog(@"LoginView : onClick chosenLanguage %@", chosenLanguage);
    
    [self checkUpToDate];
    
    if (!isLogin) {
        NSNumber *projid = [_siteGetter.nameToProjectID objectForKey:chosenLanguage];
        NSLog(@"LoginView : onClick projid %@", projid);
        if (projid.intValue == -1) {
            [self performSegueWithIdentifier:@"goToSignUp" sender:self];
        }
//        else {
//            [self performSegueWithIdentifier:@"goToNewSignUp" sender:self];
//        }
        //return;
    }
    
    BOOL valid = true;
    if (_username.text.length == 0) {
        _usernameFeedback.text = @"Please enter a username.";
        _usernameFeedback.textColor = [UIColor redColor];
        valid = false;
    }
    if (_password.text.length == 0) {
        _passwordFeedback.text = @"Please enter a password.";
        _passwordFeedback.textColor = [UIColor redColor];
        valid = false;
    }
    
    NSLog(@"LoginView onClick language %@",chosenLanguage);
    
    if (valid) {
        _logIn.enabled = false;
        
        [self tryToLogIn:chosenLanguage];
        
        //NSLog(@"got project id %@",[_siteGetter.nameToProjectID objectForKey:chosenLanguage]);
        NSString *urlForLanguage = [_siteGetter.nameToURL objectForKey:chosenLanguage];
        [_poster setURL:urlForLanguage projid:[_siteGetter.nameToProjectID objectForKey:chosenLanguage]];
        
        [_poster postEvent:@"login" exid:@"N/A" widget:@"LogIn" widgetType:@"Button"];
    }
    else {
        NSLog(@"LoginView not valid.");
    }
}

-(void)tryToLogIn:(NSString*) chosenLanguage
{
    // make sure multiple events don't occur
    _languagePicker.userInteractionEnabled = false;
    
    NSString *urlForLanguage = [_siteGetter.nameToURL objectForKey:chosenLanguage];
    
    NSString *username =_username.text;
    NSString *password =_password.text;
    
    //NSLog(@"LoginView onClick password '%@'",_password.text);
    //NSLog(@"onClick md5 password %@",[self MD5:_password.text]);
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@scoreServlet?hasUser=%@&p=%@",
                                       urlForLanguage,
                                       username,
                                       [[self MD5:password] uppercaseString]
                                       ]];
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    
    NSNumber *projid = [_siteGetter.nameToProjectID objectForKey:chosenLanguage];
    if (projid.intValue > -1) {
        [urlRequest setValue:@"hasUser" forHTTPHeaderField:@"request"];
        if ([username length] < 5) {
            username = [username stringByAppendingString:@"_"];
            NSLog(@"tryToLogIn user %@ md5 password %@", username, [self MD5:_password.text]);
        }
        [urlRequest setValue:username forHTTPHeaderField:@"userid"];
        [urlRequest setValue:password forHTTPHeaderField:@"pass"];
        [urlRequest setValue:[projid stringValue] forHTTPHeaderField:@"projid"];
    }
    else {
    }
    
    [urlRequest setHTTPMethod: @"GET"];
    [urlRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setTimeoutInterval:15];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:true];
    
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         if (error != nil) {
             NSLog(@"\n\n\n\t1 Got error %@",error);
             dispatch_async(dispatch_get_main_queue(), ^{
                 [self connection:nil didFailWithError:error];
             });
         }
         else {
             _responseData = data;
             [self performSelectorOnMainThread:@selector(connectionDidFinishLoading:)
                                    withObject:nil
                                 waitUntilDone:YES];
         }
     }];
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    //One column
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    //set number of rows
    return _siteGetter.languages.count;
}

//-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
//{
//    //set item per row
//    return [_siteGetter.languages objectAtIndex:row];
//}

-(UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(nullable UIView *)view{
    UILabel *pView = (UILabel *)view;
    if(!pView){
        pView = [[UILabel alloc] init];
        //        CGRect frame = CGRectMake(0.0, 0.0, 80, 32);
        //        pView = [[[UILabel alloc] initWithFrame:frame] autorelease];
        [pView setFont:[UIFont boldSystemFontOfSize: 46]];
        [pView setBackgroundColor:[UIColor clearColor]];
        //        [pView setTextColor:[UIColor greenColor]];
        [pView setTextColor:[UIColor colorWithRed:3/255.0 green:99/255.0 blue:148/255.0 alpha:1.0]];
        [pView setTextAlignment: NSTextAlignmentCenter];
    }
    [pView setText:[_siteGetter.languages objectAtIndex: row]];
    return pView;
}

-(CGFloat)pickerView: (UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component{
    return 50;
}

- (void) textFieldText:(id)notification {
    _usernameFeedback.text = @"";
    _passwordFeedback.text = @"";
    _signUpFeedback.text = @"";
}

- (void) passwordChanged:(id)notification {
    [self textFieldText:nil];
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

// Ask the server if the userid exists
// if not, and we have a remembered password, add the user
// - if the reset token is sent, ask the user to reset their password
// if the user exists and the password is correct, segue to the chapter scene
- (BOOL)useJsonChapterData {
    NSError * error;
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:_responseData
                          options:NSJSONReadingAllowFragments
                          error:&error];
    
    // put the UI back to initial state
    [_activityIndicator stopAnimating];
    _logIn.enabled = true;
    _languagePicker.userInteractionEnabled = true;
    
    
    
    if (error) {
        NSLog(@"got error %@",error);
        NSLog(@"useJsonChapterData error %@",error.description);
        return false;
    }
    
    NSString *userIDExisting = [json objectForKey:@"userid"];
    NSString *passCorrectValue = [json objectForKey:@"passwordCorrect"];
    BOOL passCorrect = passCorrectValue == nil || [passCorrectValue boolValue];
    NSString *resetToken = [json objectForKey:@"token"];
    
    NSString *existing = [json objectForKey:@"ExistingUserName"];
    
    NSLog(@"useJsonChapterData existing         %@",existing);
    NSLog(@"useJsonChapterData resetToken       %@",resetToken);
    NSLog(@"useJsonChapterData userIDExisting   %@",userIDExisting);
    NSLog(@"useJsonChapterData passCorrectValue %@",passCorrectValue);
    
    if ([userIDExisting integerValue] == -1) {
        NSString *rememberedEmail = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"chosenEmail"];
        if (rememberedEmail != nil && existing == nil) {
            NSLog(@"useJsonChapterData OK, let's sign up!");
            NSString *chosenLanguage = [_siteGetter.languages objectAtIndex:[_languagePicker selectedRowInComponent:0]];
            [self addUser:chosenLanguage username:_username.text password: _password.text email:rememberedEmail];
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:true];
            [_activityIndicator startAnimating];
        }
        else {
            // no user with that name
            _passwordFeedback.text = @"Username or password incorrect";
            _signUpFeedback.text   = @"Have you signed up?";
        }
    }
    else if (resetToken.length > 0) {
        _token = resetToken;
        [self performSegueWithIdentifier:@"goToSetPassword" sender:self];
    } else if (passCorrect) {
        // OK store info and segue
        NSString *converted = [NSString stringWithFormat:@"%@",userIDExisting];
        
        [SSKeychain setPassword:converted      forService:@"mitll.proFeedback.device" account:@"userid"];
        [SSKeychain setPassword:_username.text forService:@"mitll.proFeedback.device" account:@"chosenUserID"];
        [SSKeychain setPassword:_password.text forService:@"mitll.proFeedback.device" account:@"chosenPassword"];
        NSString *chosenLanguage = [_siteGetter.languages objectAtIndex:[_languagePicker selectedRowInComponent:0]];
        [SSKeychain setPassword:chosenLanguage forService:@"mitll.proFeedback.device" account:@"language"];
        
        [self performSegueWithIdentifier:@"goToChapter" sender:self];
    } else {
        // password is bad
        _passwordFeedback.text = @"Username or password incorrect";
    }
    return true;
}

// this is a post request
- (void)addUser:(NSString *)chosenLanguage username:(NSString *)username password:(NSString *)password email:(NSString *)email {
    NSString *baseurl = [NSString stringWithFormat:@"%@scoreServlet",[_siteGetter.nameToURL objectForKey:chosenLanguage]];
    
    NSURL *url = [NSURL URLWithString:baseurl];
    NSLog(@"url %@",url);
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    
    [urlRequest setHTTPMethod: @"POST"];
    [urlRequest setValue:@"application/x-www-form-urlencoded"
      forHTTPHeaderField:@"Content-Type"];
    
    [urlRequest setValue:username forHTTPHeaderField:@"user"];
    [urlRequest setValue:[[self MD5:password] uppercaseString] forHTTPHeaderField:@"passwordH"];
    [urlRequest setValue:[[self MD5:email] uppercaseString]    forHTTPHeaderField:@"emailH"];
    [urlRequest setValue:[UIDevice currentDevice].model forHTTPHeaderField:@"deviceType"];
    NSString *retrieveuuid = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"UUID"];
    [urlRequest setValue:retrieveuuid forHTTPHeaderField:@"device"];
    
    [urlRequest setValue:@"addUser"    forHTTPHeaderField:@"request"];
    
    [urlRequest setTimeoutInterval:10];
    
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         NSLog(@"\n\n\nGot response %@",error);
         
         if (error != nil) {
             NSLog(@"\n\n\n\tGot error %@",error);
             dispatch_async(dispatch_get_main_queue(), ^{
                 [self connection:nil didFailWithError:error];
             });
         }
         else {
             _responseData = data;
             [self performSelectorOnMainThread:@selector(connectionDidFinishLoading:)
                                    withObject:nil
                                 waitUntilDone:YES];
         }
     }];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // The request is complete and data has been received
    
    [self useJsonChapterData];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // The request has failed for some reason!
    // Check the error var
    _languagePicker.userInteractionEnabled = true;
    NSLog(@"login call to server failed with %@",error);
    [_activityIndicator stopAnimating];
    _logIn.enabled = true;
    
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

- (IBAction)gotSingleTap:(id)sender {
    // NSLog(@"dismiss keyboard! %@",_currentResponder);
    [_currentResponder resignFirstResponder];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    //   NSLog(@"got text field start on %@",textField);
    _currentResponder = textField;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    //    NSLog(@"textFieldShouldBeginEditing text field start on %@",textField);
    _currentResponder = textField;
    return YES;
}

// It is important for you to hide keyboard

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)checkUpToDate {
    if (!_siteGetter.isCurrent) {
        UIAlertView *_alert = [[UIAlertView alloc] initWithTitle:@"App is out of date"
                                                         message:@"Please download from the appstore or netprof.ll.mit.edu"
                                                        delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil];
        [_alert show];
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    NSString *chosenLanguage = [_siteGetter.languages objectAtIndex:[_languagePicker selectedRowInComponent:0]];
    NSString *url= [_siteGetter.nameToURL objectForKey:chosenLanguage];
    BOOL isRTL= [_siteGetter.rtlLanguages containsObject:chosenLanguage];
    
    NSLog(@"LoginViewController : prepareForSegue login view %@ url %@ segue %@",chosenLanguage,url,segue.identifier);
    
    if ([segue.identifier isEqualToString:@"goToForgotUsername"]) {
        EAFForgotUsernameViewController *forgotUserName = [segue destinationViewController];
        forgotUserName.url =url;
        [forgotUserName setLanguage:chosenLanguage];
    }
    else if ([segue.identifier isEqualToString:@"goToForgotPassword"]) {
        EAFForgotPasswordViewController *forgotUserName = [segue destinationViewController];
        [forgotUserName setLanguage:chosenLanguage];
        // NSLog(@"username %@",_username.text);
        forgotUserName.url =url;
        forgotUserName.userFromLogin = _username.text;
    }
    else if ([segue.identifier isEqualToString:@"goToSetPassword"]) {
        [SSKeychain deletePasswordForService:@"mitll.proFeedback.device" account:@"password"];
        _password.text = @"";
        EAFSetPasswordViewController *forgotUserName = [segue destinationViewController];
        forgotUserName.url =url;
        [forgotUserName setLanguage:chosenLanguage];
        forgotUserName.token  = _token;
    }
    else if ([segue.identifier isEqualToString:@"goToChapter"]) {
        EAFChapterTableViewController *chapterController = [segue destinationViewController];
        [chapterController setLanguage:chosenLanguage];
        chapterController.url =url;
        chapterController.isRTL = isRTL;
        [chapterController setTitle:chosenLanguage];
        [self textFieldText:nil];
        [chapterController forceRefreshCache];
    }
    else if ([segue.identifier isEqualToString:@"goToSignUp"]) {
        long selection = [_languagePicker selectedRowInComponent:0];
        //NSString *chosenLanguage = [_languages objectAtIndex:selection];
        NSLog(@"LoginViewController : old identifier %@ %@ %@",segue.identifier,_username.text,_password.text);
        
        EAFSignUpViewController *signUp = [segue destinationViewController];
        
        
        NSNumber *projid = [_siteGetter.nameToProjectID objectForKey:chosenLanguage];
        NSLog(@"LoginView : segue to sign up projid %@", projid);
       
        signUp.userFromLogin = _username.text;
        //  signUp.passFromLogin = _password.text;
        signUp.languageIndex = selection;
        signUp.siteGetter = _siteGetter;
        signUp.projID = projid.intValue;
        
        [self textFieldText:nil];
    }
    else {
        NSLog(@"LoginViewController : WARN - strange segue new identifier %@ %@ %@",segue.identifier,_username.text,_password.text);
//        long selection = [_languagePicker selectedRowInComponent:0];
//        //NSString *chosenLanguage = [_languages objectAtIndex:selection];
//        NSLog(@"LoginViewController : new identifier %@ %@ %@",segue.identifier,_username.text,_password.text);
//        
//        EAFSignUpViewController *signUp = [segue destinationViewController];
//        signUp.userFromLogin = _username.text;
//        //signUp.passFromLogin = _password.text;
//        signUp.languageIndex = selection;
//        signUp.siteGetter = _siteGetter;
//        
//       // signUp.chosenLanguage = chosenLanguage;
//        
//        [self textFieldText:nil];
    }
}

@end
