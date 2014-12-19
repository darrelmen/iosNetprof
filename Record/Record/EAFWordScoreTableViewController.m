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
//#import "BButton.h"
#import "SSKeychain.h"

@interface EAFWordScoreTableViewController ()

@end

@implementation EAFWordScoreTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _audioPlayer = [[EAFAudioPlayer alloc] init];

    //NSLog(@"got word score table view did load");
    
    NSString *userid = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"userid"];
    _user = [userid intValue];
    [self askServerForJson];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    // _tableView.cancelTouchesInView = NO;
    
  //  _playingIcon = [BButton awesomeButtonWithOnlyIcon:FAVolumeUp color:[UIColor blackColor] style:BButtonStyleBootstrapV3];
    
//    [_playingIcon initWithFrame:CGRectMake(0.0f, 0.0f, 32.0f, 32.0f)
//                          color:[UIColor colorWithWhite:1.0f alpha:0.0f]
//                          style:BButtonStyleBootstrapV3
//                           icon:FAVolumeUp
//                       fontSize:20.0f];
//    [_playingIcon setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
//    
    for(UIViewController *tab in self.tabBarController.viewControllers)
        
    {
      //  NSLog(@"EAFWordScoreTableViewController got item %@",tab.tabBarItem);        
        [tab.tabBarItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                [UIFont fontWithName:@"Helvetica" size:16.0], NSFontAttributeName, nil]
                                      forState:UIControlStateNormal];
    }
}

- (void)askServerForJson {
    NSString *baseurl = [NSString stringWithFormat:@"https://np.ll.mit.edu/npfClassroom%@/scoreServlet?request=chapterHistory&user=%ld&%@=%@&%@=%@", _language, _user, _unitName, _unitSelection, _chapterName, _chapterSelection];
   // NSString *baseurl = [NSString stringWithFormat:@"https://np.ll.mit.edu/npfClassroom%@/scoreServlet?request=chapterHistory&user=%ld&%@=%@", _language, _user, _chapterName, _chapterSelection];
    baseurl =[baseurl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    NSLog(@"askServerForJson url %@",baseurl);
    
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
        //NSLog(@"fl is %@",fl);
        NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:fl];
        
        NSRange range = NSMakeRange(0, [result length]);
        NSString *scoreString = [_exToScore objectForKey:exid];
        float score = [scoreString floatValue]/100.0f;
        
        // NSLog(@"score was %@ %f",scoreString,score);
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

- (void)setTitleGivenCorrect:(NSString *)incorrect correct:(NSString *)correct {
    float total = [correct floatValue] + [incorrect floatValue];
    float percent = total == 0.0f ? 0.0f : [correct floatValue]/total;
    percent *= 100;
    int percentInt = round(percent);
    int totalInt = round(total);
    UIViewController  *parent = [self parentViewController];
    NSString *wordReport;
    wordReport = [NSString stringWithFormat:@"%@ of %d Correct (%d%%)",correct,totalInt,percentInt];
    NSLog(@"setting correct title %@",wordReport);
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
        // NSLog(@"json for scores was %@",jsonArray);
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

- (IBAction)gotTapGesture:(UITapGestureRecognizer *) sender {
    CGPoint p = [sender locationInView:sender.view];
    //  NSLog(@"Got point %f %f",p.x,p.y);
    
    p = [sender locationInView:self.tableView];
  //    NSLog(@"Got point %f %f",p.x,p.y);
    
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
 //     NSLog(@"Got path %@",indexPath);
    
    NSInteger row = indexPath.row;
    NSString *exid = [_exList objectAtIndex:row];
    
 //   NSLog(@"exid selection %@",exid);
    
    for (NSDictionary *jsonObject in _jsonItems) {
   //     NSLog(@"comparing to %@",[jsonObject objectForKey:@"id"]);
        if ([[jsonObject objectForKey:@"id"] isEqualToString:exid]) {
            NSLog(@"got it %@",jsonObject);
            NSString *refAudio = [jsonObject objectForKey:@"ref"];
            NSMutableArray *toPlay = [[NSMutableArray alloc] init];
            [toPlay addObject:refAudio];
            
//            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            
//            for (UIView *subview in [cell.contentView subviews]) {
//                NSLog(@"subview %@",subview);
//                
//                if ([subview isKindOfClass:[UIImage class]]) {
//                            NSLog(@"got it %@",subview);
//
//                    _audioPlayer.playingIcon = subview;
//                    
//                }
//            }
            
     //       NSLog(@"playing audio @%",toPlay);
            _audioPlayer.audioPaths = toPlay;
            //  _audioPlayer.viewToAddIconTo = _contextFL;
            _audioPlayer.url = _url;
            _audioPlayer.language = _language;
            [_audioPlayer playRefAudio];
        }
    }

}

- (void) playStarted {
    
}


- (void) playStopped {
    
}

#pragma mark - Table view delegate

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    [tableView deselectRowAtIndexPath:indexPath animated:NO];
//    
//    NSInteger row = indexPath.row;
//    NSString *exid = [_exList objectAtIndex:row];
//    
//    NSLog(@"exid selection %@",exid);
//
//    for (NSDictionary *jsonObject in _jsonItems) {
//        if ([[jsonObject objectForKey:@"exid"] isEqualToString:exid]) {
//            NSLog(@"got it %@",jsonObject);
//            NSString *refAudio = [jsonObject objectForKey:@"ref"];
//            NSMutableArray *toPlay = [[NSMutableArray alloc] init];
//            [toPlay addObject:refAudio];
//            
//            
//            _audioPlayer.audioPaths = toPlay;
//          //  _audioPlayer.viewToAddIconTo = _contextFL;
//            _audioPlayer.url = _url;
//            _audioPlayer.language = _language;
//          //  _audioPlayer.playingIcon = _playingIcon;
//            [_audioPlayer playRefAudio];
//            
//        }
//    }
//    
//}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
