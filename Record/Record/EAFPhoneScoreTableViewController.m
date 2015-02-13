//
//  EAFLanguageTableViewController.m
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 7/16/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import "EAFPhoneScoreTableViewController.h"
#import "FAImageView.h"
#import "MyTableViewCell.h"
#import "EAFAudioView.h"
#import "EAFAudioCache.h"
#import <AudioToolbox/AudioServices.h>
#import "SSKeychain.h"

@interface EAFPhoneScoreTableViewController ()

@property int rowHeight;
@property BOOL showPhonesLTRAlways;  // constant
@property EAFAudioCache *audioCache;

@end

@implementation EAFPhoneScoreTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _audioCache = [[EAFAudioCache alloc] init];

    _showPhonesLTRAlways = true;

    _rowHeight = 66;
    NSString *userid = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"userid"];
    _user = [userid intValue];
  
    playingIcon = [[FAImageView alloc] initWithFrame:CGRectMake(0.f, 0.f, _rowHeight/2,  _rowHeight/2)];
    playingIcon.image = nil;
    [playingIcon setDefaultIconIdentifier:@"fa-volume-up"];
    playingIcon.defaultView.textColor = [UIColor blueColor];
    
    [self askServerForJson];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    // _tableView.cancelTouchesInView = NO;    
}

- (void)viewWillDisappear:(BOOL)animated {
    [_audioCache cancelAllOperations];
    [super viewWillDisappear:animated];
}

-(void)setCurrentTitle {
    UIViewController  *parent = [self parentViewController];
    parent.navigationItem.title = @"Touch to compare audio";
}

- (BOOL) cancelTouchesInView {
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)askServerForJson {
    NSString *baseurl = [NSString stringWithFormat:@"https://np.ll.mit.edu/npfClassroom%@/scoreServlet?request=phoneReport&user=%ld&%@=%@&%@=%@", _language, _user, _unitName, _unitSelection, _chapterName, _chapterSelection];
    baseurl =[baseurl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

//    NSLog(@"EAFPhoneScoreTableViewController url %@",baseurl);
    
    NSURL *url = [NSURL URLWithString:baseurl];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
   // [urlRequest setCachePolicy:NSURLRequestReturnCacheDataElseLoad];
    
    [urlRequest setHTTPMethod: @"GET"];
    [urlRequest setValue:@"application/x-www-form-urlencoded"
      forHTTPHeaderField:@"Content-Type"];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:true];
    
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         NSLog(@"PhoneScoreTableViewController - Got response %@",error);
         
         if (error != nil) {
             NSLog(@"PhoneScoreTableViewController Got error %@",error);
             //[self connection:nil didFailWithError:error];
             
             dispatch_async(dispatch_get_main_queue(), ^{
                 [self connection:nil didFailWithError:error];
             });
         }
         else {
             _responseData = data;
         //    [self connectionDidFinishLoading:nil];
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
 //   exampleView.backgroundColor = [UIColor purpleColor];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Configure the cell...
    static NSString *CellIdentifier = @"PhoneCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    UIView *bgColorView = [[UIView alloc] init];
    
    [bgColorView setBackgroundColor:[UIColor whiteColor]];
    [cell setSelectedBackgroundView:bgColorView];
    
    NSString *phone = [_phonesInOrder objectAtIndex:indexPath.row];
    
 //   NSLog(@"tableView phone is %@",phone);
    
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
   
    UIView *leftView = nil;
    
    UILabel *overallPhoneLabel = [self getOverallPhoneLabel:phone cell:cell];
    
   // UIScrollView *scrollView = [[UIScrollView alloc] init];
//    UIView *scrollView = [[UIView alloc] init];
//    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
//
//    scrollView.backgroundColor = [UIColor purpleColor];
//    [cell.contentView addSubview:scrollView];
//    
//    // top
//    [cell.contentView addConstraint:[NSLayoutConstraint
//                                     constraintWithItem:scrollView
//                                     attribute:NSLayoutAttributeTop
//                                     relatedBy:NSLayoutRelationEqual
//                                     toItem:cell.contentView
//                                     attribute:NSLayoutAttributeTop
//                                     multiplier:1.0
//                                     constant:0.0]];
//    // bottom
//    [cell.contentView addConstraint:[NSLayoutConstraint
//                                     constraintWithItem:scrollView
//                                     attribute:NSLayoutAttributeBottom
//                                     relatedBy:NSLayoutRelationEqual
//                                     toItem:cell.contentView
//                                     attribute:NSLayoutAttributeBottom
//                                     multiplier:1.0
//                                     constant:0.0]];
//    
//    [cell.contentView addConstraint:[NSLayoutConstraint
//                                     constraintWithItem:scrollView
//                                     attribute:NSLayoutAttributeLeft
//                                     relatedBy:NSLayoutRelationEqual
//                                     toItem:overallPhoneLabel
//                                     attribute:NSLayoutAttributeRight
//                                     multiplier:1.0
//                                     constant:3.0]];
//    
//    [cell.contentView addConstraint:[NSLayoutConstraint
//                                     constraintWithItem:scrollView
//                                     attribute:NSLayoutAttributeRight
//                                     relatedBy:NSLayoutRelationEqual
//                                     toItem:cell.contentView
//                                     attribute:NSLayoutAttributeRight
//                                     multiplier:1.0
//                                     constant:0.0]];
//    [scrollView setTranslatesAutoresizingMaskIntoConstraints:NO];

    NSArray *rtl = [NSArray arrayWithObjects: @"Dari",
                    @"Egyptian",
                    @"Farsi",
                    @"Levantine",
                    @"MSA", @"Pashto1", @"Pashto2", @"Pashto3",  @"Sudanese",  @"Urdu",  nil];
    
    float totalPhoneScore = 0.0f;
    float totalPhones = 0.0f;
   // int count = 0;
    BOOL addSpaces = true;

    // try to worry about the same word appearing multiple times...
    NSMutableSet *shownSoFar = [[NSMutableSet alloc] init];
    for (NSDictionary *wordEntry in words) {
        // TODO iterate over first N words in example words for phone
        NSString *word = [wordEntry objectForKey:@"w"];
        
        if ([shownSoFar containsObject:word]) continue;
        else [shownSoFar addObject:word];
        
    //    if (count++ > 5) break; // only first five?
        NSString *result = [wordEntry objectForKey:@"result"];
        NSArray *resultWords = [_resultToWords objectForKey:result];
        
        EAFAudioView *exampleView = [[EAFAudioView alloc] init];
        
        exampleView.translatesAutoresizingMaskIntoConstraints = NO;
        [cell.contentView addSubview:exampleView];
        //    [scrollView addSubview:exampleView];
        
        exampleView.refAudio = [_resultToRef objectForKey:result];
        exampleView.answer =[_resultToAnswer objectForKey:result];
        
        //NSLog(@"ref %@ %@",exampleView.refAudio, exampleView.answer);
        // NSLog(@"word is %@",wordEntry);
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
            NSString *wordPhoneAppearsIn = [wordEntry objectForKey:@"wid"];
            NSString *wordInResult = [wordResult objectForKey:@"id"];
            UILabel *wordLabel = [[UILabel alloc] init];
            
            if ([_language isEqualToString:@"English"]) {
                word = [word lowercaseString];
            }
     //       NSLog(@"Word is %@",word);
            NSMutableAttributedString *coloredWord = [[NSMutableAttributedString alloc] initWithString:word];
           
            NSRange range = NSMakeRange(0, [coloredWord length]);
            NSString *scoreString = [wordResult objectForKey:@"s"];
            float score = [scoreString floatValue];
            
           // NSLog(@"score was %@ %f",scoreString,score);
            if (score > 0) {
                UIColor *color = [self getColor2:score];
                [coloredWord addAttribute:NSBackgroundColorAttributeName
                                    value:color
                                    range:range];
            }
            
            wordLabel.attributedText = coloredWord;
            //NSLog(@"label word is %@",wordLabel.attributedText);
            [wordLabel setFont:[UIFont systemFontOfSize:24]];

            [wordLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
            
            [exampleView addSubview:wordLabel];
            
            [self addWordLabelConstraints:exampleView wordLabel:wordLabel];
            
            if ([wordInResult isEqualToString:wordPhoneAppearsIn]) {
                NSArray *phoneArray = [wordResult objectForKey:@"phones"];
                
                BOOL isRTL = [rtl containsObject:_language];
                
                if (isRTL && !_showPhonesLTRAlways) {
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
                    
                    // NSLog(@"score was %@ %f",scoreString,score);
                    // NSLog(@"%@ vs %@ ",phoneText,phone);
                    BOOL match = [phoneText isEqualToString:phone];
                  
                    UIColor *color = match? [self getColor2:score] : [UIColor whiteColor];
                    if (match) {
                        totalPhoneScore += score;
                        totalPhones++;
                    }
                    //   NSLog(@"%@ %f %@ range at %lu length %lu", phoneText, score,color,(unsigned long)range.location,(unsigned long)range.length);
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
    //CGPoint p = [sender locationInView:sender.view];
    //  NSLog(@"Got point %f %f",p.x,p.y);
    
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
                    playingRef = TRUE;
                    currentAudioSelection = (EAFAudioView *)subview;
                    [self playRefAudio:(EAFAudioView *)subview];
                }
                else if ([subview isKindOfClass:[UILabel class]]) {
                    for (UIView *sibling in subview.superview.subviews) {
                        if ([sibling isKindOfClass:[EAFAudioView class]]) {
                            playingRef = TRUE;
                            currentAudioSelection = (EAFAudioView *)sibling;
                            [self playRefAudio:(EAFAudioView *)sibling];
                            break;
                        }
                    }
          
                }
            }
        }
    }
}

FAImageView *playingIcon;
EAFAudioView * currentAudioSelection;
bool playingRef = TRUE;

// look for local file with mp3 and use it if it's there.
- (IBAction)playRefAudio:(EAFAudioView *)sender {
    NSString *refPath = playingRef ? sender.refAudio : sender.answer;
 //   NSLog(@"ref path %@ playing ref %@",refPath, (playingRef ? @"YES":@"NO"));

    NSString *refAudioPath;
    NSString *rawRefAudioPath;
    
    if (refPath) {
      //  NSLog(@"has ref path %@",refPath);
        refPath = [refPath stringByReplacingOccurrencesOfString:@".wav"
                                                     withString:@".mp3"];
        
        NSMutableString *mu = [NSMutableString stringWithString:refPath];
        [mu insertString:_url atIndex:0];
        refAudioPath = mu;
        rawRefAudioPath = refPath;
    }
    else {
      //  NSLog(@"does not have ref path %@",refPath);

      //  refAudioPath = @"NO";
      //  rawRefAudioPath = @"NO";
        playingRef = FALSE;
        [self playRefAudio:currentAudioSelection];
        return;
    }
    
    NSURL *url = [NSURL URLWithString:refAudioPath];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *audioDir = [NSString stringWithFormat:@"%@_audio",_language];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:audioDir];
    
    NSString *destFileName = [filePath stringByAppendingPathComponent:rawRefAudioPath];
    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:destFileName];
    if (fileExists) {
        //NSLog(@"playRefAudio Raw URL %@", _rawRefAudioPath);
        NSLog(@"using local url %@",destFileName);
        url = [[NSURL alloc] initFileURLWithPath: destFileName];
    }
    else {
        NSLog(@"can't find local url %@",destFileName);
        NSLog(@"playRefAudio URL     %@", url);
    }
    NSString *PlayerStatusContext;
    
    if (_player) {
        [_player pause];
        NSLog(@"removing current observer");
        [self removePlayObserver];
    }
    
    UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
    AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
    AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,sizeof (audioRouteOverride),&audioRouteOverride);
    
    _player = [AVPlayer playerWithURL:url];
    
    [_player addObserver:self forKeyPath:@"status" options:0 context:&PlayerStatusContext];
}

- (void)removePlayingAudioIcon {
    for (UIView *v in [currentAudioSelection subviews]) {
        if (v == playingIcon) {
            [v removeFromSuperview];
        }
    }
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    NSLog(@" playerItemDidReachEnd");
    
    [self removePlayingAudioIcon];
    
    if (playingRef) {
        playingRef = FALSE;
        [self playRefAudio:currentAudioSelection];
    }
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    NSLog(@"Got error %@", error);
    [self removePlayingAudioIcon];
}


// So this is more complicated -- we have to wait until the mp3 has arrived from the server before we can play it
// we remove the observer, or else we will later get a message when the player discarded
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    //NSLog(@" observeValueForKeyPath %@",keyPath);
    
    if (object == _player && [keyPath isEqualToString:@"status"]) {
        if (_player.status == AVPlayerStatusReadyToPlay) {
            NSLog(@" audio ready so playing...");
            [currentAudioSelection addSubview:playingIcon];

            [_player play];
            
            AVPlayerItem *currentItem = [_player currentItem];
            
            [[NSNotificationCenter defaultCenter]
             addObserver:self
             selector:@selector(playerItemDidReachEnd:)
             name:AVPlayerItemDidPlayToEndTimeNotification
             object:currentItem];
            
            @try {
                [_player removeObserver:self forKeyPath:@"status"];
            }
            @catch (NSException *exception) {
                NSLog(@"observeValueForKeyPath : got exception %@",exception.description);
            }
            
        } else if (_player.status == AVPlayerStatusFailed) {
            // something went wrong. player.error should contain some information
            [self removePlayingAudioIcon];

            UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Connection problem" message: @"Couldn't play audio file." delegate: nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            
            //  NSLog(@"player status failed %@",_player.status);
            
            [_player removeObserver:self forKeyPath:@"status"];
        }
    }
    else {
        NSLog(@"ignoring value... %@",keyPath);
    }
}

- (void)removePlayObserver {
    NSLog(@" remove observer");
    
    @try {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:[_player currentItem]];
        [_player removeObserver:self forKeyPath:@"status"];
    }
    @catch (NSException *exception) {
        NSLog(@"initial create - got exception %@",exception.description);
    }
}

- (UIColor *) getColor2:(float) score {
    if (score > 1.0) score = 1.0;
    if (score < 0)  score = 0;
    
    //  NSLog(@"getColor2 score %f",score);
    
    float red   = fmaxf(0,(255 - (fmaxf(0, score-0.5)*2*255)));
    float green = fminf(255, score*2*255);
    float blue  = 0;
    
    red /= 255;
    green /= 255;
    blue /= 255;
    
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

#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // A response has been received, this is where we initialize the instance var you created
    // so that we can append data to it in the didReceiveData method
    // Furthermore, this method is called each time there is a redirect so reinitializing it
    // also serves to clear it
    
    _responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // Append the new data to the instance variable you declared
  //  [_responseData appendData:data];
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
    
    //   NSLog(@"useJsonChapter data ");
    
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
    
    NSMutableArray *paths = [[NSMutableArray alloc] init];
    NSMutableArray *rawPaths = [[NSMutableArray alloc] init];
    
    for (NSString *resultID in resultsDict) {
        NSDictionary *fields = [resultsDict objectForKey:resultID];
        [_resultToRef setValue:[fields objectForKey:@"ref"] forKey:resultID];
        NSString *answer = [fields objectForKey:@"answer"];
        [_resultToAnswer setValue:answer forKey:resultID];
        [_resultToWords setValue:[[fields objectForKey:@"result"] objectForKey:@"words"] forKey:resultID];
        
        
        if (answer && answer.length > 2) { //i.e. not NO
            NSString * refPath = [answer stringByReplacingOccurrencesOfString:@".wav"
                                                                   withString:@".mp3"];
            
            NSMutableString *mu = [NSMutableString stringWithString:refPath];
            [mu insertString:[self getURL] atIndex:0];
            [paths addObject:mu];
            [rawPaths addObject:refPath];
        }
    }
    
    [_audioCache goGetAudio:rawPaths paths:paths language:_language];
    
    UIViewController  *parent = [self parentViewController];
    parent.navigationItem.title = @"Touch to compare audio";

    [[self tableView] reloadData];
    
    return true;
}

- (NSString *)getURL
{
    return [NSString stringWithFormat:@"https://np.ll.mit.edu/npfClassroom%@/", _language];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // The request is complete and data has been received
   
    [self useJsonChapterData];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
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

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
