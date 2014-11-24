//
//  EAFItemTableViewController.m
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 7/11/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import "EAFItemTableViewController.h"
#import "EAFAudioCache.h"
#import "EAFRecoFlashcardController.h"
#import "SSKeychain.h"

@interface EAFItemTableViewController ()

@end

@implementation EAFItemTableViewController


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (NSString *)getURL
{
    return [NSString stringWithFormat:@"https://np.ll.mit.edu/npfClassroom%@/", _language];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _itemIndex = 0;
    _audioCache = [[EAFAudioCache alloc] init];
    
    self.paths = [[NSMutableArray alloc] init];
    self.rawPaths = [[NSMutableArray alloc] init];
    NSArray *items =_jsonItems;

     NSArray *fields = [NSArray arrayWithObjects:@"ref",@"mrr",@"mrs",@"frr",@"frs",nil];

    for (NSDictionary *object in items) {
        for (NSString *id in fields) {
            NSString *refPath = [object objectForKey:id];
            if (refPath && refPath.length > 2) { //i.e. not NO
                refPath = [refPath stringByReplacingOccurrencesOfString:@".wav"
                                                             withString:@".mp3"];
                
                NSMutableString *mu = [NSMutableString stringWithString:refPath];
                [mu insertString:[self getURL] atIndex:0];
                [_paths addObject:mu];
                [_rawPaths addObject:refPath];
            }
        }
    }
    
    [_audioCache goGetAudio:_rawPaths paths:_paths language:_language];

    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
    [self setTitle:[NSString stringWithFormat:@"%@ %@ %@",_language,chapterTitle,currentChapter]];
    
    NSString *userid = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"userid"];
    _user = [userid intValue];
    
    [self askServerForJson];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

NSString *currentChapter;
NSString *chapterTitle = @"Chapter";

- (void)setChapter:(NSString *) chapter {
    currentChapter = chapter;
    
    NSLog(@"ItemTableViewController - current chapter %@",currentChapter);
}

- (void)setChapterTitle:(NSString *) title {
    chapterTitle = title;
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
    //NSLog(@"found rows %d",self.items.count);
    return [_jsonItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"WordListPrototype";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NSDictionary *jsonObject =[_jsonItems objectAtIndex:indexPath.row];
    
    NSString *exercise = [jsonObject objectForKey:@"fl"];
    NSString *englishPhrases = [jsonObject objectForKey:@"en"];
    NSString *id = [jsonObject objectForKey:@"id"];
    NSArray *answers = [_exToHistory objectForKey:id];
    
    if (answers == nil || answers.count == 0) {
        cell.imageView.image = [UIImage imageNamed:@"questionIcon.png"];
    }
    else {
        int index = 0;
        for (NSString *correct in answers) {
            if ([correct isEqualToString:@"Y"]) {
                cell.imageView.image = [UIImage imageNamed:@"checkmark32.png"];

            }
            else {
                cell.imageView.image = [UIImage imageNamed:@"redx32.png"];
            }
            
        }
    }
    
    
    
    cell.textLabel.text = exercise;
    cell.detailTextLabel.text = englishPhrases;
    
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

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    EAFRecoFlashcardController *flashcardController = [segue destinationViewController];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    NSInteger row = indexPath.row;
    NSLog(@"got seque row %ld %@ %@",(long)indexPath.row, chapterTitle, currentChapter );
 
    flashcardController.jsonItems = _jsonItems;
    flashcardController.index = row;
    flashcardController.language = _language;
    flashcardController.url = [self getURL];
    [flashcardController setTitle:[NSString stringWithFormat:@"%@ Chapter %@",_language,currentChapter]];
    [flashcardController setHasModel:_hasModel];
    flashcardController.chapterTitle = chapterTitle;
    flashcardController.currentChapter = currentChapter;
    flashcardController.itemViewController = self;
    _notifyFlashcardController = flashcardController;
}

- (void)askServerForJson {
    // NSString *baseurl = [NSString stringWithFormat:@"https://np.ll.mit.edu/npfClassroom%@/scoreServlet?request=chapterHistory&user=%ld&%@=%@&%@=%@", _language, _user, _unitName, _unitSelection, _chapterName, _chapterSelection];
    NSString *baseurl = [NSString stringWithFormat:@"https://np.ll.mit.edu/npfClassroom%@/scoreServlet?request=chapterHistory&user=%ld&%@=%@", _language, _user, chapterTitle, currentChapter];
    
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
    
    NSMutableDictionary *exToEntry = [[NSMutableDictionary alloc] init];
    for (NSDictionary *entry in _jsonItems) {
        NSString *ex = [entry objectForKey:@"id"];
       [exToEntry setObject:entry forKey:ex];
    }
    NSMutableArray *newOrder = [[NSMutableArray alloc] init];
    
    NSArray *jsonArray = [json objectForKey:@"scores"];
    if (jsonArray != nil) {
        _exToScore   = [[NSMutableDictionary alloc] init];
        _exToHistory = [[NSMutableDictionary alloc] init];
        _exList = [[NSMutableArray alloc] init];
        for (NSDictionary *entry in jsonArray) {
            NSString *ex = [entry objectForKey:@"ex"];
            
            NSDictionary *entryForID = [exToEntry objectForKey:ex];
            if (entryForID != nil) {
                [newOrder addObject:entryForID];
            }
            //   NSLog(@"ex key %@",ex);
            NSString *score = [entry objectForKey:@"s"];
            //   NSLog(@"score  %@",score);
            [_exToScore setValue:score forKey:ex];
            
            NSArray *jsonArrayHistory = [entry objectForKey:@"h"];
            
            [_exToHistory setValue:jsonArrayHistory forKey:ex];
            [_exList addObject:ex];
        }
        
        if ([newOrder count] > 0) {
            _jsonItems = newOrder;
            if (_notifyFlashcardController != nil) {
                _notifyFlashcardController.jsonItems = _jsonItems;
                [_notifyFlashcardController respondToSwipe ];
            }
            [[self tableView] reloadData];
        }
    }
    else {
        NSLog(@"got empty json???");
        if (_notifyFlashcardController != nil) {
            [_notifyFlashcardController respondToSwipe ];
        }
    }
    
    return true;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // The request is complete and data has been received
    
    //[loadingContentAlert dismissWithClickedButtonIndex:0 animated:true];
    NSLog(@"connectionDidFinishLoading... "
          );

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
}

@end
