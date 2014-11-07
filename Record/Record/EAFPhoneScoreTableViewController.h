//
//  EAFLanguageTableViewController.h
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 7/16/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EAFPhoneScoreTableViewController : UITableViewController<NSURLConnectionDelegate>

@property (strong, nonatomic) NSMutableData *responseData;

@property NSString *language;

@property NSString *chapterName;
@property NSString *chapterSelection;
@property NSDictionary *phoneToWords;
@property NSDictionary *resultToRef;
@property NSDictionary *resultToAnswer;
@property NSArray *phonesInOrder;

@property long user;

@end
