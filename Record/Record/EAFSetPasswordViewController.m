//
//  EAFLoginViewController.m
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 11/14/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import "EAFSetPasswordViewController.h"
#import <CommonCrypto/CommonDigest.h>
#import "SSKeychain.h"

@interface EAFSetPasswordViewController ()

@end

@implementation EAFSetPasswordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setTitle:[NSString stringWithFormat:@"Set new password for %@",_language]];
    _confirmPassword.text = _userFromLogin;
}

- (IBAction)gotClick:(id)sender {
    BOOL valid = true;
    
    if (_password.text.length == 0) {
        _passwordFeedback.text = @"Please enter a password";
        _passwordFeedback.textColor = [UIColor redColor];
        valid = false;
    }
    
    if (_confirmPassword.text.length == 0) {
        _confirmPasswordFeedback.text = @"Please enter a password.";
        _confirmPasswordFeedback.textColor = [UIColor redColor];
        valid = false;
    }

    if (![_password.text isEqualToString:_confirmPassword.text]) {
        _confirmPasswordFeedback.text = @"Please enter the same email as above.";
        _confirmPasswordFeedback.textColor = [UIColor redColor];
        valid = false;
    }
    if (valid) {
        
        [self forgotUsername:[self MD5:_password.text] language:_language];
    }
    
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


- (void) forgotUsername:(NSString *)passwordH language:(NSString *)lang {
    NSString *baseurl = [NSString stringWithFormat:@"https://np.ll.mit.edu/npfClassroom%@/scoreServlet?setPassword=%@&email=%@", lang, _token, passwordH];
    
    NSLog(@"url %@",baseurl);
    
    NSURL *url = [NSURL URLWithString:baseurl];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    [urlRequest setCachePolicy:NSURLRequestReturnCacheDataElseLoad];
    
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
    
    NSLog(@"set password - connectionDidFinishLoading got %@ ",json);
    NSString *validEmail = [json objectForKey:@"valid"];

    if ([validEmail boolValue]) {
        // force user to enter in userid and password again
        [SSKeychain deletePasswordForService:@"mitll.proFeedback.device" account:@"userid"];

  //      [self performSegueWithIdentifier:@"goBackToLogin" sender:self];
        
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    else {
        _passwordFeedback.text = @"Error setting new password.";
               _passwordFeedback.textColor = [UIColor redColor];
    }
    //
//    if ([validEmail isEqualToString:@"PASSWORD_EMAIL_SENT"]) {
//        _confirmPasswordFeedback.text = @"Please check your email";
//        _confirmPasswordFeedback.textColor = [UIColor blackColor];
//    }
//    else {
//        _confirmPasswordFeedback.text = @"Unknown email address for user.";
//        _confirmPasswordFeedback.textColor = [UIColor redColor];
//    }
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
//
//// In a storyboard-based application, you will often want to do a little preparation before navigation
//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    // Get the new view controller using [segue destinationViewController].
//    // Pass the selected object to the new view controller.
//    
//    EAFChapterTableViewController *chapterController = [segue destinationViewController];
//    
//     NSString *chosenLanguage = [_languages objectAtIndex:[_languagePicker selectedRowInComponent:0]];
//    [chapterController setLanguage:chosenLanguage];
//    
//    NSString *toShow = chosenLanguage;
//    if ([toShow isEqualToString:@"CM"]) {
//        toShow = @"Mandarin";
//    }
//    [chapterController setTitle:toShow];
//}
//
//
@end