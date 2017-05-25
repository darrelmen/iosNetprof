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
//  EAFSetPasswordViewController.m
//  Talks to the score servlet on the NetProF site to set the password for a userid.
//  Only the hash of the password is sent.
//  Gives feedback if we can't connect to the server.
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 11/14/14.
//  Copyright (c) 2011-2016 Massachusetts Institute of Technology, Lincoln Laboratory
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
        _confirmPasswordFeedback.text = @"Please enter the same password.";
        _confirmPasswordFeedback.textColor = [UIColor redColor];
        valid = false;
    }
    if (valid) {
        [self setPassword:[self MD5:_password.text] language:_language];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSLog(@"Got return!");
    // done button was pressed - dismiss keyboard
    [textField resignFirstResponder];
    
    if (_password.text.length > 0) {
        _passwordFeedback.text = @"";
    }
    
    if (_confirmPassword.text.length > 0) {
        _confirmPasswordFeedback.text = @"";
    }
    
    return YES;
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

- (void) setPassword:(NSString *)passwordH language:(NSString *)lang {
    NSString *baseurl = [NSString stringWithFormat:@"%@scoreServlet?setPassword=%@&email=%@", _url, _token, passwordH];
   
//    NSLog(@"url %@",baseurl);
    
    NSURL *url = [NSURL URLWithString:baseurl];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
 //   [urlRequest setCachePolicy:NSURLRequestReturnCacheDataElseLoad];
    
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
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    else {
        _passwordFeedback.text = @"Error setting new password.";
        _passwordFeedback.textColor = [UIColor redColor];
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
    
    [[[UIAlertView alloc] initWithTitle: @"Connection problem"
                                message: message
                               delegate: nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
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
