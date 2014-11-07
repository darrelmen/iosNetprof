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

@interface EAFPhoneScoreTableViewController ()

@end

@implementation EAFPhoneScoreTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSLog(@"got phone score table view did load");
    
    _user=1;  // TODO find this out at login/sign up

    [self askServerForJson];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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
   // NSArray *wordsPhoneAppearsIn = [_phonesInOrder objectAtIndex:indexPath.row];
    NSString *phone = [_phonesInOrder objectAtIndex:indexPath.row];
    NSArray *words = [_phoneToWords objectForKey:phone];
    
    cell.textLabel.text = [words objectAtIndex:0];
    //cell.detailTextLabel.text = @"More text";
    //cell.imageView.image = [UIImage imageNamed:@"flower.png"];
    
    // set the accessory view:
   // cell.accessoryType =  UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    // Configure the cell...
//    MyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"WordScoreCell" forIndexPath:indexPath];
// 
//    NSMutableArray *icons = [[NSMutableArray alloc] init];
//    [icons addObject:cell.first];
//    [icons addObject:cell.second];
//    [icons addObject:cell.third];
//    [icons addObject:cell.fourth];
//    [icons addObject:cell.fifth];
//    
//    for (UIView *container in icons) {
//        for (UIView *v in [container subviews]) {
//            [v removeFromSuperview];
//        }
//    }
//    
//    NSInteger row = indexPath.row;
//    NSString *exid = [_exList objectAtIndex:row];
//    NSArray *answers = [_exToHistory objectForKey:exid];
//    //NSLog(@"ex answers %@ %@",exid,answers);
//
//    int index = 0;
//  //  int correctCount = 0;
//  //  int incorrectCount = 0;
//    for (NSString *correct in answers) {
//      //  NSLog(@"ex %@ %@",exid,correct);
//        UIView *container = [icons objectAtIndex:(index++ + (5-[answers count]))];
//        
//        FAImageView *correctView = [[FAImageView alloc] initWithFrame:CGRectMake(0.f, 0.f, 22.f, 22.f)];
//        correctView.image = nil;
//        if ([correct isEqualToString:@"Y"]) {
//            [correctView setDefaultIconIdentifier:@"fa-check"];
//            correctView.defaultIconColor = [UIColor greenColor];
//            correctView.defaultView.backgroundColor = [UIColor greenColor];
////            if (index == [answers count]) {
////                correctCount++;
////            }
//        }
//        else {
//            [correctView setDefaultIconIdentifier:@"fa-times"];
//            correctView.defaultIconColor = [UIColor redColor];
//            correctView.defaultView.backgroundColor = [UIColor redColor];
////            if (index == [answers count]) {
////                incorrectCount++;
////            }
//        }
//       
//        [container addSubview:correctView];
//    }
////    NSLog(@"correct %d incorrect %d",correctCount,incorrectCount);
//    
//    // TODO display and calc correct/incorrect skipped
//    
//    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:[_exToFL objectForKey:exid]];
//
//    NSRange range = NSMakeRange(0, [result length]);
//    NSString *scoreString = [_exToScore objectForKey:exid];
//    float score = [scoreString floatValue]/100.0f;
//   
//   // NSLog(@"score was %@ %f",scoreString,score);
//    if (score > 0) {
//        UIColor *color = [self getColor2:score];
//        [result addAttribute:NSBackgroundColorAttributeName
//                       value:color
//                       range:range];
//    }
//    
//    cell.fl.attributedText = result;
//    
//    return cell;
//}

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
//NSDictionary* chapterInfo;
//BOOL hasModel;

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
    
    NSLog(@"useJsonChapter data ");
    
    NSDictionary *phoneDict = [json objectForKey:@"phones"];
    NSDictionary *resultsDict = [json objectForKey:@"results"];
    _phonesInOrder = [[NSArray alloc] initWithArray:[json objectForKey:@"order"]];
    
    _phoneToWords   = [[NSMutableDictionary alloc] init];
    _resultToRef   = [[NSMutableDictionary alloc] init];
    _resultToAnswer   = [[NSMutableDictionary alloc] init];

    for (NSString *phone in phoneDict) {
         NSArray *wordsPhoneAppearsIn = [phoneDict objectForKey:phone];
        [_phoneToWords setValue:wordsPhoneAppearsIn forKey:phone];
    }
    
    for (NSString *resultID in resultsDict) {
        NSDictionary *fields = [resultsDict objectForKey:resultID];
        [_resultToRef setValue:[fields objectForKey:@"ref"] forKey:resultID];
        [_resultToAnswer setValue:[fields objectForKey:@"answer"] forKey:resultID];
    }

    [[self tableView] reloadData];
    
    return true;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // The request is complete and data has been received
    
    //[loadingContentAlert dismissWithClickedButtonIndex:0 animated:true];
    
    //BOOL dataIsValid =
    [self useJsonChapterData];
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
