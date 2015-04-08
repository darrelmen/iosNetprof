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

@property BOOL requestPending;
@property EAFAudioCache *audioCache;
@property (strong, nonatomic) NSData *responseData;

@property NSArray *scores;

@property NSDictionary *exToEnglish;

@property NSDictionary *exToScore;
@property NSDictionary *exToHistory;
@property NSDictionary *exToJson;

@property EAFRecoFlashcardController *notifyFlashcardController;
@end

@implementation EAFItemTableViewController

- (NSString *)getURL
{
    return [NSString stringWithFormat:@"https://np.ll.mit.edu/npfClassroom%@/", _language];
}

- (void)cacheAudio:(NSArray *)items
{
    NSMutableArray *paths = [[NSMutableArray alloc] init];
    NSMutableArray *rawPaths = [[NSMutableArray alloc] init];
    
    NSArray *fields = [NSArray arrayWithObjects:@"ref",@"mrr",@"msr",@"frr",@"fsr",@"ctmref",@"ctfref",@"ctref",nil];
    
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
        }
    }
    
    NSLog(@"ItemTableViewController.cacheAudio Got get audio -- %@ ",_audioCache);
    [_audioCache goGetAudio:rawPaths paths:paths language:_language];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _audioCache = [[EAFAudioCache alloc] init];
    //NSLog(@"made audio cache...");
  //  NSLog(@"viewDidLoad - item table controller - %@, count = %lu", _hasModel?@"YES":@"NO",(unsigned long)_jsonItems.count);

    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
    [self setTitle:[NSString stringWithFormat:@"%@ %@ %@",([_language isEqualToString:@"CM"] ? @"Mandarin":_language),_chapterTitle,_currentChapter]];
    
    NSString *userid = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"userid"];
    _user = [userid intValue];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillDisappear:(BOOL)animated {
    NSLog(@"ItemViewController : viewWillDisappear -- cancelling %@",_audioCache);
    [_audioCache cancelAllOperations];
    [super viewWillDisappear:animated];
}

-(void)viewWillAppear:(BOOL)animated {
    NSLog(@"ItemViewController : viewWillAppear ");
    [self askServerForJson];
    [super viewWillAppear:animated];
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
    return _requestPending ? 0:[_jsonItems count];
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

// use score history to color each word if multi-word phrase
// TODO : don't copy this code - see WordScoreTableViewController
- (void)colorEachWord:(NSString *)exid cell:(UITableViewCell *)cell exercise:(NSString *)exercise scoreHistory:(NSDictionary *)scoreHistory
{
    NSString *scoreString = [_exToScore objectForKey:exid];
    if (scoreString == nil) {
        cell.textLabel.text = exercise;
    }
    else {
        NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:exercise];
        
        if (scoreHistory == nil || ![scoreHistory isKindOfClass:[NSDictionary class]] || scoreHistory.count == 0) {
            [self colorWholeString:result scoreString:scoreString];
        }
        else {
            NSArray *words = [scoreHistory valueForKey:@"words"];
            if (words.count == 1) {
                [self colorWholeString:result scoreString:scoreString];
            }
            else {
                NSUInteger endToken = 0;
                int i = 0;
                
                // attempt to avoid "cant" - "can't" issue
                
                NSArray *tokens = [self getTokens:exercise];
                BOOL useToken = tokens.count == words.count;
                for (NSDictionary *entry in words) {
                    NSString *word   = [entry objectForKey:@"w"];
                    if ([word isEqualToString:@"<s>"] || [word isEqualToString:@"</s>"]) {
                        continue;
                    }
                    NSString *wscore = [entry objectForKey:@"s"];
                    float score = [wscore floatValue];
                    
                    NSString *token = useToken ? [tokens objectAtIndex:i++] : word;
                  // NSLog(@"token %@ score %@ vs %@",word,wscore,token);
                    
                    NSRange trange = [exercise rangeOfString:token options:NSCaseInsensitiveSearch range:NSMakeRange(endToken, exercise.length-endToken)];
                    
                    if (trange.length > 0) {
                        UIColor *color = [self getColor2:score];
                        
                        [result addAttribute:NSBackgroundColorAttributeName
                                       value:color
                                       range:trange];
                        endToken = trange.location+trange.length;
                    }
                    else {
                        NSLog(@"colorEachWord : huh? ERROR - can't find %@ in %@",word,exercise);
                    }
                }
            }
        }
        
        cell.textLabel.attributedText = result;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"WordListPrototype";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NSDictionary *jsonObject =[_jsonItems objectAtIndex:indexPath.row];
    
    NSString *exercise = [jsonObject objectForKey:@"fl"];
    NSString *englishPhrases = [jsonObject objectForKey:@"en"];
    NSString *exid = [jsonObject objectForKey:@"id"];
    NSArray *answers = [_exToHistory objectForKey:exid];
    NSDictionary *scoreHistory = [_exToJson objectForKey:exid];
  //  NSLog(@"Scores %@",scoreHistory);
    
    if (answers == nil || answers.count == 0) {
        cell.imageView.image = [UIImage imageNamed:@"questionIcon"];
    }
    else {
        for (NSString *correct in answers) {
          BOOL isCorrect = [correct isEqualToString:@"Y"];
          cell.imageView.image = [UIImage imageNamed:isCorrect ? @"checkmark32.png" : @"redx32.png"];
        }
    }
    
    [self colorEachWord:exid cell:cell exercise:exercise scoreHistory:scoreHistory];
    cell.detailTextLabel.text = englishPhrases;
    
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
    //  NSLog(@"tokens %@", all);
    
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

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    EAFRecoFlashcardController *flashcardController = [segue destinationViewController];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    NSInteger row = indexPath.row;
//    NSLog(@"Item Table - got seque row %ld %@ %@",(long)indexPath.row, _chapterTitle, _currentChapter );
 
    flashcardController.jsonItems = _jsonItems;
    flashcardController.index = row;
    flashcardController.language = _language;
    flashcardController.url = [self getURL];
    [flashcardController setTitle:[NSString stringWithFormat:@"%@ Chapter %@",([_language isEqualToString:@"CM"] ? @"Mandarin":_language),_currentChapter]];
    
    flashcardController.hasModel=_hasModel;
    flashcardController.chapterTitle = _chapterTitle;
    flashcardController.currentChapter = _currentChapter;
    flashcardController.unitTitle = _unitTitle;
    flashcardController.currentUnit = _unit;
    
    flashcardController.itemViewController = self;
    _notifyFlashcardController = flashcardController;
}

//
- (void)askServerForJson {
    _requestPending = true;
    NSString *baseurl = [NSString stringWithFormat:@"https://np.ll.mit.edu/npfClassroom%@/scoreServlet?request=chapterHistory&user=%ld&%@=%@&%@=%@", _language, _user, _unitTitle, _unit, _chapterTitle, _currentChapter];
    
    baseurl =[baseurl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    NSLog(@"askServerForJson url %@",baseurl);
    
    NSURL *url = [NSURL URLWithString:baseurl];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    [urlRequest setTimeoutInterval:10];

    [urlRequest setHTTPMethod: @"GET"];
    [urlRequest setValue:@"application/x-www-form-urlencoded"
      forHTTPHeaderField:@"Content-Type"];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:true];
    
   // [[Mint sharedInstance] leaveBreadcrumb:@"sendingAsyncItemController"];
    
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         if (error != nil) {
             NSLog(@"ItemTableViewController Got error %@",error);
             dispatch_async(dispatch_get_main_queue(), ^{
                 [self connection:nil didFailWithError:error];
             });
         }
         else {
             _responseData = data;
             [self performSelectorOnMainThread:@selector(connectionDidFinishLoading:)
                                    withObject:nil
                                 waitUntilDone:YES];
         }
     }];
}

- (BOOL)useJsonChapterData {
    NSLog(@"ITemTableViewController - useJsonChapterData --- num json %lu ",(unsigned long)_jsonItems.count);

    NSError * error;
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:_responseData
                          options:NSJSONReadingAllowFragments
                          error:&error];
    _requestPending = false;
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
        _exToJson    = [[NSMutableDictionary alloc] init];
        for (NSDictionary *entry in jsonArray) {
            NSString *ex = [entry objectForKey:@"ex"];
            NSDictionary *entryForID = [exToEntry objectForKey:ex];
            if (entryForID != nil) {
                [newOrder addObject:entryForID];
            }
            
            [_exToScore   setValue:[entry objectForKey:@"s"] forKey:ex];
            [_exToHistory setValue:[entry objectForKey:@"h"] forKey:ex];
            [_exToJson    setValue:[entry objectForKey:@"scoreJson"] forKey:ex];
        }
        
        if ([newOrder count] > 0) {
            _jsonItems = newOrder;
            if (_notifyFlashcardController != nil) {
                _notifyFlashcardController.jsonItems = _jsonItems;
            //    [_notifyFlashcardController respondToSwipe ];
            }
            NSLog(@"item table view : reload table ----------- ");
            
            [[self tableView] reloadData];
        }
    }

    [self performSelectorInBackground:@selector(cacheAudio:) withObject:_jsonItems];

    return true;
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // The request is complete and data has been received
    [self useJsonChapterData];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // The request has failed for some reason!
    // Check the error var
    NSLog(@"ItemTableViewController - Download content failed with %@",error);
    _requestPending = false;
    [[self tableView] reloadData];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];
}

@end
