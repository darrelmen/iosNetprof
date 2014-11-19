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
#import <AudioToolbox/AudioServices.h>
#import "FAImageView.h"
#import "SSKeychain.h"

@interface EAFPhoneScoreTableViewController ()

@end

@implementation EAFPhoneScoreTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    NSString *userid = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"userid"];
    _user = [userid intValue];
    playingIcon = [[FAImageView alloc] initWithFrame:CGRectMake(0.f, 0.f, 22.f, 22.f)];
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

- (BOOL) cancelTouchesInView {
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)askServerForJson {
    // NSString *baseurl = [NSString stringWithFormat:@"https://np.ll.mit.edu/npfClassroom%@/scoreServlet?request=phoneReport&user=%ld&%@=%@&%@=%@", _language, _user, _unitName, _unitSelection, _chapterName, _chapterSelection];
    NSString *baseurl = [NSString stringWithFormat:@"https://np.ll.mit.edu/npfClassroom%@/scoreServlet?request=phoneReport&user=%ld&%@=%@", _language, _user, _chapterName, _chapterSelection];
    
    NSLog(@"EAFPhoneScoreTableViewController url %@",baseurl);
    
    NSURL *url = [NSURL URLWithString:baseurl];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    [urlRequest setCachePolicy:NSURLRequestReturnCacheDataElseLoad];
    
    [urlRequest setHTTPMethod: @"GET"];
    [urlRequest setValue:@"application/x-www-form-urlencoded"
      forHTTPHeaderField:@"Content-Type"];
    
    NSURLConnection *connection = [NSURLConnection connectionWithRequest:urlRequest delegate:self];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:true];
    
    [connection start];
}

#pragma mark - Table view data source

//- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
//    if (indexPath.row%2 == 0) {
//        UIColor *altCellColor = [UIColor colorWithWhite:0.7 alpha:0.1];
//        cell.backgroundColor = altCellColor;
//    }
//    else {
//        UIColor *altCellColor = [UIColor colorWithWhite:1.0 alpha:0.1];
//        cell.backgroundColor = altCellColor;
//    }
//}

- (CGFloat)tableView:(UITableView *)tableView
estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Configure the cell...
    //  MyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"WordScoreCell" forIndexPath:indexPath];
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
    
    NSArray *words = [_phoneToWords objectForKey:phone];
    //BOOL first = true;
    
    UIView *leftView = nil;
    
    int count = 0;
    for (NSDictionary *wordEntry in words) {
        // TODO iterate over first N words in example words for phone
        if (count++ > 5) break; // only first five?
        NSString *result = [wordEntry objectForKey:@"result"];
        NSArray *resultWords = [_resultToWords objectForKey:result];
        
        
        // UIView *exampleView = [[UIView alloc] init];
        EAFAudioView *exampleView = [[EAFAudioView alloc] init];
        exampleView.translatesAutoresizingMaskIntoConstraints = NO;
        [cell.contentView addSubview:exampleView];
        
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
                                         constraintWithItem:exampleView
                                         attribute:NSLayoutAttributeTop
                                         relatedBy:NSLayoutRelationEqual
                                         toItem:cell.contentView
                                         attribute:NSLayoutAttributeTop
                                         multiplier:1.0
                                         constant:0.0]];
        
        // bottom
        
        [cell.contentView addConstraint:[NSLayoutConstraint
                                         constraintWithItem:exampleView
                                         attribute:NSLayoutAttributeBottom
                                         relatedBy:NSLayoutRelationEqual
                                         toItem:cell.contentView
                                         attribute:NSLayoutAttributeBottom
                                         multiplier:1.0
                                         constant:0.0]];
        
        if (leftView == nil) {
            [cell.contentView addConstraint:[NSLayoutConstraint
                                             constraintWithItem:exampleView
                                             attribute:NSLayoutAttributeLeft
                                             relatedBy:NSLayoutRelationEqual
                                             toItem:cell.contentView
                                             attribute:NSLayoutAttributeLeft
                                             multiplier:1.0
                                             constant:3.0]];
        }
        else {
            [cell.contentView addConstraint:[NSLayoutConstraint
                                             constraintWithItem:exampleView
                                             attribute:NSLayoutAttributeLeft
                                             relatedBy:NSLayoutRelationEqual
                                             toItem:leftView
                                             attribute:NSLayoutAttributeRight
                                             multiplier:1.0
                                             constant:5.0]];
        }
        
        leftView = exampleView;
        
        NSString *word = [wordEntry objectForKey:@"w"];
        for (NSDictionary *wordResult in resultWords) {
            NSString *wordPhoneAppearsIn = [wordEntry objectForKey:@"wid"];
            NSString *wordInResult = [wordResult objectForKey:@"id"];
            UILabel *wordLabel = [[UILabel alloc] init];
            
            if ([_language isEqualToString:@"English"]) {
                word = [word lowercaseString];
            }
            
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
            //   NSLog(@"label word is %@",wordLabel.attributedText);
            
            //[wordLabel setTextColor:[UIColor blackColor]];
            //  [wordLabel setBackgroundColor:[UIColor colorWithHue:32 saturation:100 brightness:63 alpha:1]];
            [wordLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:18.0f]];
            [wordLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
            
            
            [exampleView addSubview:wordLabel];
            
            [exampleView addConstraint:[NSLayoutConstraint
                                        constraintWithItem:wordLabel
                                        attribute:NSLayoutAttributeTop
                                        relatedBy:NSLayoutRelationEqual
                                        toItem:exampleView
                                        attribute:NSLayoutAttributeTop
                                        multiplier:1.0
                                        constant:0.0]];
            
            [exampleView addConstraint:[NSLayoutConstraint
                                        constraintWithItem:wordLabel
                                        attribute:NSLayoutAttributeLeft
                                        relatedBy:NSLayoutRelationEqual
                                        toItem:exampleView
                                        attribute:NSLayoutAttributeLeft
                                        multiplier:1.0
                                        constant:0.0]];
            
            [exampleView addConstraint:[NSLayoutConstraint
                                        constraintWithItem:wordLabel
                                        attribute:NSLayoutAttributeRight
                                        relatedBy:NSLayoutRelationEqual
                                        toItem:exampleView
                                        attribute:NSLayoutAttributeRight
                                        multiplier:1.0
                                        constant:0.0]];
            
            [exampleView addConstraint:[NSLayoutConstraint
                                        constraintWithItem:wordLabel
                                        attribute:NSLayoutAttributeHeight
                                        relatedBy:NSLayoutRelationEqual
                                        toItem:exampleView
                                        attribute:NSLayoutAttributeHeight
                                        multiplier:0.5
                                        constant:0.0]];
            
            if ([wordInResult isEqualToString:wordPhoneAppearsIn]) {
                
                NSString *phoneToShow = @"";
                
                for (NSDictionary *phoneInfo in [wordResult objectForKey:@"phones"]) {
                    NSString *phoneText =[phoneInfo objectForKey:@"p"];
                    phoneToShow = [phoneToShow stringByAppendingString:phoneText];
                    phoneToShow = [phoneToShow stringByAppendingString:@" "];
                }
                
                NSMutableAttributedString *coloredPhones = [[NSMutableAttributedString alloc] initWithString:phoneToShow];
                
                int start = 0;
                for (NSDictionary *phoneInfo in [wordResult objectForKey:@"phones"]) {
                    NSString *phoneText =[phoneInfo objectForKey:@"p"];
                    //phoneToShow = [phoneToShow stringByAppendingString:phoneText];
                    //phoneToShow = [phoneToShow stringByAppendingString:@" "];
                    
                    NSRange range = NSMakeRange(start, [phoneText length]);
                    start += range.length+1;//1 + [phoneText length];
                    NSString *scoreString = [phoneInfo objectForKey:@"s"];
                    float score = [scoreString floatValue];
                    
                    // NSLog(@"score was %@ %f",scoreString,score);
                    //if (score > 0) {
                    // NSLog(@"%@ vs %@ ",phoneText,phone);
                    BOOL match = [phoneText isEqualToString:phone];
                    //if ( || true) {
                    UIColor *color = match? [self getColor2:score] : [UIColor whiteColor];
                    //   NSLog(@"%@ %f %@ range at %lu length %lu", phoneText, score,color,(unsigned long)range.location,(unsigned long)range.length);
                    [coloredPhones addAttribute:NSBackgroundColorAttributeName
                                          value:color
                                          range:range];
                    // }
                    //}
                    
                }
                
                
                UILabel *phoneLabel = [[UILabel alloc] init];
                phoneLabel.attributedText = coloredPhones;
                
                //      [phoneLabel setTextColor:[UIColor blackColor]];
                //[phoneLabel setBackgroundColor:[UIColor colorWithHue:66 saturation:100 brightness:63 alpha:1]];
                [phoneLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:18.0f]];
                [phoneLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
                
                [exampleView addSubview:phoneLabel];
                
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
        }
        //        exampleView.clipsToBounds = YES;
        
        // add a boundary marker
        
        CALayer *rightBorder = [CALayer layer];
        rightBorder.borderColor = [UIColor colorWithWhite:0.8f
                                                    alpha:1.0f].CGColor;
        rightBorder.borderWidth = 1;
        rightBorder.frame = CGRectMake(-3, -1, 2, 44);
        
        [exampleView.layer addSublayer:rightBorder];
        
        //  [exampleView addTarget:self action:@selector(playAudioClick:) forControlEvents:UIControlEventTouchUpInside];
        
        exampleView.userInteractionEnabled = YES;
        
        //        UITapGestureRecognizer *singleFingerTap =
        //        [[UITapGestureRecognizer alloc] initWithTarget:self
        //                                                action:@selector(playAudioClick:)];
        //        singleFingerTap.delegate = self;
        //        [exampleView addGestureRecognizer:singleFingerTap];
        
        //        NSLog(@"add gesture %@ (%lu) to %@",singleFingerTap,
        //              (unsigned long)exampleView.gestureRecognizers.count,exampleView);
        //
        //
        
        // click goes to example view
        //        singleFingerTap =
        //        [[UITapGestureRecognizer alloc] initWithTarget:exampleView
        //                                                action:@selector(gotClick:)];
        //        singleFingerTap.delegate = self;
        //
        //        [exampleView addGestureRecognizer:singleFingerTap];
        
    }
    
    return cell;
}

- (IBAction)gotTapGesture:(UITapGestureRecognizer *) sender {
    ///  NSLog(@"gotTapGesture %@",sender);
    
    CGPoint p = [sender locationInView:sender.view];
    //  NSLog(@"Got point %f %f",p.x,p.y);
    
    p = [sender locationInView:self.tableView];
    //  NSLog(@"Got point %f %f",p.x,p.y);
    
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
    //  NSLog(@"Got path %@",indexPath);
    
    if (indexPath == nil) {
        NSLog(@"press on table view but not on a row");
    } else {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        //if (cell.isHighlighted) {
        //    NSLog(@" press on table view at section %ld row %ld", (long)indexPath.section, (long)indexPath.row);
        //}
        p = [sender locationInView:cell.contentView];
        //  NSLog(@"Got point in cell content view %f %f",p.x,p.y);
        
        for (UIView *subview in [cell.contentView subviews]) {
            CGPoint loc = [sender locationInView:subview];
            
            //        NSLog(@"Loc in %@ is %f %f",subview,loc.x,loc.y);
            
            if(CGRectContainsPoint(subview.frame, loc))
            {
                NSLog(@"--------> In View for %@",subview);
                //return myView;
            }
            
            if(CGRectContainsPoint(subview.bounds, loc))
            {
                NSLog(@"-XXXX-----> In View for %@",subview);
                
                playingRef = TRUE;
                currentAudioSelection = (EAFAudioView *)subview;
//                [currentAudioSelection addSubview:playingIcon];
                [self playRefAudio:(EAFAudioView *)subview];
            }
        }
    }
}

FAImageView *playingIcon;
EAFAudioView * currentAudioSelection;
bool playingRef = TRUE;

// look for local file with mp3 and use it if it's there.
- (IBAction)playRefAudio:(EAFAudioView *)sender {
   // NSLog(@"playRefAudio %@",sender);
    
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

        refAudioPath = @"NO";
        rawRefAudioPath = @"NO";
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
    //NSLog(@" remove observer");
    
    @try {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:[_player currentItem]];
        [_player removeObserver:self forKeyPath:@"status"];
    }
    @catch (NSException *exception) {
        // NSLog(@"initial create - got exception %@",exception.description);
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
    [_responseData appendData:data];
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
    
    for (NSString *resultID in resultsDict) {
        NSDictionary *fields = [resultsDict objectForKey:resultID];
        [_resultToRef setValue:[fields objectForKey:@"ref"] forKey:resultID];
        [_resultToAnswer setValue:[fields objectForKey:@"answer"] forKey:resultID];
        [_resultToWords setValue:[[fields objectForKey:@"result"] objectForKey:@"words"] forKey:resultID];
    }
    
    NSString *report;
//    NSString *phoneScore = [json objectForKey:@"phoneScore"];
    UIViewController  *parent = [self parentViewController];
  //  report = [NSString stringWithFormat:@"Overall Sound Score is %@",phoneScore];
   // report = [NSString stringWithFormat:@"Score is %@, touch a word to hear yourself",phoneScore];
    report = [NSString stringWithFormat:@"Touch a word to hear yourself"];
    parent.navigationItem.title = report;
    
    [[self tableView] reloadData];
    
    return true;
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
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Connection problem"
                                                    message: @"Couldn't connect to server."
                                                   delegate: nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    //    EAFChapterTableViewController *chapterController = [segue destinationViewController];
    
    //  NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    //  NSString *tappedItem = [languages objectAtIndex:indexPath.row];
    
    //  [chapterController setLanguage:tappedItem];
    //  if ([tappedItem isEqualToString:@"CM"]) {
    //      tappedItem = @"Mandarin";
    //  }
    // [chapterController setTitle:tappedItem];
}


@end
