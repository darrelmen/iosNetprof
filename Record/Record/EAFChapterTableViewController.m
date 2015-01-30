//
//  EAFChapterTableViewController.m
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 7/11/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import "EAFChapterTableViewController.h"
#import "EAFSignUpViewController.h"
#import "EAFItemTableViewController.h"
#import "SSKeychain.h"
#import "EAFEventPoster.h"

@interface EAFChapterTableViewController ()

@property BOOL isRefresh;
@property CFAbsoluteTime startPost;

@end

@implementation EAFChapterTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.chapters == nil) {
        self.chapters = [[NSMutableArray alloc] init];
    }
    
    _language = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"language"];

    [self setTitle:_language];
    
    if (_jsonContentArray == nil) {
        [self loadInitialData];
    }
    
    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    NSMutableArray *navigationArray = [[NSMutableArray alloc] initWithArray: self.navigationController.viewControllers];
    
    BOOL found = false;
    for (UIViewController *controller in self.navigationController.viewControllers) {
        BOOL isSignUp = [controller isKindOfClass:[EAFSignUpViewController class]];
        if (isSignUp) {
            found = TRUE;
            [navigationArray removeObject:controller];
        }
    }
    if (found) {
        self.navigationController.viewControllers = navigationArray;
    }
}

int reqCount = 0;;
int receivedCount = 0;;

- (void)askServerForJson:(BOOL) isRefresh {
    _isRefresh = isRefresh;
    
    reqCount++;
    NSString *baseurl = [NSString stringWithFormat:@"https://np.ll.mit.edu/npfClassroom%@/scoreServlet?nestedChapters", _language];
    
    NSURL *url = [NSURL URLWithString:baseurl];
    
    NSLog(@"ChapterTableViewController - askServerForJson %@",url);

    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    [urlRequest setCachePolicy:NSURLRequestReturnCacheDataElseLoad];
    
    [urlRequest setHTTPMethod: @"GET"];
    [urlRequest setValue:@"application/x-www-form-urlencoded"
      forHTTPHeaderField:@"Content-Type"];
    
//    NSURLConnection *connection = [NSURLConnection connectionWithRequest:urlRequest delegate:self];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:true];

    _startPost = CFAbsoluteTimeGetCurrent();

  //  [connection start];
    
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         NSLog(@"ChapterTableViewController - Got response %@",error);
         
         if (error != nil) {
             NSLog(@"ChapterTableViewController Got error %@",error);
             [self connection:nil didFailWithError:error];
         }
         else {
             _responseData = data;
             [self connectionDidFinishLoading:nil];
         }
     }];
}

UIAlertView *loadingContentAlert;

- (void)loadInitialData {
    NSLog(@"loadInitialData");

    NSData *cachedData = [self getCachedJson];
    if (cachedData && [cachedData length] > 100) {
        NSLog(@"loadInitialData : using cached json!");
        _responseData = [NSMutableData dataWithData:cachedData];
        BOOL dataIsValid = [self useJsonChapterData];
        if (!dataIsValid) {
            NSLog(@"loadInitialData : asking server for json!");
            [self askServerForJson:false];
        }
        else {
            [self refreshCache];
        }
    }
    else {
        // show please wait dialog
        loadingContentAlert = [[UIAlertView alloc] initWithTitle:@"Fetching course word list\nPlease Wait..." message:nil delegate:self cancelButtonTitle:nil otherButtonTitles: nil];
        [loadingContentAlert show];
        
        [self askServerForJson:false];
    }
}

// refresh cache checks how old the cached file is
- (void)writeToCache:(NSData *) toWrite {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *fileName = [NSString stringWithFormat:@"%@_chapters.json",_language];
    NSString *appFile = [documentsDirectory stringByAppendingPathComponent:fileName];
    
    NSLog(@"Writing json data to file %@",appFile);
    [toWrite writeToFile:appFile atomically:YES];
}

- (NSString *)getCachedJsonFile {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *fileName = [NSString stringWithFormat:@"%@_chapters.json",_language];
    NSString *appFile = [documentsDirectory stringByAppendingPathComponent:fileName];
    return appFile;
}

// every 24 hours check with the server for updates
- (void)refreshCache {
    NSString *appFile = [self getCachedJsonFile];
    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:appFile];
    
    if (fileExists) {
        NSLog(@"refreshCache found the cached json at %@",appFile);
        
        NSFileManager* fm = [NSFileManager defaultManager];
        NSDictionary* attrs = [fm attributesOfItemAtPath:appFile error:nil];
        
        if (attrs != nil) {
            NSDate *date = (NSDate*)[attrs objectForKey: NSFileCreationDate];
            //NSLog(@"getCachedJson Date Created: %@", [date description]);
            CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
            CFAbsoluteTime fileDate =[date timeIntervalSinceReferenceDate];
            CFAbsoluteTime diff = now-fileDate;
            if (diff > 24*60*60) {
                NSLog(@"refreshCache file is stale - time = %f vs %f - diff %f",CFAbsoluteTimeGetCurrent(),  [date timeIntervalSinceReferenceDate], diff);
                [self askServerForJson:true];
            }
            else {
                NSLog(@"refreshCache cache *not* stale time = %f vs %f - diff %f",CFAbsoluteTimeGetCurrent(),  [date timeIntervalSinceReferenceDate], diff);
            }
        }
        else {
            NSLog(@"No file attributes for %@???",appFile);
        }
    }
}

//
- (NSData *) getCachedJson {
    NSString *appFile = [self getCachedJsonFile];
   
    if ([[NSFileManager defaultManager] fileExistsAtPath:appFile]) {
        NSLog(@"getCachedJson : found the cached json at %@",appFile);
        NSData *data = [[NSFileManager defaultManager] contentsAtPath:appFile];
        return data;
    }
    else {
        NSLog(@"getCachedJson : no cached json at %@",appFile);
        return nil;
    }
}

#pragma mark NSURLConnection Delegate Methods

//long long expected;

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // A response has been received, this is where we initialize the instance var you created
    // so that we can append data to it in the didReceiveData method
    // Furthermore, this method is called each time there is a redirect so reinitializing it
    // also serves to clear it
 //   NSLog(@"didReceiveResponse... %@ %lld",response, response.expectedContentLength);
//    expected = response.expectedContentLength;
    _responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // Append the new data to the instance variable you declared
  //  float progress = ((float) [_responseData length] / (float) expected);
  //  NSLog(@"didReceiveData... %f",progress);
   // NSLog(@"didReceiveData...");

 //   [_responseData appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
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
        NSLog(@"error %@",error.description);
        return false;
    }
    
    NSArray *jsonArray = [json objectForKey:@"content"];
    
    if (jsonArray != nil) {
        _jsonContentArray = jsonArray;
        id something =[json objectForKey:@"hasModel"];
        
        hasModel = [something boolValue];
     
        NSMutableArray *myArray = [[NSMutableArray alloc] init];
        
        for (NSDictionary *entry in jsonArray) {
            if (_unitTitle == nil) {
                _unitTitle = [entry objectForKey:@"type"];
            }
            else {
                _chapterName = [entry objectForKey:@"type"]; // a little redundant here.
            }
            [myArray addObject:[entry objectForKey:@"name"]];
        }
        //sorting
        [myArray sortUsingComparator:^NSComparisonResult(NSString *str1, NSString *str2) {
            return [str1 compare:str2 options:(NSNumericSearch)];
        }];
        _chapters = myArray;
        chapterInfo = json;
    }
    else {
        _chapters = [json allKeys];
        
        NSMutableArray *myArray = [NSMutableArray arrayWithArray:_chapters];
        
        //sorting
        [myArray sortUsingComparator:^NSComparisonResult(NSString *str1, NSString *str2) {
            return [str1 compare:str2 options:(NSNumericSearch)];
        }];
        
        _chapters = myArray;
        chapterInfo = json; // this is the full json dictionary (???)
    }
    [[self tableView] reloadData];
    
    return true;
}


- (void)postEvent:(NSString *) message widget:(NSString *) widget type:(NSString *) type {
    EAFEventPoster *poster = [[EAFEventPoster alloc] init];
    [poster postEvent:message exid:@"N/A" lang:_language widget:widget widgetType:type];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // The request is complete and data has been received
    NSLog(@"connectionDidFinishLoading : chapters");

    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    CFAbsoluteTime diff = (now-_startPost);
    
    NSLog(@"course content round trip time was %f",diff);
    [self postEvent:[NSString stringWithFormat:@"Roundtrip to download content for %.2f",diff] widget:@"download content" type:[NSString stringWithFormat:@"%.2f",diff]];
    
    [loadingContentAlert dismissWithClickedButtonIndex:0 animated:true];
    
    BOOL dataIsValid = [self useJsonChapterData];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];

    receivedCount++;
    if (receivedCount != reqCount) {
        NSLog(@"ignoring out of order requests %d vs %d",reqCount,receivedCount);
    }
    else if (dataIsValid) {
        [self writeToCache:_responseData];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // The request has failed for some reason!
    // Check the error var
    NSLog(@"ChapterTable Download content failed with %@",error);
    [loadingContentAlert dismissWithClickedButtonIndex:0 animated:true];
    
    receivedCount++;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];
    
    if (!_isRefresh) {
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
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.chapters count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ListPrototypeCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
 
   // NSLog(@"selecting row %d out of %d chapters",indexPath.row, self.chapters.count);
    
    NSString *chapter = [self.chapters objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ %@",_chapterName, chapter];

    return cell;
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


#pragma mark - Navigation
NSArray *currentItems;

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    EAFItemTableViewController *itemController = [segue destinationViewController];
 
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    NSString *tappedItem = [self.chapters objectAtIndex:indexPath.row];
    NSLog(@"Chapter table view controller prepareForSegue identifier %@ %@ %@ %@ %@",segue.identifier,_chapterName,tappedItem,
          _unitTitle,_unit);

 //   NSLog(@"Got prepare -- %@",itemController);
    [itemController setChapterToItems:chapterInfo];
    [itemController setJsonItems:currentItems];
    [itemController setChapterTitle:_chapterName];
    [itemController setChapter:_currentChapter];
    [itemController setLanguage:_language];
    [itemController setHasModel:hasModel];
    itemController.unitTitle = _unitTitle;
    itemController.unit = _unit;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    NSString *tappedItem = [self.chapters objectAtIndex:indexPath.row];
    NSArray *children;
    
    for (NSDictionary *entry in _jsonContentArray) {
        NSString *name =[entry objectForKey:@"name"];
        //NSLog(@"looking for '%@' '%@'",name, tappedItem);

        if ([name isEqualToString:tappedItem]) {
            
           // NSLog(@"=---- > got match '%@' '%@'",name, tappedItem);

            NSArray *items = [entry objectForKey:@"items"];
            if (items == nil) { // no items - not a leaf
                children = [entry objectForKey:@"children"];
                //NSLog(@"children are %@",children);
                EAFChapterTableViewController *myController = [self.storyboard instantiateViewControllerWithIdentifier:@"ChapterViewController"];
                [myController setJsonContentArray:children];
                
                NSMutableArray *myArray = [[NSMutableArray alloc] init];
                
                NSString *childType = nil;
                for (NSDictionary *child in children) {
                    childType = [child objectForKey:@"type"];
                    [myArray addObject:[child objectForKey:@"name"]];
                }
                //sorting
                [myArray sortUsingComparator:^NSComparisonResult(NSString *str1, NSString *str2) {
                    return [str1 compare:str2 options:(NSNumericSearch)];
                }];
                
                NSString *title = [[self title] stringByAppendingFormat:@" %@ %@",[entry objectForKey:@"type"],name];
             //   NSLog(@"tableView %@ child %@",title, childType);

                [myController setChapters:myArray];
                [myController setTitle:title];
                [myController setLanguage:_language];
                [myController setChapterName:childType];
                myController.unitTitle = _unitTitle;
                myController.unit = name;
                
                [self.navigationController pushViewController: myController animated:YES];
                break;
            }
            else {
         //       NSLog(@"items is %@",items);
         //       NSLog(@"Got click to segue to items");
                
                // TODO : ask for history here!
                // when returns, go ahead and do segue
                
                _currentChapter = name;
                currentItems = items;
                [self performSegueWithIdentifier:@"ItemViewController" sender:self];
                
                break;
            }
        }
    }
}
@end
