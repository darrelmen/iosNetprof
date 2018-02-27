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
//  EAFWordScoreTableViewController
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 7/16/14.
//  Copyright (c) 2011-2016 Massachusetts Institute of Technology, Lincoln Laboratory
//

#import "EAFWordScoreTableViewController.h"
#import "FAImageView.h"
#import "MyTableViewCell.h"
#import "EAFAudioPlayer.h"
#import "EAFAudioCache.h"
#import "EAFEventPoster.h"
#import "SSKeychain.h"
#import "UIColor_netprofColors.h"

@interface EAFWordScoreTableViewController ()
@property int rowHeight;
@property UILabel *current;
@property (strong, nonatomic) NSData *responseData;
@property EAFAudioPlayer *audioPlayer;
@property EAFAudioCache *audioCache;
@property NSDictionary *exToJson;
@property NSArray *scores;

@property NSDictionary *exToScore;
@property NSDictionary *exToHistory;
@property NSDictionary *exToHistoryScores;
@property NSMutableArray *exList;

@end

@implementation EAFWordScoreTableViewController

- (void)cacheAudio:(NSArray *)items
{
    NSMutableArray *paths = [[NSMutableArray alloc] init];
    NSMutableArray *rawPaths = [[NSMutableArray alloc] init];
    
    NSArray *fields = [NSArray arrayWithObjects:@"ref",nil];
    
    for (NSDictionary *object in items) {
        for (NSString *id in fields) {
            NSString *refPath = [object objectForKey:id];
            
            if (refPath && refPath.length > 2) { //i.e. not NO
                //NSLog(@"adding %@ %@",id,refPath);
                refPath = [refPath stringByReplacingOccurrencesOfString:@".wav"
                                                             withString:@".mp3"];
                
                NSMutableString *mu = [NSMutableString stringWithString:refPath];
                [mu insertString:_url atIndex:0];
                [paths addObject:mu];
                [rawPaths addObject:refPath];
            }
        }
    }
    
    NSLog(@"EAFWordScoreTableViewController Got get audio -- %@ ",_audioCache);
    
    [_audioCache goGetAudio:rawPaths paths:paths language:_language];
    
    //NSLog(@"cacheAudio Got get audio -- after ");
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _audioCache = [EAFAudioCache new];
    
    [self performSelectorInBackground:@selector(cacheAudio:) withObject:_jsonItems];
    _rowHeight = 60;
    
    _audioPlayer = [[EAFAudioPlayer alloc] init];
    _audioPlayer.url = _url;
    _audioPlayer.language = _language;
    _audioPlayer.delegate = self;
    
    NSString *userid = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"userid"];
    _user = [userid intValue];
    [self askServerForJson];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    for(UIViewController *tab in self.tabBarController.viewControllers)
    {
        [tab.tabBarItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                [UIFont fontWithName:@"Helvetica" size:16.0], NSFontAttributeName, nil]
                                      forState:UIControlStateNormal];
    }
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_audioPlayer stopAudio];
}

- (void)askServerForJson {
    NSString *baseurl = [NSString stringWithFormat:@"%@scoreServlet?request=chapterHistory&user=%ld&%@=%@&%@=%@", _url, _user, _unitName, _unitSelection, _chapterName, _chapterSelection];
    baseurl =[baseurl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSLog(@"wordScoreTable: askServerForJson url %@ %@",baseurl, _projid);
    
    NSURL *url = [NSURL URLWithString:baseurl];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    
    [urlRequest setHTTPMethod: @"GET"];
    [urlRequest setValue:@"application/x-www-form-urlencoded"
      forHTTPHeaderField:@"Content-Type"];
    
    [urlRequest setValue:[NSString stringWithFormat:@"%@",_projid] forHTTPHeaderField:@"projid"];
    
    [urlRequest setTimeoutInterval:10];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:true];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         dispatch_async(dispatch_get_main_queue(), ^{
             [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];
         });
         
         if (error != nil) {
             NSLog(@" : Got error %@",error);
             [self performSelectorOnMainThread:@selector(reportError:)
                                    withObject:error
                                 waitUntilDone:NO];
         }
         else {
             _responseData = data;
             [self performSelectorOnMainThread:@selector(connectionDidFinishLoading:)
                                    withObject:nil
                                 waitUntilDone:NO];
         }
     }];
}

#pragma mark - Table view data source

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row%2 == 0) {
        UIColor *altCellColor = [UIColor colorWithWhite:0.7 alpha:0.1];
        cell.backgroundColor = altCellColor;
    }
    else {
        UIColor *altCellColor = [UIColor colorWithWhite:1.0 alpha:0.1];
        cell.backgroundColor = altCellColor;
    }
}

- (CGFloat)tableView:(UITableView *)tableView
estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return _rowHeight;
}

- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return _rowHeight;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return _exToScore.count;
}

- (void)colorWholeString:(NSMutableAttributedString *)result scoreString:(NSString *)scoreString
{
    NSRange range = NSMakeRange(0, [result length]);
    float score = [scoreString floatValue]/100.0f;
    if (score > 0) {
        UIColor *color = [self getColor2:score];
        [result addAttribute:NSBackgroundColorAttributeName
                       value:color
                       range:range];
    }
}

- (void)colorEachWord:(NSString *)exid cell:(MyTableViewCell *)cell exercise:(NSString *)exercise scoreHistory:(NSDictionary *)scoreHistory
{
    NSString *scoreString = [_exToScore objectForKey:exid];
    if (scoreString == nil) {
        cell.textLabel.text = exercise;
    }
    else {
        NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:exercise];
        
        // NSLog(@"tableView scoreHistory - json %@",scoreHistory);
        if (scoreHistory == nil || ![scoreHistory isKindOfClass:[NSDictionary class]] || scoreHistory.count == 0) {
            [self colorWholeString:result scoreString:scoreString];
        }
        else {
            NSArray *words = [scoreHistory valueForKey:@"words"];
            // NSLog(@"for words %lu count ",(unsigned long)words.count);
            NSArray *tokens = [self getTokens:exercise];
            
            if (words.count == 1) {
                [self colorWholeString:result scoreString:scoreString];
            }
            else {
                NSUInteger endToken = 0;
                int i = 0;
                //   NSLog(@"for %@ got tokens %@",exercise,tokens);
                //  NSLog(@"for words %lu count ",(unsigned long)tokens.count);
                BOOL useToken = tokens.count == words.count;
                
                for (NSDictionary *entry in words) {
                    NSString *word   = [entry objectForKey:@"w"];
                    if ([word isEqualToString:@"<s>"] || [word isEqualToString:@"</s>"]) {
                        //  NSLog(@"skipping %@",word);
                        continue;
                    }
                    
                    NSString *wscore = [entry objectForKey:@"s"];
                    float score = [wscore floatValue];
                    
                    NSString *token = useToken ? [tokens objectAtIndex:i++] : word;
                    
                    NSRange trange = [exercise rangeOfString:token options:NSCaseInsensitiveSearch range:NSMakeRange(endToken, exercise.length-endToken)];
                    
                    if (trange.length > 0) {
                        UIColor *color = [self getColor2:score];
                        
                        [result addAttribute:NSBackgroundColorAttributeName
                                       value:color
                                       range:trange];
                        endToken = trange.location+trange.length;
                    }
                    else {
                        NSLog(@"huh? ERROR - can't find %@ in %@",word,exercise);
                    }
                }
            }
        }
        
        cell.fl.attributedText = result;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Configure the cell...
    MyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"WordScoreCell" forIndexPath:indexPath];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(gotTapGesture:)];
    tap.cancelsTouchesInView = YES;
    tap.numberOfTapsRequired = 1;
    [cell addGestureRecognizer:tap];
    
    NSMutableArray *icons = [[NSMutableArray alloc] init];
    [icons addObject:cell.first];
    [icons addObject:cell.second];
    [icons addObject:cell.third];
    [icons addObject:cell.fourth];
    [icons addObject:cell.fifth];
    
    for (UIView *container in icons) {
        for (UIView *v in [container subviews]) {
            [v removeFromSuperview];
        }
    }
    
    NSInteger row = indexPath.row;
    NSString *exid = [_exList objectAtIndex:row];
    NSArray *answers = [_exToHistory objectForKey:exid];
    NSArray *scores = [_exToHistoryScores objectForKey:exid];
    
    
    // NSDictionary *scoreHistory = [_exToJson objectForKey:exid];
    //   NSLog(@"scoreHistory %@ %@",exid,scores);
    //   NSLog(@"ex answers %@ %@",exid,answers);
    
    float iconDim = 22.f;
    if (answers == nil || answers.count == 0) {
        FAImageView *correctView = [[FAImageView alloc] initWithFrame:CGRectMake(0.f, 0.f, iconDim,iconDim)];
        correctView.image = nil;
        [correctView setDefaultIconIdentifier:@"fa-question"];
        [cell.fifth addSubview:correctView];
    }
    else {
        int index = 0;
        for (NSString *correct in answers) {
            NSNumber *score   = [scores objectAtIndex:index];
            UIView *container = [icons objectAtIndex:(index++ + (5-[answers count]))];
            
            FAImageView *correctView = [[FAImageView alloc] initWithFrame:CGRectMake(0.f, 0.f, iconDim, iconDim)];
            correctView.image = nil;
            
            // NSLog(@"Score is %@",score);
            BOOL isCorrect = [correct isEqualToString:@"Y"];
            [correctView setDefaultIconIdentifier:isCorrect ? @"fa-check" : @"fa-times"];
            
            UIColor *scoreColor = [self getColor2:score.floatValue];
            correctView.defaultView.backgroundColor = scoreColor;
            
            [container addSubview:correctView];
        }
    }
    
    NSString *fl = [_exToFL objectForKey:exid];
    if (fl == nil) {
        NSLog(@"arg -- error! no fl for %@",exid);
        cell.fl.text = @"";
    }
    else {
        NSDictionary *scoreHistory = [_exToJson objectForKey:exid];
        [self colorEachWord:exid cell:cell exercise:fl scoreHistory:scoreHistory];
     //    cell.fl.font=[UIFont systemFontOfSize:12.0];
        cell.english.text = [_exToEnglish objectForKey:exid];
        
      //  cell.english.font=[UIFont systemFontOfSize:12.0];
    }
    return cell;
}

-(NSArray *)getTokens:(NSString *)sentence {
    NSMutableArray * all = [[NSMutableArray alloc] init];
    NSError *error = nil;
    NSString *regexPattern = @"[\\?\\.,-\\/#!$%\\^&\\*;:{}=\\-_`~()]";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexPattern options:NSRegularExpressionCaseInsensitive error:&error];
    sentence = [regex stringByReplacingMatchesInString:sentence options:0 range:NSMakeRange(0, [sentence length]) withTemplate:@" "];
    
    for (NSString *untrimedToken in [sentence componentsSeparatedByString:@" "]) { // split on spaces
        NSString *token = [untrimedToken stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if (token.length > 0) {
            [all addObject:token];
        }
    }
    // NSLog(@"tokens %@", all);
    
    return all;
}

- (UIColor *) getColor2:(float) score {
    if (score > 1.0) score = 1.0;
    if (score < 0)  score = 0;
    
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

- (void)setTitleGivenCorrect:(NSString *)incorrect correct:(NSString *)correct {
    float total = [correct floatValue] + [incorrect floatValue];
    float percent = total == 0.0f ? 0.0f : [correct floatValue]/total;
    percent *= 100;
    int percentInt = round(percent);
    int totalInt = round(total);
    UIViewController  *parent = [self parentViewController];
    NSString *wordReport;
    wordReport = [NSString stringWithFormat:@"%@ of %d Correct (%d%%)",correct,totalInt,percentInt];
    //   NSLog(@"setting correct title %@",wordReport);
    parent.navigationItem.title = wordReport;
    myCurrentTitle = wordReport;
}

- (void)useJsonChapterData {
    NSError * error;
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:_responseData
                          options:NSJSONReadingAllowFragments
                          error:&error];
    
    if (error) {
        NSLog(@"useJsonChapterData error %@",error.description);
    }
    else {
        NSArray *jsonArray = [json objectForKey:@"scores"];
        //  NSLog(@"json for scores was %@",jsonArray);
        
        unsigned long indexOfFirst = 0;
        BOOL isEmpty = true;
        if (jsonArray != nil) {
            _exToScore   = [[NSMutableDictionary alloc] init];
            _exToHistory = [[NSMutableDictionary alloc] init];
            _exToHistoryScores = [[NSMutableDictionary alloc] init];
            _exList      = [[NSMutableArray alloc] init];
            _exToJson    = [[NSMutableDictionary alloc] init];
            
            for (NSDictionary *entry in jsonArray) {
                NSString *ex = [entry objectForKey:@"ex"];
                if ([_exToFL objectForKey:ex] != nil) {
                    //   NSLog(@"ex key %@",ex);
                    NSString *score = [entry objectForKey:@"s"];
                    
                    //   NSLog(@"score  %@",score);
                    [_exToScore setValue:score forKey:ex];
                    
                    NSArray *jsonArrayHistory = [entry objectForKey:@"h"];
                    if (jsonArrayHistory.count > 0 && isEmpty) {
                        indexOfFirst = _exToHistory.count;
                        isEmpty = false;
                    }
                    [_exToHistory setValue:jsonArrayHistory forKey:ex];
                    [_exToHistoryScores setValue:[entry objectForKey:@"scores"] forKey:ex];
                    [_exList addObject:ex];
                    [_exToJson    setValue:[entry objectForKey:@"scoreJson"] forKey:ex];
                }
            }
            NSString *correct   = [json objectForKey:@"lastCorrect"];
            NSString *incorrect = [json objectForKey:@"lastIncorrect"];
            [self setTitleGivenCorrect:incorrect correct:correct];
        }
        else {
            UIViewController  *parent = [self parentViewController];
            NSString *wordReport = @"0 of 0 Correct (0%)";
            parent.navigationItem.title = wordReport;
            myCurrentTitle = wordReport;
        }
        
        [[self tableView] reloadData];
        
        // scroll to first item with history
        if (!isEmpty) {
            NSIndexPath *scrollIndexPath = [NSIndexPath indexPathForRow:indexOfFirst inSection:0];
            [[self tableView] scrollToRowAtIndexPath:scrollIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        }
    }
}

NSString *myCurrentTitle;

-(void)setCurrentTitle {
    UIViewController  *parent = [self parentViewController];
    parent.navigationItem.title = myCurrentTitle;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // The request is complete and data has been received
    
    //[loadingContentAlert dismissWithClickedButtonIndex:0 animated:true];
    [self useJsonChapterData];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];
}

- (void)reportError:(NSError *)error {
    //  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];
    
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

- (IBAction)gotTapGesture:(UITapGestureRecognizer *) sender {
    //  CGPoint p = [sender locationInView:sender.view];
    //  NSLog(@"Got point %f %f",p.x,p.y);
    
    CGPoint p = [sender locationInView:self.tableView];
    //NSLog(@"gotTapGesture Got point %f %f",p.x,p.y);
    
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
    //NSLog(@"gotTapGesture Got path %@",indexPath);
    
    NSInteger row = indexPath.row;
    NSString *exid = [_exList objectAtIndex:row];
    
    if ([exid isKindOfClass:[NSNumber class]]) {
        NSNumber *nid = [_exList objectAtIndex:row];
        exid = [NSString stringWithFormat:@"%@",nid];
        NSLog(@"gotTapGesture got at row %ld, object id %@ = %@", (long)row, nid, exid);
    }
    
    //    EAFEventPoster *poster = [[EAFEventPoster alloc] initWithURL:_url];
    //    [poster postEvent:@"tapOnItem" exid:exid widget:@"WordScoreTableCell" widgetType:@"Table"];
    //   NSLog(@"exid selection %@",exid);
    
    //NSLog(@"gotTapGesture examining %ld items",[_jsonItems count]);

    for (NSDictionary *jsonObject in _jsonItems) {
        //     NSLog(@"comparing to %@",[jsonObject objectForKey:@"id"]);
        NSString *id =  [jsonObject objectForKey:@"id"];
        
        if ([id isKindOfClass:[NSNumber class]]) {  // deal with netprof v2 ids
            NSNumber *nid = [jsonObject objectForKey:@"id"];
            id = [NSString stringWithFormat:@"%@",nid];
            //NSLog(@"gotTapGesture got number on item %@ = %@",nid,id);
        }
        
        if ([id isEqualToString:exid]) {
            NSLog(@"gotTapGesture got match %@ = %@",id,exid);
           // NSLog(@"gotTapGesture got it %@",jsonObject);
            // NSString *refAudio = [jsonObject objectForKey:@"ref"];
            NSMutableArray *toPlay = [[NSMutableArray alloc] init];
            NSString *refAudioPath = [jsonObject objectForKey:@"ref"];
            if (refAudioPath == nil) {
                NSLog(@"gotTapGesture ERROR : no ref audio in %@",jsonObject);
            }
            else {
                [toPlay addObject:refAudioPath];
                NSString *fl = [_exToFL objectForKey:exid];
                
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                
                for (UIView *subview in [cell.contentView subviews]) {
                    // NSLog(@"subview %@",subview);
                    if ([subview isKindOfClass:[UILabel class]]) {
                        //   NSLog(@"found label %@, %@", subview, ((UILabel *) subview).text);
                        if ([ fl isEqualToString:((UILabel *) subview).text]) {
                            if (_current) {
                                _current.textColor = [UIColor blackColor];
                            }
                            _current = ((UILabel *) subview);
                            _current.textColor = [UIColor npMedPurple];
                        }
                    }
                }
                
                _audioPlayer.audioPaths = toPlay;
                [_audioPlayer playRefAudio];
            }
            break;
        }
    }
    
}

- (void) playStarted {
    //    NSLog(@"got play started...");
}

- (void) playStopped {
    //    NSLog(@"got play stopped...");
    _current.textColor = [UIColor blackColor];
}

- (void) playGotToEnd {
    //    NSLog(@"got to end...");
    _current.textColor = [UIColor blackColor];
}

#pragma mark - Table view delegate

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
