//
//  EAFLanguageTableViewController.m
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 7/16/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import "EAFWordScoreTableViewController.h"

@interface EAFWordScoreTableViewController ()

@end

@implementation EAFWordScoreTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSLog(@"got word score table view did load");
    
    //_language = @"CM";
    _user=1;  // TODO find this out at login/sign up
    
   // _unitName = @"Unit";
  //  _unitSelection = @"1";
    
  //  _chapterName = @"Lesson";
  //  _chapterSelection = @"1";

    [self askServerForJson];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)askServerForJson {
   // NSString *baseurl = [NSString stringWithFormat:@"https://np.ll.mit.edu/npfClassroom%@/scoreServlet?request=chapterHistory&user=%ld&%@=%@&%@=%@", _language, _user, _unitName, _unitSelection, _chapterName, _chapterSelection];
    NSString *baseurl = [NSString stringWithFormat:@"https://np.ll.mit.edu/npfClassroom%@/scoreServlet?request=chapterHistory&user=%ld&%@=%@", _language, _user, _chapterName, _chapterSelection];
    
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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

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
    //UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    static NSString *CellIdentifier = @"WordScoreCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    //NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    NSInteger row = indexPath.row;   
    
    NSString *exid = [_exList objectAtIndex:row];
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:[_exToFL objectForKey:exid]];

    NSRange range = NSMakeRange(0, [result length]);
    NSString *scoreString = [_exToScore objectForKey:exid];
    float score = [[_exToScore objectForKey:exid] floatValue]/100.0f;
   
   // NSLog(@"score was %@ %f",scoreString,score);
    if (score > 0) {
        UIColor *color = [self getColor2:score];
        [result addAttribute:NSBackgroundColorAttributeName
                       value:color
                       range:range];
    }
    
    cell.textLabel.attributedText = result;
    cell.detailTextLabel.text =  [_exToEnglish objectForKey:exid];
    
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
    
  //  NSLog(@"didReceiveResponse ----- ");

    _responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
   // NSLog(@"didReceiveData ----- ");

    // Append the new data to the instance variable you declared
    [_responseData appendData:data];
}
NSDictionary* chapterInfo;
BOOL hasModel;

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
    
    NSArray *jsonArray = [json objectForKey:@"scores"];
    
    if (jsonArray != nil) {
        _jsonContentArray = jsonArray; // remove
        _exToScore   = [[NSMutableDictionary alloc] init];
        _exToHistory = [[NSMutableDictionary alloc] init];
        _exList = [[NSMutableArray alloc] init];
        for (NSDictionary *entry in jsonArray) {
            NSString *ex = [entry objectForKey:@"ex"];
         //   NSLog(@"ex key %@",ex);
           // int score = [[entry objectForKey:@"s"] intValue];
            NSString *score = [entry objectForKey:@"s"];
            
         //   NSLog(@"score  %@",score);

            [_exToScore setValue:score forKey:ex];
            
            NSArray *jsonArrayHistory = [json objectForKey:@"h"];

            [_exToHistory setValue:jsonArrayHistory forKey:ex];
            [_exList addObject:ex];
        }
        NSLog(@"ex to score %lu",(unsigned long)[_exToScore count]);
    }

    [[self tableView] reloadData];
    
    return true;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // The request is complete and data has been received
    
    //[loadingContentAlert dismissWithClickedButtonIndex:0 animated:true];
    
    BOOL dataIsValid = [self useJsonChapterData];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];
    
  //  receivedCount++;
  //  if (receivedCount != reqCount) {
  //      NSLog(@"ignoring out of order requests %d vs %d",reqCount,receivedCount);
  //  }
  //  else if (dataIsValid) {
  //      [self writeToCache:_responseData];
   // }
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