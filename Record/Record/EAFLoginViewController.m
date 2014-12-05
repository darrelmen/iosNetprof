//
//  EAFLoginViewController.m
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 11/14/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
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

@interface EAFLoginViewController ()

@end

@implementation EAFLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //not japanese or levantine -- consider levantine?
    // TODO : get list of languages from server call?

    _langauges = [NSArray arrayWithObjects: @"Dari", @"English",
                  //@"Egyptian",
                  @"Farsi", @"Korean", @"CM", @"MSA", @"Pashto1", @"Pashto2", @"Pashto3", @"Russian", @"Spanish", @"Sudanese",  @"Urdu",  nil];
  
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
    
    NSString *rememberedUserID = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"chosenUserID"];
    if (rememberedUserID != nil) {
        _username.text = rememberedUserID;
    }
    NSString *rememberedPass = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"chosenPassword"];
    if (rememberedPass != nil) {
        _password.text = rememberedPass;
    }
    
    NSString *rememberedLanguage = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"language"];
    if (rememberedLanguage != nil) {
      //  _password.text = rememberedLanguage;
        // TODO : set picker with chosen language
    }
    
    [_forgotUsername initWithFrame:CGRectMake(0.0f, 0.0f, 32.0f, 32.0f)
                             color:[UIColor colorWithWhite:1.0f alpha:0.0f]
                             style:BButtonStyleBootstrapV3
                              icon:FAQuestion
                          fontSize:20.0f];
    [_forgotUsername setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];

    [_forgotPassword initWithFrame:CGRectMake(0.0f, 0.0f, 32.0f, 32.0f)
                             color:[UIColor colorWithWhite:1.0f alpha:0.0f]
                             style:BButtonStyleBootstrapV3
                              icon:FAQuestion
                          fontSize:20.0f];
    [_forgotPassword setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    
    UITapGestureRecognizer* gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pickerViewTapGestureRecognized:)];
    gestureRecognizer.cancelsTouchesInView = NO;
     gestureRecognizer.delegate = self;
    [self.languagePicker addGestureRecognizer:gestureRecognizer];
    
    NSString *userid = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"userid"];
    if (userid != nil) {
        [self performSegueWithIdentifier:@"goToChapter" sender:self];
    }
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
}

- (IBAction)onClick:(id)sender {
   // NSLog(@"Got click");
    BOOL valid = true;
    if (_username.text.length == 0) {
        _usernameFeedback.text = @"Please enter a username";
        valid = false;
    }
    if (_password.text.length == 0) {
        _passwordFeedback.text = @"Please enter a password";
        valid = false;
    }
    
    NSString *chosenLanguage = [_langauges objectAtIndex:[_languagePicker selectedRowInComponent:0]];
    
    NSLog(@"language %@",chosenLanguage);
    
    if (valid) {
        // make sure multiple events don't occur
        _languagePicker.userInteractionEnabled = false;
        NSLog(@"password '%@'",_password.text);
        NSString *baseurl = [NSString stringWithFormat:@"https://np.ll.mit.edu/npfClassroom%@/scoreServlet?hasUser=%@&p=%@", chosenLanguage,_username.text,[[self MD5:_password.text] uppercaseString]];
        NSURL *url = [NSURL URLWithString:baseurl];
        
        NSLog(@"url %@",url);

        NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
        [urlRequest setCachePolicy:NSURLRequestReturnCacheDataElseLoad];
        
        [urlRequest setHTTPMethod: @"GET"];
        [urlRequest setValue:@"application/x-www-form-urlencoded"
          forHTTPHeaderField:@"Content-Type"];
        
        NSURLConnection *connection = [NSURLConnection connectionWithRequest:urlRequest delegate:self];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:true];
        
        [connection start];
        [_activityIndicator startAnimating];
        _logIn.enabled = false;
        
        EAFEventPoster *poster = [[EAFEventPoster alloc] init];
        [poster postEvent:@"login" exid:@"N/A" lang:chosenLanguage widget:@"LogIn" widgetType:@"Button"];
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
    return _langauges.count;
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    //set item per row
    NSString *lang = [_langauges objectAtIndex:row];
    if ([lang isEqualToString:@"CM"]) {
        return @"Mandarin";
    }
    else {
        return lang;
    }
}

- (void) textFieldText:(id)notification {
    _usernameFeedback.text = @"";
    _passwordFeedback.text = @"";
    _signUpFeedback.text = @"";
}

- (void) passwordChanged:(id)notification {
    _usernameFeedback.text = @"";
    _passwordFeedback.text = @"";
    _signUpFeedback.text = @"";
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
    
    if (error) {
        NSLog(@"useJsonChapterData error %@",error.description);
        return false;
    }
    
    [_activityIndicator stopAnimating];
    
    NSString *userIDExisting = [json objectForKey:@"userid"];
    BOOL passCorrect = [[json objectForKey:@"passwordCorrect"] boolValue];
    NSString *resetToken = [json objectForKey:@"token"];
    
    _logIn.enabled = true;
    _languagePicker.userInteractionEnabled = true;
    if ([userIDExisting integerValue] == -1) {
        // no user with that name
        _passwordFeedback.text = @"Username or password incorrect";
        _signUpFeedback.text = @"Have you signed up?";

    }
    else if (resetToken.length > 0) {
        _token = resetToken;
        [self performSegueWithIdentifier:@"goToSetPassword" sender:self];

    } else if (passCorrect) {
        // OK store info and segue
        NSString *converted = [NSString stringWithFormat:@"%@",userIDExisting];
        [SSKeychain setPassword:converted forService:@"mitll.proFeedback.device" account:@"userid"];
        [SSKeychain setPassword:_username.text forService:@"mitll.proFeedback.device" account:@"chosenUserID"];
        [SSKeychain setPassword:_password.text forService:@"mitll.proFeedback.device" account:@"chosenPassword"];
        NSString *chosenLanguage = [_langauges objectAtIndex:[_languagePicker selectedRowInComponent:0]];
        NSLog(@"chosenLanguage %@",chosenLanguage);

        [SSKeychain setPassword:chosenLanguage forService:@"mitll.proFeedback.device" account:@"language"];
        [self performSegueWithIdentifier:@"goToChapter" sender:self];
   } else {
        // password is bad
        _passwordFeedback.text = @"Username or password incorrect";
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
    _languagePicker.userInteractionEnabled = true;
    NSLog(@"login call to server failed with %@",error);
    [_activityIndicator stopAnimating];

    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Connection problem"
                                                    message: @"Couldn't connect to server."
                                                   delegate: nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (IBAction)gotSingleTap:(id)sender {
    NSLog(@"dismiss keyboard! %@",_currentResponder);
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

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([segue.identifier isEqualToString:@"goToForgotUsername"]) {
        EAFForgotUsernameViewController *forgotUserName = [segue destinationViewController];
        
        NSString *chosenLanguage = [_langauges objectAtIndex:[_languagePicker selectedRowInComponent:0]];
        [forgotUserName setLanguage:chosenLanguage];
    }
    else if ([segue.identifier isEqualToString:@"goToForgotPassword"]) {
        EAFForgotPasswordViewController *forgotUserName = [segue destinationViewController];
        
        NSString *chosenLanguage = [_langauges objectAtIndex:[_languagePicker selectedRowInComponent:0]];
        [forgotUserName setLanguage:chosenLanguage];
        NSLog(@"username %@",_username.text);
        forgotUserName.userFromLogin = _username.text;
    }
    else if ([segue.identifier isEqualToString:@"goToSetPassword"]) {
        [SSKeychain deletePasswordForService:@"mitll.proFeedback.device" account:@"password"];
        _password.text = @"";
        EAFSetPasswordViewController *forgotUserName = [segue destinationViewController];
        
        NSString *chosenLanguage = [_langauges objectAtIndex:[_languagePicker selectedRowInComponent:0]];
        [forgotUserName setLanguage:chosenLanguage];
        forgotUserName.token  = _token;
    }
    else if ([segue.identifier isEqualToString:@"goToChapter"]) {
        EAFChapterTableViewController *chapterController = [segue destinationViewController];
        
        NSString *chosenLanguage = [_langauges objectAtIndex:[_languagePicker selectedRowInComponent:0]];
        [chapterController setLanguage:chosenLanguage];
        
        NSString *toShow = chosenLanguage;
        if ([toShow isEqualToString:@"CM"]) {
            toShow = @"Mandarin";
        }
        [chapterController setTitle:toShow];
    }
    else {
        EAFSignUpViewController *signUp = [segue destinationViewController];
        
        long selection = [_languagePicker selectedRowInComponent:0];
        
       // NSString *chosenLanguage = [_langauges objectAtIndex:selection];
        //[signUp.languagePicker selectRow:selection inComponent:0 animated:false];
        
       // NSLog(@"language %@ %@ %@",chosenLanguage,_username.text,_password.text);
        
        signUp.userFromLogin = _username.text;
        signUp.passFromLogin = _password.text;
        signUp.languageIndex = selection;
        
        _usernameFeedback.text = @"";
        _passwordFeedback.text = @"";
        _signUpFeedback.text = @"";
    }
}

@end
