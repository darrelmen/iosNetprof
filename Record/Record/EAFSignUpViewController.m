//
//  EAFLoginViewController.m
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 11/14/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import "EAFSignUpViewController.h"
#import <CommonCrypto/CommonDigest.h>
#import "SSKeychain.h"
#import "EAFChapterTableViewController.h"
#import "EAFEventPoster.h"

@interface EAFSignUpViewController ()

@end

@implementation EAFSignUpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //not japanese or egyptian?
    // TODO : get list of languages from server call?
    // TODO : don't duplicate this with login page
    _languages = [NSArray arrayWithObjects: @"Dari", @"English",
                  @"Egyptian",
                  @"Farsi",
                  @"Korean",
                  //  @"Levantine",
                  @"CM",
                  @"MSA", @"Pashto1", @"Pashto2", @"Pashto3",
                  //@"Russian", @"Spanish",
                  @"Sudanese",  @"Urdu",  nil];
  
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserver:self
                           selector:@selector (textFieldText:)
                               name:UITextFieldTextDidChangeNotification
                             object:_username];
   
    [notificationCenter addObserver:self
                           selector:@selector (passwordChanged:)
                               name:UITextFieldTextDidChangeNotification
                             object:_password];
    
    [notificationCenter addObserver:self
                           selector:@selector (emailChanged:)
                               name:UITextFieldTextDidChangeNotification
                             object:_email];
    
    _username.text = _userFromLogin;
    _password.text = _passFromLogin;
    [_languagePicker selectRow:_languageIndex inComponent:0 animated:false];
  
    _username.delegate = self;
    _password.delegate = self;
    _email.delegate = self;
    
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
    
    UITapGestureRecognizer* gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pickerViewTapGestureRecognized:)];
    gestureRecognizer.cancelsTouchesInView = NO;
    gestureRecognizer.delegate = self;
    [self.languagePicker addGestureRecognizer:gestureRecognizer];
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

- (void)addUser:(NSString *)chosenLanguage username:(NSString *)username password:(NSString *)password email:(NSString *)email {
    NSString *baseurl = [NSString stringWithFormat:@"https://np.ll.mit.edu/npfClassroom%@/scoreServlet",chosenLanguage
                         ];
    
    NSURL *url = [NSURL URLWithString:baseurl];
    //NSLog(@"url %@",url);
    
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
    [[NSURLConnection connectionWithRequest:urlRequest delegate:self] start];
}

- (IBAction)onClick:(id)sender {
    _signUp.enabled = false;
    
    BOOL valid = true;
    if (_username.text.length == 0) {
        _usernameFeedback.text = @"Please enter a username.";
        valid = false;
    }
    if (_username.text.length < 4) {
        _usernameFeedback.text = @"Please enter a longer username.";
        valid = false;
    }
    if (_password.text.length == 0) {
        _passwordFeedback.text = @"Please enter a password.";
        valid = false;
    }
    if (_password.text.length < 4) {
        _passwordFeedback.text = @"Please enter a longer password.";
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
        _emailFeedback.textColor = [UIColor blackColor];

        NSString *chosenLanguage = [_languages objectAtIndex:[_languagePicker selectedRowInComponent:0]];
        NSString *username = _username.text;
        NSString *password = _password.text;
        NSString *email = _email.text;
        
        [self addUser:chosenLanguage username:username password:password email:email];
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:true];
        [_activityIndicator startAnimating];
        
        EAFEventPoster *poster = [[EAFEventPoster alloc] init];
        [poster postEvent:[NSString stringWithFormat:@"signUp by %@",_username.text] exid:@"N/A" lang:chosenLanguage widget:@"SignIn" widgetType:@"Button"];
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
    return _languages.count;
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    //set item per row
    NSString *lang = [_languages objectAtIndex:row];
    if ([lang isEqualToString:@"CM"]) {
        return @"Mandarin";
    }
    else {
        return lang;
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
        NSLog(@"useJsonChapterData error %@",error.description);
        _signUp.enabled = true;
        return false;
    }
    
    //   NSLog(@"useJsonChapter got %@ ",json);
    NSString *existing = [json objectForKey:@"ExistingUserName"];
    
    NSString *userIDExisting = [json objectForKey:@"userid"];
   
    if (existing != nil) {
        // no user with that name
        _usernameFeedback.text = @"Username exists already.";
    }
    else {
        // OK store info and segue
        NSLog(@"userid %@",userIDExisting);
        NSString *converted = [NSString stringWithFormat:@"%@",userIDExisting];
        [SSKeychain setPassword:converted forService:@"mitll.proFeedback.device" account:@"userid"];
        [SSKeychain setPassword:_username.text forService:@"mitll.proFeedback.device" account:@"chosenUserID"];
        [SSKeychain setPassword:_password.text forService:@"mitll.proFeedback.device" account:@"chosenPassword"];
        [SSKeychain setPassword:_email.text forService:@"mitll.proFeedback.device" account:@"chosenEmail"];
        NSString *chosenLanguage = [_languages objectAtIndex:[_languagePicker selectedRowInComponent:0]];
        [SSKeychain setPassword:chosenLanguage forService:@"mitll.proFeedback.device" account:@"language"];
        
        [self performSegueWithIdentifier:@"goToChapterFromSignUp" sender:self];
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

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    EAFChapterTableViewController *chapterController = [segue destinationViewController];
    
     NSString *chosenLanguage = [_languages objectAtIndex:[_languagePicker selectedRowInComponent:0]];
    [chapterController setLanguage:chosenLanguage];
    
    NSString *toShow = chosenLanguage;
    if ([toShow isEqualToString:@"CM"]) {
        toShow = @"Mandarin";
    }
    [chapterController setTitle:toShow];
}


@end
