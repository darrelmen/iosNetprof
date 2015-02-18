//
//  EAFLanguageTableViewController.m
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 7/16/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import "EAFWordScoreTableViewController.h"
#import "FAImageView.h"
#import "MyTableViewCell.h"
#import "EAFAudioPlayer.h"
#import "EAFAudioCache.h"
#import "SSKeychain.h"

@interface EAFWordScoreTableViewController ()
@property int rowHeight;
@property UILabel *current;
@property (strong, nonatomic) NSData *responseData;
@property EAFAudioPlayer *audioPlayer;
@property EAFAudioCache *audioCache;

@end

@implementation EAFWordScoreTableViewController

- (NSString *)getURL
{
    return [NSString stringWithFormat:@"https://np.ll.mit.edu/npfClassroom%@/", _language];
}

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
                [mu insertString:[self getURL] atIndex:0];
                [paths addObject:mu];
                [rawPaths addObject:refPath];
            }
            //else {
            //NSLog(@"skipping %@ %@",id,refPath);
            //}
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
      //  NSLog(@"EAFWordScoreTableViewController got item %@",tab.tabBarItem);        
        [tab.tabBarItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                [UIFont fontWithName:@"Helvetica" size:16.0], NSFontAttributeName, nil]
                                      forState:UIControlStateNormal];
    }
}

//-(void) viewWillAppear:(BOOL)animated {
//    
//}

- (void)askServerForJson {
    NSString *baseurl = [NSString stringWithFormat:@"https://np.ll.mit.edu/npfClassroom%@/scoreServlet?request=chapterHistory&user=%ld&%@=%@&%@=%@", _language, _user, _unitName, _unitSelection, _chapterName, _chapterSelection];
    baseurl =[baseurl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

 //   NSLog(@"askServerForJson url %@",baseurl);
    
    NSURL *url = [NSURL URLWithString:baseurl];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    
    [urlRequest setHTTPMethod: @"GET"];
    [urlRequest setValue:@"application/x-www-form-urlencoded"
      forHTTPHeaderField:@"Content-Type"];
    
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Configure the cell...
    MyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"WordScoreCell" forIndexPath:indexPath];
 
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
    //NSLog(@"ex answers %@ %@",exid,answers);
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
            UIView *container = [icons objectAtIndex:(index++ + (5-[answers count]))];
            
            FAImageView *correctView = [[FAImageView alloc] initWithFrame:CGRectMake(0.f, 0.f, iconDim, iconDim)];
            correctView.image = nil;
            if ([correct isEqualToString:@"Y"]) {
                [correctView setDefaultIconIdentifier:@"fa-check"];
                correctView.defaultIconColor = [UIColor greenColor];
                correctView.defaultView.backgroundColor = [UIColor greenColor];
            }
            else {
                [correctView setDefaultIconIdentifier:@"fa-times"];
                correctView.defaultIconColor = [UIColor redColor];
                correctView.defaultView.backgroundColor = [UIColor redColor];
            }
            
            [container addSubview:correctView];
        }
    }
    
    NSString *fl = [_exToFL objectForKey:exid];
    if (fl == nil) {
        NSLog(@"arg -- error! no fl for %@",exid);
        cell.fl.text = @"";
    }
    else {
        NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:fl];
        
        NSRange range = NSMakeRange(0, [result length]);
        NSString *scoreString = [_exToScore objectForKey:exid];
        float score = [scoreString floatValue]/100.0f;
        if (score > 0) {
            UIColor *color = [self getColor2:score];
            [result addAttribute:NSBackgroundColorAttributeName
                           value:color
                           range:range];
        }
        
        cell.fl.attributedText = result;
        cell.english.text = [_exToEnglish objectForKey:exid];
    }
    return cell;
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
        
        int indexOfFirst = -1;
        if (jsonArray != nil) {
            _exToScore   = [[NSMutableDictionary alloc] init];
            _exToHistory = [[NSMutableDictionary alloc] init];
            _exList = [[NSMutableArray alloc] init];
            for (NSDictionary *entry in jsonArray) {
                NSString *ex = [entry objectForKey:@"ex"];
                if ([_exToFL objectForKey:ex] != nil) {
                    //   NSLog(@"ex key %@",ex);
                    NSString *score = [entry objectForKey:@"s"];
                    
                    //   NSLog(@"score  %@",score);
                    [_exToScore setValue:score forKey:ex];
                    
                    NSArray *jsonArrayHistory = [entry objectForKey:@"h"];
                    if (jsonArrayHistory.count > 0 && indexOfFirst == -1) {
                        indexOfFirst = _exToHistory.count;
                    }
                    [_exToHistory setValue:jsonArrayHistory forKey:ex];
                    [_exList addObject:ex];
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
        if (indexOfFirst > -1) {
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
  //    NSLog(@"Got point %f %f",p.x,p.y);
    
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
 //     NSLog(@"Got path %@",indexPath);
    
    NSInteger row = indexPath.row;
    NSString *exid = [_exList objectAtIndex:row];
    
 //   NSLog(@"exid selection %@",exid);
    
    for (NSDictionary *jsonObject in _jsonItems) {
   //     NSLog(@"comparing to %@",[jsonObject objectForKey:@"id"]);
        if ([[jsonObject objectForKey:@"id"] isEqualToString:exid]) {
         //   NSLog(@"got it %@",jsonObject);
           // NSString *refAudio = [jsonObject objectForKey:@"ref"];
            NSMutableArray *toPlay = [[NSMutableArray alloc] init];
            [toPlay addObject:[jsonObject objectForKey:@"ref"]];
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
                        _current.textColor = [UIColor blueColor];
                    }
                }
            }
            
            _audioPlayer.audioPaths = toPlay;
            [_audioPlayer playRefAudio];
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
