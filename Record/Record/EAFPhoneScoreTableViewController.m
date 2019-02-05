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
//  EAFPhoneScoreTableViewController
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 7/16/14.
//  Copyright (c) 2011-2016 Massachusetts Institute of Technology, Lincoln Laboratory
//

#import "EAFPhoneScoreTableViewController.h"
#import "FAImageView.h"
#import "MyTableViewCell.h"
#import "EAFAudioView.h"
#import "EAFAudioCache.h"
#import "EAFAudioPlayer.h"
#import "EAFEventPoster.h"
#import "EAFGetSites.h"

#import <AudioToolbox/AudioServices.h>
#import "SSKeychain.h"
#import "UIColor_netprofColors.h"

@interface EAFPhoneScoreTableViewController ()

@property int rowHeight;
@property BOOL showPhonesLTRAlways;  // constant
@property EAFAudioCache *audioCache;
@property EAFAudioView * currentAudioSelection;
@property EAFAudioPlayer *myAudioPlayer;
@property (strong, nonatomic) NSData *responseData;
@property EAFGetSites *siteGetter;

@end

@implementation EAFPhoneScoreTableViewController

const BOOL debug = FALSE;

- (void)viewDidLoad
{
    [super viewDidLoad];
    _audioCache = [[EAFAudioCache alloc] init];
    _audioCache.language = _language;

    _showPhonesLTRAlways = true;
    
    _rowHeight = 66;
    NSString *userid = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"userid"];
    _user = [userid intValue];
    
    _myAudioPlayer = [[EAFAudioPlayer alloc] init];
    _myAudioPlayer.url = _url;
    _myAudioPlayer.language = _language;
    _myAudioPlayer.delegate = self;
    
    _siteGetter = [EAFGetSites new];
    _siteGetter.delegate = self;
    
    [self askServerForJson];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    // _tableView.cancelTouchesInView = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_audioCache cancelAllOperations];
    [_myAudioPlayer stopAudio];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (_responseData == nil) { // if it failed before.
        // NSLog(@"PhoneScoreTableViewController.viewWillAppear - ask server for json");
        [self askServerForJson];
    }
}

-(void)setCurrentTitle {
    [self parentViewController].navigationItem.title = @"Touch to compare audio";
}

- (BOOL) cancelTouchesInView {
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)askServerForJson {
    NSString *baseurl = [NSString stringWithFormat:@"%@scoreServlet?request=phoneReport&user=%ld&%@=%@&%@=%@", _url, _user, _unitName, _unitSelection, _chapterName, _chapterSelection];
    baseurl =[baseurl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
 
    //   baseurl = [NSString stringWithFormat:@"%@&projid=%@", baseurl, _projid];

    if (_listid != NULL) {
        baseurl = [NSString stringWithFormat:@"%@&listid=%@", baseurl, _listid];
    }

    NSLog(@"EAFPhoneScoreTableViewController url %@ %@",baseurl,_projid);
    
    NSURL *url = [NSURL URLWithString:baseurl];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    
    [urlRequest setValue:[NSString stringWithFormat:@"%@",_projid] forHTTPHeaderField:@"projid"];
    
    [urlRequest setHTTPMethod: @"GET"];
    [urlRequest setValue:@"application/x-www-form-urlencoded"
      forHTTPHeaderField:@"Content-Type"];
    
  //  [urlRequest setTimeoutInterval:1];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:true];
    
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         if (error != nil) {
             NSLog(@"PhoneScoreTableViewController Got error %@",error);
             
             dispatch_async(dispatch_get_main_queue(), ^{
                 [self connection:nil didFailWithError:error];
             });
         }
         else {
             self->_responseData = data;
             [self performSelectorOnMainThread:@selector(connectionDidFinishLoading:)
                                    withObject:nil
                                 waitUntilDone:YES];
         }
     }];
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView
estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return  _rowHeight;
}

- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return  _rowHeight;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return _phoneToWords.count;
}

- (UILabel *)getOverallPhoneLabel:(NSString *)phone cell:(UITableViewCell *)cell
{
    UILabel *overallPhoneLabel = [[UILabel alloc] init];
    [cell.contentView addSubview:overallPhoneLabel];
    
    overallPhoneLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    overallPhoneLabel.text = phone;
    [overallPhoneLabel setFont:[UIFont systemFontOfSize:32]];
    
    // top
    
    [cell.contentView addConstraint:[NSLayoutConstraint
                                     constraintWithItem:overallPhoneLabel
                                     attribute:NSLayoutAttributeTop
                                     relatedBy:NSLayoutRelationEqual
                                     toItem:cell.contentView
                                     attribute:NSLayoutAttributeTop
                                     multiplier:1.0
                                     constant:0.0]];
    
    // bottom
    
    [cell.contentView addConstraint:[NSLayoutConstraint
                                     constraintWithItem:overallPhoneLabel
                                     attribute:NSLayoutAttributeBottom
                                     relatedBy:NSLayoutRelationEqual
                                     toItem:cell.contentView
                                     attribute:NSLayoutAttributeBottom
                                     multiplier:1.0
                                     constant:0.0]];
    // left
    
    [cell.contentView addConstraint:[NSLayoutConstraint
                                     constraintWithItem:overallPhoneLabel
                                     attribute:NSLayoutAttributeLeft
                                     relatedBy:NSLayoutRelationEqual
                                     toItem:cell.contentView
                                     attribute:NSLayoutAttributeLeft
                                     multiplier:1.0
                                     constant:1.0]];
    
    [cell.contentView addConstraint:[NSLayoutConstraint
                                     constraintWithItem:overallPhoneLabel
                                     attribute:NSLayoutAttributeWidth
                                     relatedBy:NSLayoutRelationGreaterThanOrEqual
                                     toItem:nil
                                     attribute:NSLayoutAttributeNotAnAttribute
                                     multiplier:1.0
                                     constant:50.0]];
    return overallPhoneLabel;
}

- (void)addWordLabelConstraints:(EAFAudioView *)exampleView wordLabel:(UILabel *)wordLabel
{
    // top
    [exampleView addConstraint:[NSLayoutConstraint
                                constraintWithItem:wordLabel
                                attribute:NSLayoutAttributeTop
                                relatedBy:NSLayoutRelationEqual
                                toItem:exampleView
                                attribute:NSLayoutAttributeTop
                                multiplier:1.0
                                constant:0.0]];
    
    // left
    [exampleView addConstraint:[NSLayoutConstraint
                                constraintWithItem:wordLabel
                                attribute:NSLayoutAttributeLeft
                                relatedBy:NSLayoutRelationEqual
                                toItem:exampleView
                                attribute:NSLayoutAttributeLeft
                                multiplier:1.0
                                constant:0.0]];
    
    // right
    [exampleView addConstraint:[NSLayoutConstraint
                                constraintWithItem:wordLabel
                                attribute:NSLayoutAttributeRight
                                relatedBy:NSLayoutRelationEqual
                                toItem:exampleView
                                attribute:NSLayoutAttributeRight
                                multiplier:1.0
                                constant:0.0]];
    
    // height
    [exampleView addConstraint:[NSLayoutConstraint
                                constraintWithItem:wordLabel
                                attribute:NSLayoutAttributeHeight
                                relatedBy:NSLayoutRelationEqual
                                toItem:exampleView
                                attribute:NSLayoutAttributeHeight
                                multiplier:0.5
                                constant:0.0]];
}

- (NSString *)getPhonesToShow:(NSDictionary *)lastPhone addSpaces:(BOOL)addSpaces phoneArray:(NSArray *)phoneArray
{
    NSString *phoneToShow = @"";
    for (NSDictionary *phoneInfo in phoneArray) {
        NSString *phoneText =[phoneInfo objectForKey:@"p"];
        phoneToShow = [phoneToShow stringByAppendingString:phoneText];
        
        if (addSpaces) {
            if (phoneInfo != lastPhone && ![_language isEqualToString:@"Korean"]) {
                phoneToShow = [phoneToShow stringByAppendingString:@" "];
            }
        }
    }
    return phoneToShow;
}

- (void)addPhoneLabelConstrains:(UILabel *)phoneLabel exampleView:(EAFAudioView *)exampleView
{
    [phoneLabel setFont:[UIFont systemFontOfSize:24]];
    
    [phoneLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    
    [exampleView addConstraint:[NSLayoutConstraint
                                constraintWithItem:phoneLabel
                                attribute:NSLayoutAttributeHeight
                                relatedBy:NSLayoutRelationEqual
                                toItem:exampleView
                                attribute:NSLayoutAttributeHeight
                                multiplier:0.5
                                constant:0.0]];
    
    [exampleView addConstraint:[NSLayoutConstraint
                                constraintWithItem:phoneLabel
                                attribute:NSLayoutAttributeLeft
                                relatedBy:NSLayoutRelationEqual
                                toItem:exampleView
                                attribute:NSLayoutAttributeLeft
                                multiplier:1.0
                                constant:0.0]];
    
    [exampleView addConstraint:[NSLayoutConstraint
                                constraintWithItem:phoneLabel
                                attribute:NSLayoutAttributeRight
                                relatedBy:NSLayoutRelationEqual
                                toItem:exampleView
                                attribute:NSLayoutAttributeRight
                                multiplier:1.0
                                constant:0.0]];
    
    [exampleView addConstraint:[NSLayoutConstraint
                                constraintWithItem:phoneLabel
                                attribute:NSLayoutAttributeBottom
                                relatedBy:NSLayoutRelationEqual
                                toItem:exampleView
                                attribute:NSLayoutAttributeBottom
                                multiplier:1.0
                                constant:0.0]];
}

- (UILabel *)getLabelForWord:(float)score word:(NSString *)word {
    //NSLog(@"resultWords : wordInResult is %@",wordInResult);
    
    UILabel *wordLabel = [[UILabel alloc] init];
    
    if ([_language isEqualToString:@"English"]) {
        word = [word lowercaseString];
    }
    
    if (debug) NSLog(@"resultWords : Word is %@",word);
    
    NSMutableAttributedString *coloredWord = [[NSMutableAttributedString alloc] initWithString:word];
    
    NSRange range = NSMakeRange(0, [coloredWord length]);
    
    
    //    NSLog(@"score was %@ %f",scoreString,score);
    if (score > 0) {
        UIColor *color = [self getColor2:score];
        [coloredWord addAttribute:NSBackgroundColorAttributeName
                            value:color
                            range:range];
    }
    
    wordLabel.attributedText = coloredWord;
   // NSLog(@"label word is %@",wordLabel.attributedText);
    [wordLabel setFont:[UIFont systemFontOfSize:24]];
    
    [wordLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    return wordLabel;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Configure the cell...
    static NSString *CellIdentifier = @"PhoneCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(gotTapGesture:)];
    tap.cancelsTouchesInView = YES;
    tap.numberOfTapsRequired = 1;
    [cell addGestureRecognizer:tap];
    
    UIView *bgColorView = [[UIView alloc] init];
    
    [bgColorView setBackgroundColor:[UIColor whiteColor]];
    [cell setSelectedBackgroundView:bgColorView];
    
    NSString *phone = [_phonesInOrder objectAtIndex:indexPath.row];
    
    NSLog(@"tableView phone is %@",phone);
    
    for (UIView *v in [cell.contentView subviews]) {
        [v removeFromSuperview];
    }
    [cell.contentView removeConstraints:cell.contentView.constraints];
    cell.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSLayoutConstraint *constraint = [NSLayoutConstraint
                                      constraintWithItem:cell.contentView
                                      attribute:NSLayoutAttributeLeft
                                      relatedBy:NSLayoutRelationEqual
                                      toItem:cell.contentView.superview
                                      attribute:NSLayoutAttributeLeft
                                      multiplier:1.0
                                      constant:3.0];
    
    [cell.contentView.superview addConstraint:constraint];
    
    NSArray *words = [_phoneToWords objectForKey:phone];
   
    
    // NSLog(@"tableView words for %@ = %@",phone, words);
    
    UIView *leftView = nil;
    
    UILabel *overallPhoneLabel = [self getOverallPhoneLabel:phone cell:cell];
    
    
    float totalPhoneScore = 0.0f;
    float totalPhones = 0.0f;
    // int count = 0;
    BOOL addSpaces = false;
    BOOL debug=false;
    BOOL debug2=false;

    // try to worry about the same word appearing multiple times...
    NSMutableSet *shownSoFar = [[NSMutableSet alloc] init];
    for (NSDictionary *wordEntry in words) {
        // TODO iterate over first N words in example words for phone
        // NSLog(@"about to ask for word from %@",wordEntry);
        
        NSString *word = [wordEntry objectForKey:@"w"];
        if (debug2) NSLog(@"phone %@ word is %@",phone,word);

        // TODO : fix this on the server!
        // don't show more than one example of a word
        if ([shownSoFar containsObject:word]) continue;
        else [shownSoFar addObject:word];
        
        //    if (count++ > 5) break; // only first five?
        NSString *result = [wordEntry objectForKey:@"result"];
        if (debug) NSLog(@"result is %@",result);
        NSArray *resultWords = [_resultToWords objectForKey:result];
        
        EAFAudioView *exampleView = [[EAFAudioView alloc] init];
        
        exampleView.translatesAutoresizingMaskIntoConstraints = NO;
        [cell.contentView addSubview:exampleView];
        //    [scrollView addSubview:exampleView];
        
        exampleView.refAudio = [_resultToRef    objectForKey:result];
        exampleView.answer   = [_resultToAnswer objectForKey:result];
        
        //NSLog(@"ref %@ %@",exampleView.refAudio, exampleView.answer);
        //   NSLog(@"word is %@",wordEntry);
        // first example view constraints left side to left side of container
        // all - top to top of container
        // bottom to bottom of container
        // after first, left side is right side of previous container, with margin
        
        // upper part is word, lower is phones
        // upper has left, right top bound to container
        // upper bottom is half container height
        
        // lower has left, right bottom bound to container
        // lower has top that is equal to bottom of top or half container height
        
        // top
        
        [cell.contentView addConstraint:[NSLayoutConstraint
                                         constraintWithItem:exampleView //scrollView
                                         attribute:NSLayoutAttributeTop
                                         relatedBy:NSLayoutRelationEqual
                                         toItem:cell.contentView
                                         attribute:NSLayoutAttributeTop
                                         multiplier:1.0
                                         constant:0.0]];
        
        // bottom
        
        [cell.contentView addConstraint:[NSLayoutConstraint
                                         constraintWithItem:exampleView//scrollView
                                         attribute:NSLayoutAttributeBottom
                                         relatedBy:NSLayoutRelationEqual
                                         toItem:cell.contentView
                                         attribute:NSLayoutAttributeBottom
                                         multiplier:1.0
                                         constant:0.0]];
        
        if (leftView == nil) {
            // left
            NSLayoutConstraint *constraint = [NSLayoutConstraint
                                              constraintWithItem:exampleView
                                              attribute:NSLayoutAttributeLeft
                                              relatedBy:NSLayoutRelationEqual
                                              toItem:overallPhoneLabel//scrollView
                                              attribute:NSLayoutAttributeRight
                                              multiplier:1.0
                                              constant:3.0];
            
            [cell.contentView addConstraint:constraint];
            //    NSLog(@"adding (no left view) constraint %@",constraint);
        }
        else {
            NSLayoutConstraint *constraint = [NSLayoutConstraint
                                              constraintWithItem:exampleView
                                              attribute:NSLayoutAttributeLeft
                                              relatedBy:NSLayoutRelationEqual
                                              toItem:leftView
                                              attribute:NSLayoutAttributeRight
                                              multiplier:1.0
                                              constant:5.0];
            
            [cell.contentView addConstraint:constraint];
            //  NSLog(@"adding (to left view) constraint %@",constraint);
        }
        
        leftView = exampleView;
        
        for (NSDictionary *wordResult in resultWords) {
            if (debug)  NSLog(@"resultWords : wordEntry is %@",wordEntry);
            
            BOOL isMatch;
            if ([[wordEntry objectForKey:@"wid"] isKindOfClass:[NSNumber class]]) {
                NSNumber *wordPhoneAppearsInID = [wordEntry objectForKey:@"wid"];
                NSNumber *idOfWordInResult = [wordResult objectForKey:@"id"];
                
                isMatch = [wordPhoneAppearsInID isEqualToNumber:idOfWordInResult];
            }
            else {
                NSString *wordPhoneAppearsIn = [wordEntry objectForKey:@"wid"];
                if (debug)  NSLog(@"resultWords : wordPhoneAppearsIn is %@",wordPhoneAppearsIn);
                int iwid= [wordPhoneAppearsIn intValue];
                
                int idOfWordInResult = [[wordResult objectForKey:@"id"] intValue];
                
                isMatch = iwid == idOfWordInResult;
            }
            
            if (debug)  NSLog(@"resultWords : wordResult         is %@",wordResult);
            
            float fscore = [[wordResult objectForKey:@"s"] floatValue];
            
            //            if ([[wordResult objectForKey:@"s"] isKindOfClass:[NSString class]]) {
            //                NSString *scoreString  = [wordResult objectForKey:@"s"];
            //            }
            //            else {
            //                NSNumber *scoreString  = [wordResult objectForKey:@"s"];
            //                fscore = [scoreString floatValue];
            //            }
            
            UILabel * wordLabel = [self getLabelForWord:fscore word:word];
            
            [exampleView addSubview:wordLabel];
            [self addWordLabelConstraints:exampleView wordLabel:wordLabel];
           
            if (isMatch) {  // match!
                NSArray *phoneArray = [wordResult objectForKey:@"phones"];
                
                if (_isRTL && !_showPhonesLTRAlways) {
                    phoneArray = [self reversedArray:phoneArray];
                }
                NSDictionary *lastPhone = phoneArray.count > 0 ? [phoneArray objectAtIndex:phoneArray.count-1] : nil;
                NSString *phoneToShow = [self getPhonesToShow:lastPhone addSpaces:addSpaces phoneArray:phoneArray];
                
                NSMutableAttributedString *coloredPhones = [[NSMutableAttributedString alloc] initWithString:phoneToShow];
                
                int start = 0;
                for (NSDictionary *phoneInfo in phoneArray) {
                    NSString *phoneText =[phoneInfo objectForKey:@"p"];
                    
                    NSRange range = NSMakeRange(start, [phoneText length]);
                    
                    if ([_language isEqualToString:@"Korean"] || !addSpaces)
                    {
                        start += range.length;
                    }
                    else {
                        
                        start += (phoneInfo != lastPhone) ? range.length+1 : range.length;
                    }
                    
                    NSString *scoreString = [phoneInfo objectForKey:@"s"];
                    float score = [scoreString floatValue];
                    
                    if (debug)   NSLog(@"score was %@ %f",scoreString,score);
                    if (debug)   NSLog(@"%@ vs %@ ",phoneText,phone);
                    BOOL match = [phoneText isEqualToString:phone];
                    
                    UIColor *color = match? [self getColor2:score] : [UIColor whiteColor];
                    if (match) {
                        totalPhoneScore += score;
                        totalPhones++;
                    }
                    if (debug)   NSLog(@"%@ %f %@ range at %lu length %lu", phoneText, score,color,(unsigned long)range.location,(unsigned long)range.length);
                    [coloredPhones addAttribute:NSBackgroundColorAttributeName
                                          value:color
                                          range:range];
                }
                
                
                UILabel *phoneLabel = [[UILabel alloc] init];
                phoneLabel.attributedText = coloredPhones;
                [exampleView addSubview:phoneLabel];
                [self addPhoneLabelConstrains:phoneLabel exampleView:exampleView];
            }
        }
        // add a boundary marker
        
        CALayer *rightBorder = [CALayer layer];
        rightBorder.borderColor = [UIColor colorWithWhite:0.8f
                                                    alpha:1.0f].CGColor;
        rightBorder.borderWidth = 1;
        rightBorder.frame = CGRectMake(-3, -4, 2, _rowHeight);//exampleView.layer.bounds.size.height);
        
        [exampleView.layer addSublayer:rightBorder];
        
        exampleView.userInteractionEnabled = YES;
    }
    //
    //    [cell.contentView addConstraint:[NSLayoutConstraint
    //                                     constraintWithItem:scrollView
    //                                     attribute:NSLayoutAttributeRight
    //                                     relatedBy:NSLayoutRelationEqual
    //                                     toItem:leftView
    //                                     attribute:NSLayoutAttributeRight
    //                                     multiplier:1.0
    //                                     constant:0.0]];
    
    NSMutableAttributedString *coloredWord = [[NSMutableAttributedString alloc] initWithString:overallPhoneLabel.text];
    
    NSRange range = NSMakeRange(0, [coloredWord length]);
    
    float overallAvg = totalPhoneScore/totalPhones;
    //   NSLog(@"%@ score was %f = %f/%f",phone,overallAvg,totalPhoneScore,totalPhones);
    if (overallAvg > -0.1) {
        UIColor *color = [self getColor2:overallAvg];
        [coloredWord addAttribute:NSBackgroundColorAttributeName
                            value:color
                            range:range];
    }
    
    overallPhoneLabel.attributedText = coloredWord;
    return cell;
}

- (NSArray *)reversedArray:(NSArray *) toReverse {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[toReverse count]];
    NSEnumerator *enumerator = [toReverse reverseObjectEnumerator];
    for (id element in enumerator) {
        [array addObject:element];
    }
    return array;
}

- (IBAction)gotTapGesture:(UITapGestureRecognizer *) sender {
    CGPoint p = [sender locationInView:self.tableView];
    //  NSLog(@"Got point %f %f",p.x,p.y);
    
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
    //  NSLog(@"Got path %@",indexPath);
    
    if (indexPath == nil) {
        NSLog(@"press on table view but not on a row");
    } else {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        //      CGPoint p = [sender locationInView:cell.contentView];
        //  NSLog(@"Got point in cell content view %f %f",p.x,p.y);
        
        for (UIView *subview in [cell.contentView subviews]) {
            CGPoint loc = [sender locationInView:subview];
            //        NSLog(@"Loc in %@ is %f %f",subview,loc.x,loc.y);
            
            if(CGRectContainsPoint(subview.bounds, loc))
            {
                //     NSLog(@"-XXXX-----> In View for %@",subview);
                if ([subview isKindOfClass:[EAFAudioView class]]) {
                    [_myAudioPlayer stopAudio];
                    
                    [self setTextColor:[UIColor blackColor]];
                    _currentAudioSelection = (EAFAudioView *)subview;
                    [self playRefAudio:_currentAudioSelection];
                }
                else if ([subview isKindOfClass:[UILabel class]]) {
                    [_myAudioPlayer stopAudio];
                    
                    for (UIView *sibling in subview.superview.subviews) {
                        if ([sibling isKindOfClass:[EAFAudioView class]]) {
                            
                            [self setTextColor:[UIColor blackColor]];
                            _currentAudioSelection = (EAFAudioView *)sibling;
                            [self playRefAudio:_currentAudioSelection];
                            break;
                        }
                    }
                    
                }
            }
        }
    }
}

// look for local file with mp3 and use it if it's there.
- (IBAction)playRefAudio:(EAFAudioView *)sender {
//    NSLog(@"playRefAudio playing audio...");
    
    NSMutableArray *audioRefs = [[NSMutableArray alloc] init];
    
    if (sender.refAudio == nil) {
        NSLog(@"ERROR - ref audio is null on %@",sender);
    }
    else {
        [audioRefs addObject:sender.refAudio];
        EAFEventPoster *poster = [[EAFEventPoster alloc] initWithURL:_url projid:_projid];
  //      NSLog(@"playRefAudio post - projid %@ lang %@",_projid,_language);
        
        [poster postEvent:sender.refAudio exid:@"n/a" widget:@"refAudio" widgetType:@"PhoneScoreTableCell"];
    }
    if (sender.answer == nil) {
        NSLog(@"ERROR - answer audio is null on %@",sender);
    }
    else {
        [audioRefs addObject:sender.answer];
    }
    
    _myAudioPlayer.audioPaths = audioRefs;
    [_myAudioPlayer playRefAudio];
}

- (void) playStarted {
    [self setTextColor:[UIColor npMedPurple]];
}

- (void) playStopped {
    [self setTextColor:[UIColor blackColor]];
}

- (void) playGotToEnd {
    NSLog(@" playGotToEnd");
    [self setTextColor:[UIColor blackColor]];
}

// set the text color of all the labels in the scoreDisplayContainer
- (void)setTextColor:(UIColor *)color {
    for (UIView *subview in [_currentAudioSelection subviews]) {
        if ([subview isKindOfClass:[UILabel class]]) {
            UILabel *asLabel = (UILabel *) subview;
            asLabel.textColor = color;
            //   NSLog(@"initial hit %@ %@",asLabel,asLabel.text);
        }
        else {
            for (UIView *subview2 in [subview subviews]) {
                if ([subview2 isKindOfClass:[UILabel class]]) {
                    UILabel *asLabel = (UILabel *) subview2;
                    asLabel.textColor = color;
                }
            }
        }
    }
}

- (UIColor *) getColor2:(float) score {
    if (score > 1.0) score = 1.0;
    if (score < 0)   score = 0;
    
    float red   = fmaxf(0,(255 - (fmaxf(0, score-0.5)*2*255)));
    float green = fminf(255, score*2*255);
    float blue  = 0;
    
    red   /= 255;
    green /= 255;
    blue  /= 255;
    
    return [UIColor colorWithRed:red green:green blue:blue alpha:1];
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */


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
  //  NSLog(@"PhoneScore: useJsonChapter data json\n%@",json);
    
    NSDictionary *phoneDict = [json objectForKey:@"phones"];
    NSDictionary *resultsDict = [json objectForKey:@"results"];
    _phonesInOrder = [[NSArray alloc] initWithArray:[json objectForKey:@"order"]];
    
    _phoneToWords   = [[NSMutableDictionary alloc] init];
    _resultToRef   = [[NSMutableDictionary alloc] init];
    _resultToAnswer   = [[NSMutableDictionary alloc] init];
    _resultToWords   = [[NSMutableDictionary alloc] init];
    
    for (NSString *phone in phoneDict) {
        NSArray *wordsPhoneAppearsIn = [phoneDict objectForKey:phone];
        [_phoneToWords setValue:wordsPhoneAppearsIn forKey:phone];
    }
    
    NSMutableArray *paths    = [[NSMutableArray alloc] init];
    NSMutableArray *rawPaths = [[NSMutableArray alloc] init];
    
    for (NSString *resultID in resultsDict) {
        if (debug) NSLog(@"PhoneScore: resultID %@",resultID);
        NSDictionary *fields = [resultsDict objectForKey:resultID];
        NSString *ref = [fields objectForKey:@"ref"];
        
        if (debug) NSLog(@"PhoneScore: ref %@",ref);
        
        [_resultToRef setValue:ref forKey:resultID];
        NSString *answer = [fields objectForKey:@"answer"];
       if (debug)  NSLog(@"PhoneScore: answer %@",answer);
        
        [_resultToAnswer setValue:answer forKey:resultID];
        
        NSDictionary *resultDict = [fields objectForKey:@"result"];
       // NSLog(@"PhoneScore: resultDict %@",resultDict);
        
        if ([[resultDict objectForKey:@"words"] isKindOfClass:[NSString class]]) {
            if (debug) NSLog(@"PhoneScore: is a string %@",[resultDict objectForKey:@"words"]);
            
            NSString *theWords = [resultDict objectForKey:@"words"];
            
            if (debug) NSLog(@"PhoneScore: theWords %@",theWords);
            
            if (theWords != nil) {
                [_resultToWords setValue:theWords forKey:resultID];
            }
            else {
                NSLog(@"PhoneScore: no words for %@",answer);
            }
        }
        else if ([[resultDict objectForKey:@"words"] isKindOfClass:[NSArray class]]) {
           // NSLog(@"PhoneScore: is an array %@",[resultDict objectForKey:@"words"]);
            
            NSArray *theWords = [resultDict objectForKey:@"words"];
            
           // NSLog(@"PhoneScore: dict theWords %@",theWords);
            
            if (theWords != nil) {
                //                NSMutableArray *newArray = [NSMutableArray new];
                //                for (NSDictionary *word in theWords) {
                //                    NSLog(@"PhoneScore: word %@",[word objectForKey:@"w"]);
                //                    [newArray addObject:[word objectForKey:@"w"]];
                //                }
                //                NSLog(@"PhoneScore: read all words %@",newArray);
                //
                //                [_resultToWords setValue:newArray forKey:resultID];
                
                [_resultToWords setValue:theWords forKey:resultID];
            }
            else {
                NSLog(@"PhoneScore: no words for %@",answer);
            }
        }
        else {
            NSLog(@"Phonescore can't tell class for words");
        }
        
        if (answer && answer.length > 2) { //i.e. not NO
            NSString * refPath = [answer stringByReplacingOccurrencesOfString:@".wav"
                                                                   withString:@".mp3"];
            
            NSMutableString *mu = [NSMutableString stringWithString:refPath];
            [mu insertString:_url atIndex:0];
            [paths addObject:mu];
            [rawPaths addObject:refPath];
        }
    }
    
    //NSLog(@"getting audio %lul",(unsigned long)paths.count);
    [_audioCache goGetAudio:rawPaths paths:paths language:_language];
    
    UIViewController  *parent = [self parentViewController];
    parent.navigationItem.title = @"Touch to compare audio";
    
    [[self tableView] reloadData];
    
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
    
    NSString *message = error.localizedDescription;
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

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
