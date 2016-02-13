//
//  EAFLoginViewController.m
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 11/14/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import "EAFForgotUsernameViewController.h"
#import <CommonCrypto/CommonDigest.h>
#import "SSKeychain.h"

@interface EAFForgotUsernameViewController ()

@property (nonatomic, assign) id currentResponder;

@end

@implementation EAFForgotUsernameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setTitle:[NSString stringWithFormat:@"Forgot username for %@",_language]];
}

- (IBAction)gotClick:(id)sender {
    BOOL valid = true;
    
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                           selector:@selector (textFieldText:)
                               name:UITextFieldTextDidChangeNotification
                             object:_email];
}

- (void) textFieldText:(id)notification {
    _emailFeedback.text = @"";
}

- (BOOL) validateEmail: (NSString *) candidate {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    
    return [emailTest evaluateWithObject:candidate];
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
  //  NSLog(@"Got return!");
    // done button was pressed - dismiss keyboard
    [textField resignFirstResponder];
    return YES;
}


#pragma mark NSURLConnection Delegate Methods


- (void) forgotUsername:(NSString *)email language:(NSString *)lang {
    NSString *baseurl = [NSString stringWithFormat:@"%@/scoreServlet?forgotUsername=%@", _url, email];
    
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
    NSString *validEmail = [json objectForKey:@"valid"];
    BOOL value = [validEmail boolValue];
    if (value) {//[validEmail isEqualToString:@"true"]) {
        _emailFeedback.text = @"Please check your email";
        _emailFeedback.textColor = [UIColor blackColor];
    }
    else {
        _emailFeedback.text = @"Unknown email address";
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
//    // Get the new view controller using [segue destinationViewController].
//    // Pass the selected object to the new view controller.
//}
//
//
@end
