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

@interface EAFSignUpViewController ()

@end

@implementation EAFSignUpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //not japanese or levantine -- consider levantine?
    // TODO : get list of languages from server call?

    _languages = [NSArray arrayWithObjects: @"Dari", @"English",@"Egyptian",@"Farsi", @"Korean", @"CM", @"MSA", @"Pashto1", @"Pashto2", @"Pashto3", @"Russian", @"Spanish", @"Sudanese",  @"Urdu",  nil];
  
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
    
   // NSLog(@"username is %@",_username.text);
    _username.text = _userFromLogin;
    _password.text = _passFromLogin;
    [_languagePicker selectRow:_languageIndex inComponent:0 animated:false];
  
    _username.delegate = self;
    _password.delegate = self;
    _email.delegate = self;
    
    NSMutableArray *navigationArray = [[NSMutableArray alloc] initWithArray: self.navigationController.viewControllers];
    
    for (UIViewController *controller in self.navigationController.viewControllers) {
        NSLog(@"controller %@",controller);
    }
    // [navigationArray removeAllObjects];    // This is just for remove all view controller from navigation stack.
  //  [navigationArray removeObjectAtIndex: 2];  // You can pass your index here
 //   self.navigationController.viewControllers = navigationArray;
    
   // NSLog(@"username is %@",_username.text);

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onClick:(id)sender {
    NSLog(@"\n\n\n--->Got click");
    BOOL valid = true;
    if (_username.text.length == 0) {
        _usernameFeedback.text = @"Please enter a username";
        valid = false;
    }
    if (_password.text.length == 0) {
        _passwordFeedback.text = @"Please enter a password";
        valid = false;
    }
    if (_email.text.length == 0) {
        _emailFeedback.text = @"Please enter your email.";
        valid = false;
    }
    if (![self validateEmail:_email.text]) {
        _emailFeedback.text = @"Please enter a valid email address.";
        valid = false;
    }
    
    if (valid) {
        NSString *chosenLanguage = [_languages objectAtIndex:[_languagePicker selectedRowInComponent:0]];
        
        NSLog(@"language %@",chosenLanguage);
        
        NSLog(@"password '%@'",_password.text);
        NSString *baseurl = [NSString stringWithFormat:@"https://np.ll.mit.edu/npfClassroom%@/scoreServlet",//=%@&p=%@&e=%@",
                             chosenLanguage
                             //,
                             //_username.text,
                             //[[self MD5:_password.text] uppercaseString],
                             //[[self MD5:_email.text] uppercaseString]
                             ];

        NSURL *url = [NSURL URLWithString:baseurl];
        
        NSLog(@"url %@",url);

        NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
        [urlRequest setCachePolicy:NSURLRequestReturnCacheDataElseLoad];
        
        [urlRequest setHTTPMethod: @"POST"];
        [urlRequest setValue:@"application/x-www-form-urlencoded"
          forHTTPHeaderField:@"Content-Type"];
        
        [urlRequest setValue:_username.text forHTTPHeaderField:@"user"];
        [urlRequest setValue:[[self MD5:_password.text] uppercaseString] forHTTPHeaderField:@"passwordH"];
        [urlRequest setValue:[[self MD5:_email.text] uppercaseString]    forHTTPHeaderField:@"emailH"];
        [urlRequest setValue:@"addUser"    forHTTPHeaderField:@"request"];
        
        NSURLConnection *connection = [NSURLConnection connectionWithRequest:urlRequest delegate:self];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:true];
        
        [connection start];
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
    _usernameFeedback.text = @"";
    _passwordFeedback.text = @"";
    _emailFeedback.text = @"";

}

- (void) passwordChanged:(id)notification {
    _usernameFeedback.text = @"";
    _passwordFeedback.text = @"";
    _emailFeedback.text = @"";}

- (void) emailChanged:(id)notification {
    _usernameFeedback.text = @"";
    _passwordFeedback.text = @"";
    _emailFeedback.text = @"";
}

- (IBAction)gotSingleTap:(id)sender {
    NSLog(@"dismiss keyboard! %@",_currentResponder);
    
    [_currentResponder resignFirstResponder];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    NSLog(@"got text field start on %@",textField);
    _currentResponder = textField;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    
    NSLog(@"textFieldShouldBeginEditing text field start on %@",textField);
    
    _currentResponder = textField;
    
    return YES;
}

// It is important for you to hide kwyboard

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
    
    if (error) {
        NSLog(@"useJsonChapterData error %@",error.description);
        return false;
    }
    
       NSLog(@"useJsonChapter got %@ ",json);
    //ExistingUserName
    NSString *existing = [json objectForKey:@"ExistingUserName"];
    
    
    NSString *userIDExisting = [json objectForKey:@"userid"];
   // BOOL passCorrect = [[json objectForKey:@"passwordCorrect"] boolValue];
    
    if (existing != nil) {
        // no user with that name
        _usernameFeedback.text = @"Username exists already.";
    }
    else {//if (passCorrect) {
        // OK store info and segue
        NSLog(@"userid %@",userIDExisting);
        NSString *converted = [NSString stringWithFormat:@"%@",userIDExisting];
        [SSKeychain setPassword:converted forService:@"mitll.proFeedback.device" account:@"userid"];
        NSString *chosenLanguage = [_languages objectAtIndex:[_languagePicker selectedRowInComponent:0]];
        NSLog(@"chosenLanguage %@",chosenLanguage);

        [SSKeychain setPassword:chosenLanguage forService:@"mitll.proFeedback.device" account:@"language"];
        [self performSegueWithIdentifier:@"goToChapterFromSignUp" sender:self];
   }
    //else {
        // password is bad
   //     _passwordFeedback.text = @"Username or password incorrect";

//    }
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
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Connection problem"
                                                    message: @"Couldn't connect to server."
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
