//
//  EAFAudioCache.h
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 11/20/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EAFLoginViewController.h"

@interface EAFForgotUsername : NSObject<NSURLConnectionDelegate>

- (void) forgotUsername:(NSString *)email language:(NSString *)lang loginView:(EAFLoginViewController *)loginViewController;

@property (strong, nonatomic) NSMutableData *responseData;
@property NSArray *jsonContentArray;
@property EAFLoginViewController *login;

@end
