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
//  EAFChapterTableViewController.m
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 7/11/14.
//  Copyright (c) 2011-2016 Massachusetts Institute of Technology, Lincoln Laboratory
//

#import "EAFChapterTableViewController.h"
#import "EAFSignUpViewController.h"
#import "EAFItemTableViewController.h"
#import "SSKeychain.h"
#import "EAFEventPoster.h"
#import "EAFGetSites.h"

@interface EAFChapterTableViewController ()

@property BOOL isRefresh;
@property CFAbsoluteTime startPost;
@property NSArray *jsonContentArray;
@property (strong, nonatomic) NSData *responseData;
@property int reqCount;
@property int receivedCount;

@property NSDictionary* chapterInfo;
@property BOOL hasModel;
@property NSArray *currentItems;
@property EAFGetSites *siteGetter;
@property EAFEventPoster *poster;

@end

@implementation EAFChapterTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        _reqCount = 0;
        _receivedCount = 0;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _siteGetter = [EAFGetSites new];
    _siteGetter.delegate = self;
    
    if (self.chapters == nil) {
        self.chapters = [[NSMutableArray alloc] init];
    }
    NSString *version = [[UIDevice currentDevice] systemVersion];
    
    // HACK?
    BOOL isEight = [version hasPrefix:@"8"];
    
    if (isEight) {
        [self tableView].rowHeight = UITableViewAutomaticDimension;
    }
    
    _language = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"language"];
    _poster = [[EAFEventPoster alloc] initWithURL:_url];//] projid:[_siteGetter.nameToProjectID objectForKey:_language]];

   [self setTitle:_language];
    
//    if (_jsonContentArray == nil) {
//        [self loadInitialData];
//    }
    [_siteGetter getSites];
    
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

- (void)askServerForJson:(BOOL) isRefresh {
    _isRefresh = isRefresh;
    
    _reqCount++;
    NSString *baseurl = [NSString stringWithFormat:@"%@/scoreServlet?nestedChapters", [_siteGetter.nameToURL objectForKey:_language]];
    
    NSURL *url = [NSURL URLWithString:baseurl];
    
    NSLog(@"ChapterTableViewController - askServerForJson %@",url);

    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    
    [urlRequest setHTTPMethod: @"GET"];
    [urlRequest setValue:@"application/x-www-form-urlencoded"
      forHTTPHeaderField:@"Content-Type"];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:true];

    _startPost = CFAbsoluteTimeGetCurrent();
    
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         //NSLog(@"ChapterTableViewController - Got response %@",error);
         if (error != nil) {
             NSLog(@"ChapterTableViewController Got error %@",error);
             dispatch_async(dispatch_get_main_queue(), ^{
                 [self connection:nil didFailWithError:error];
             });
         }
         else {
             NSLog(@"ChapterTableViewController Got data %lu",(unsigned long)data.length);

             _responseData = data;
             [self performSelectorOnMainThread:@selector(connectionDidFinishLoading:)
                                    withObject:nil
                                 waitUntilDone:YES];
         }
     }];
}

- (void) sitesReady {
    if (_jsonContentArray == nil) {
        [self loadInitialData];
    }
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
    NSString *appFile = [self getCachedJsonFile];
    NSLog(@"Writing json data to file %@ %lu bytes",appFile,(unsigned long)toWrite.length);
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
        _hasModel = [[json objectForKey:@"hasModel"] boolValue];
    //    NSLog(@"Chapter - Got model %@",_hasModel ?@"YES":@"NO");
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
        _chapterInfo = json;
    }
    else {
        NSLog(@"\n\n\n UNexpected - deprecated - Got model %@",_hasModel ?@"YES":@"NO");
        _chapters = [json allKeys];
        
        NSMutableArray *myArray = [NSMutableArray arrayWithArray:_chapters];
        
        //sorting
        [myArray sortUsingComparator:^NSComparisonResult(NSString *str1, NSString *str2) {
            return [str1 compare:str2 options:(NSNumericSearch)];
        }];
        
        _chapters = myArray;
        _chapterInfo = json; // this is the full json dictionary (???)
    }
    [[self tableView] reloadData];
    
    return true;
}

- (void)postEvent:(NSString *) message widget:(NSString *) widget type:(NSString *) type {
    [_poster postEvent:message exid:@"N/A" widget:widget widgetType:type];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // The request is complete and data has been received
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    CFAbsoluteTime diff = (now-_startPost);
    
    NSLog(@"connectionDidFinishLoading course content round trip time was %f",diff);
    [self postEvent:[NSString stringWithFormat:@"Roundtrip to download content for %.2f",diff] widget:@"download content" type:[NSString stringWithFormat:@"%.2f",diff]];
    
    [loadingContentAlert dismissWithClickedButtonIndex:0 animated:true];
    
    BOOL dataIsValid = [self useJsonChapterData];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];

    _receivedCount++;
    if (_receivedCount != _reqCount) {
        NSLog(@"ignoring out of order requests %d vs %d",_reqCount,_receivedCount);
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
    
    _receivedCount++;
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

/*
 * Marks chapters that have their content pruned out b/c of missing audio.
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ListPrototypeCell" forIndexPath:indexPath];
    
    NSString *chapter = [_chapters objectAtIndex:indexPath.row];
    NSString *prefix = [NSString stringWithFormat:@"%@ %@",_chapterName, chapter];
    
    NSMutableString  *title = [[NSMutableString alloc] init];
    
    [title appendString:prefix];
    [title appendString:@" : "];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@ %@",_chapterName, chapter];
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        cell.textLabel.font = [UIFont systemFontOfSize:28]; //Change this value to adjust size
    }
    
    NSDictionary *theChapter = [NSDictionary new];
    
    // mark chapters with empty content
    for (NSDictionary *entry in _jsonContentArray) {
        NSString *name =[entry objectForKey:@"name"];
        theChapter = entry;
        if ([name isEqualToString:chapter]) {
            NSArray *items = [entry objectForKey:@"items"];
            if (items == nil) { // no items - not a leaf
                break;
            }
            else {
                if (items.count == 0) {
                    cell.textLabel.text = [NSString stringWithFormat:@"%@ %@ (No Audio Available)",_chapterName, chapter];
                }
//                NSLog(@"items %lu",(unsigned long)items.count);

                break;
            }
        }
    }
    
    NSArray *items2 = [theChapter objectForKey:@"items"];
    if (items2 != nil) {
        unsigned long max = items2.count;
        if (max > 5) max = 5;
        int count = 0;
        NSArray *smallArray = [items2 subarrayWithRange:NSMakeRange(0, max)];
        NSMutableArray *starts = [NSMutableArray new];
        NSMutableArray *ends   = [NSMutableArray new];
        
        for (NSDictionary *item in smallArray) {
            NSString *fl =[item objectForKey:@"fl"];
            NSString *en =[item objectForKey:@"en"];
            //NSLog(@"fl %@",[self trim:fl]);
            [starts addObject:[NSNumber numberWithUnsignedInteger:title.length]];
            NSString *trimFL =[self trim:fl];
            [ends addObject:[NSNumber numberWithUnsignedInteger:trimFL.length]];
            
            [title appendString:trimFL];
            [title appendString:@" "];
            [title appendString:[self trim:en]];
            if (++count < smallArray.count) {
                [title appendString:@", "];
            }
        }
        NSMutableAttributedString *title2 = [[NSMutableAttributedString alloc] initWithString:title];
        
        for (int i = 0; i < starts.count; i++) {
            NSNumber *start = [starts objectAtIndex:i];
            NSNumber *len =   [ends objectAtIndex:i];
            NSUInteger len2 = [len unsignedIntegerValue];
            
            NSRange range = NSMakeRange([start unsignedIntegerValue], len2);
            
            [title2 addAttribute:NSForegroundColorAttributeName
                           value:[UIColor blueColor]
                           range:range];
        }
        cell.textLabel.attributedText = title2;
    }
    
    return cell;
}


- (NSString *)trim:(NSString *)untrimedToken {
    return [untrimedToken stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
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

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    EAFItemTableViewController *itemController = [segue destinationViewController];
 
//    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
 //   NSString *tappedItem = [self.chapters objectAtIndex:indexPath.row];
//    NSLog(@"Chapter table view controller prepareForSegue identifier %@ %@ %@ %@ %@",segue.identifier,_chapterName,tappedItem,
//          _unitTitle,_unit);

    NSLog(@"Chapter table Got prepare -- %@ has model %@ url %@",itemController, _hasModel?@"YES":@"NO", _url);
    [itemController setChapterToItems:_chapterInfo];
    [itemController setJsonItems:_currentItems];
    itemController.chapterTitle = _chapterName;
    itemController.currentChapter =_currentChapter;
    [itemController setLanguage:_language];
    itemController.hasModel=_hasModel;
    itemController.unitTitle = _unitTitle;
    itemController.unit = _unit;
    itemController.url = _url;
    itemController.isRTL = _isRTL;
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
                myController.hasModel = _hasModel;
                myController.url = _url;
                myController.isRTL = _isRTL;
                
                [self.navigationController pushViewController: myController animated:YES];
                break;
            }
            else {
         //       NSLog(@"Got click to segue to items is %lu",(unsigned long)items.count);
                // TODO : ask for history here?
                // when returns, go ahead and do segue
                
                _currentChapter = name;
                _currentItems = items;
                
                [self performSegueWithIdentifier:@"ItemViewController" sender:self];
                
                break;
            }
        }
    }
}
@end
