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
//  EAFItemTableViewController.m
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 7/11/14.
//  Copyright (c) 2011-2016 Massachusetts Institute of Technology, Lincoln Laboratory
//

#import "EAFItemTableViewController.h"
#import "EAFAudioCache.h"
#import "EAFRecoFlashcardController.h"
#import "SSKeychain.h"
#import "UIColor_netprofColors.h"

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

@property unsigned long checkMarkPercentage;
@property unsigned long questionIconPercentage;
@property unsigned long redXPercentage;
@property UIButton *sortBtn;

@property UIButton *checkMarkBtn;
@property UIButton *redXBtn;

@property NSArray *temp_jsonItems;

@property unsigned long lessonTotalItems;

@property (strong, nonatomic) UISearchController *searchController;
@end

@implementation EAFItemTableViewController

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
                [mu insertString:_url atIndex:0];
                [paths addObject:mu];
                [rawPaths addObject:refPath];
            }
        }
    }
    
    //   NSLog(@"ItemTableViewController.cacheAudio Got get audio -- %@ ",_audioCache);
    [_audioCache goGetAudio:rawPaths paths:paths language:_language];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _temp_jsonItems = [[NSMutableArray alloc] initWithArray:_jsonItems];;
    _audioCache = [[EAFAudioCache alloc] init];
    //  NSLog(@"viewDidLoad made audio cache, url %@ ",_url );
    //  NSLog(@"viewDidLoad - item table controller - %@, count = %lu", _hasModel?@"YES":@"NO",(unsigned long)_jsonItems.count);
    
    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
    [self setTitle:[NSString stringWithFormat:@"%@ %@ %@",_language,_chapterTitle,_currentChapter]];
    
    _user = [[SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"userid"] intValue];
    
    //   [self createBtnAndLabelForHeaderView];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(OrientationChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    _lessonTotalItems = _jsonItems.count;
    
}

//- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
//{
//    NSString *searchString = searchController.searchBar.text;
//    [self searchForText:searchString scope:searchController.searchBar.selectedScopeButtonIndex];
//    [self.tableView reloadData];
//}

-(void)OrientationChange:(NSNotification*)notification
{
    [self createBtnAndLabelForHeaderView];
    //    UIDeviceOrientation Orientation=[[UIDevice currentDevice]orientation];
    //
    //    if(Orientation==UIDeviceOrientationLandscapeLeft || Orientation==UIDeviceOrientationLandscapeRight)
    //    {
    //        [self createBtnAndLabelForHeaderView];
    //    }
    //    else if(Orientation==UIDeviceOrientationPortrait)
    //    {
    //         [self createBtnAndLabelForHeaderView];    }
}

- (void)createBtnAndLabelForHeaderView{
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 100)];
    //    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    //    self.searchController.searchResultsUpdater = self;
    //    self.searchController.dimsBackgroundDuringPresentation = NO;
    //    self.searchController.searchBar.delegate = self;
    //    [headerView addSubview:self.searchController.searchBar];
    //    self.definesPresentationContext = YES;
    
    UIFont *font;
    if([self isiPhone]){
        font = [UIFont boldSystemFontOfSize:24.0f];
    } else {
        font = [UIFont boldSystemFontOfSize:32.0f];
    }
    
    
    NSDictionary *attributes = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
    
    
    //  [[UISegmentedControl appearance] setTintColor:[UIColor grayColor]];
    UISegmentedControl *segmentedCtrlForList= [[UISegmentedControl alloc] initWithFrame:CGRectMake(5, 5, self.view.frame.size.width - 10, 45)];
    segmentedCtrlForList.backgroundColor = [UIColor npLightBlue];
    [segmentedCtrlForList setTitleTextAttributes:attributes forState:UIControlStateNormal];
    [segmentedCtrlForList insertSegmentWithImage:[UIImage imageNamed:@"checkmark32.png"] atIndex:0 animated:NO];
    [[segmentedCtrlForList.subviews objectAtIndex:0] setTintColor:[UIColor greenColor]];
    
    [segmentedCtrlForList insertSegmentWithImage:[UIImage imageNamed:@"redx32.png"] atIndex:1 animated:NO];
    [[segmentedCtrlForList.subviews objectAtIndex:1] setTintColor:[UIColor redColor]];
    
    [segmentedCtrlForList
     insertSegmentWithImage:[UIImage imageNamed:@"questionIcon1.png"]  atIndex:2 animated:NO] ;
    [segmentedCtrlForList insertSegmentWithTitle:@"All" atIndex:3 animated:NO];
    [segmentedCtrlForList setSelectedSegmentIndex:3];
    segmentedCtrlForList.tintColor = [UIColor npDarkBlue];
    [segmentedCtrlForList addTarget:self action:@selector(filterBtnTapped:) forControlEvents:UIControlEventValueChanged];
    
    segmentedCtrlForList.layer.borderWidth = 1.0f;
    segmentedCtrlForList.layer.borderColor = [UIColor npDarkBlue].CGColor;
    segmentedCtrlForList.layer.cornerRadius = 5.0;
    segmentedCtrlForList.clipsToBounds = YES;
    
    
    [headerView addSubview:segmentedCtrlForList];
    
    UISegmentedControl * segmentedCtrlForNumAndSort = [[UISegmentedControl alloc] initWithFrame:CGRectMake(5, 50, self.view.frame.size.width - 10 - (self.view.frame.size.width - 10)/4, 45)];
    
    [segmentedCtrlForNumAndSort setTitleTextAttributes:attributes forState:UIControlStateNormal];
    
    [segmentedCtrlForNumAndSort insertSegmentWithTitle:[NSString stringWithFormat:@"%lu%%",_checkMarkPercentage] atIndex:0 animated:NO];
    [segmentedCtrlForNumAndSort setEnabled:NO forSegmentAtIndex:0];
    [segmentedCtrlForNumAndSort insertSegmentWithTitle:[NSString stringWithFormat:@"%lu%%",_redXPercentage] atIndex:1 animated:NO];
    
    [segmentedCtrlForNumAndSort setEnabled:NO forSegmentAtIndex:1];
    [segmentedCtrlForNumAndSort insertSegmentWithTitle:[NSString stringWithFormat:@"%lu%%",_questionIconPercentage] atIndex:2 animated:NO];
    [segmentedCtrlForNumAndSort setEnabled:NO forSegmentAtIndex:2];
//    [segmentedCtrlForNumAndSort insertSegmentWithImage:[UIImage imageNamed:@"sort.png"] atIndex:3 animated:NO];
    segmentedCtrlForNumAndSort.backgroundColor = [UIColor whiteColor];
    segmentedCtrlForNumAndSort.tintColor = [UIColor whiteColor];
    //[segmentedCtrlForNumAndSort setTitleColor:[UIColor npDarkBlue]];
    [segmentedCtrlForNumAndSort setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor npDarkBlue]}
                                forState:UIControlStateDisabled];
    segmentedCtrlForNumAndSort.layer.borderWidth = 1.0f;
   //segmentedCtrlForList.layer.borderColor = [UIColor npDarkBlue].CGColor;
    segmentedCtrlForNumAndSort.layer.borderColor = [UIColor whiteColor].CGColor;
    segmentedCtrlForNumAndSort.layer.cornerRadius = 5.0;
    segmentedCtrlForNumAndSort.clipsToBounds = NO;
    _sortBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _sortBtn.frame = CGRectMake(self.view.frame.size.width - 5 - (self.view.frame.size.width - 10)/4, 50, (self.view.frame.size.width - 10)/4, 45);
//    [_sortBtn setImage:[UIImage imageNamed:@"sort_big.png"] forState:UIControlStateNormal];
     [_sortBtn setImage:[[UIImage imageNamed:@"ZtoA.png"]  imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
     [_sortBtn setImage:[[UIImage imageNamed:@"AtoZ.png"]  imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateSelected];

    [[_sortBtn layer] setBorderWidth:1.0f];
    [[_sortBtn layer] setBorderColor:[UIColor npDarkBlue].CGColor];
    _sortBtn.backgroundColor = [UIColor npLightBlue];
    _sortBtn.tintColor = [UIColor npDarkBlue];
    _sortBtn.layer.cornerRadius = 5.0;
    _sortBtn.clipsToBounds = YES;
    _sortBtn.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
    [_sortBtn addTarget:self action:@selector(sortBtnTapped:) forControlEvents:UIControlEventTouchUpInside];
   
    [headerView addSubview:segmentedCtrlForNumAndSort];
    [headerView addSubview:_sortBtn];

    self.tableView.tableHeaderView = headerView;
}

- (void)sortBtnTapped:(id)sender{
    
    [sender tag];
    
    NSSortDescriptor *leadNameDescriptor;
    _sortBtn.selected = !_sortBtn.selected;
    if(_sortBtn.selected){
        leadNameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"en" ascending:YES selector:@selector(localizedStandardCompare:)];
    } else {
        leadNameDescriptor = [[NSSortDescriptor alloc]initWithKey:@"en" ascending:NO selector:@selector(localizedStandardCompare:)];
    }
    
    NSArray *sortDescriptor = [NSArray arrayWithObject:leadNameDescriptor];
    NSArray *sortedArray = [_jsonItems sortedArrayUsingDescriptors:sortDescriptor];
    _jsonItems = [[NSMutableArray alloc] initWithArray:sortedArray];
    
    [[self tableView] reloadData];
}

- (void)filterBtnTapped:(UISegmentedControl *)segment{
    
    _jsonItems = _temp_jsonItems;
    NSMutableArray *checkMarkArray = [[NSMutableArray alloc] init];
    NSMutableArray *redXArray = [[NSMutableArray alloc] init];
    NSMutableArray *questionMarkArray = [[NSMutableArray alloc] init];
    for(NSDictionary *entry in _jsonItems){
        
        NSString *exid = [entry objectForKey:@"id"];
        NSArray *answers = [_exToHistory objectForKey:exid];
        
        if(answers != nil && answers.count != 0){
            BOOL isCorrect;
            BOOL isIncorrect;
            for(NSString *correct in answers){
                isCorrect = [correct isEqualToString:@"Y"];
                isIncorrect = [correct isEqualToString:@"N"];
            }
            if(isCorrect){
                [checkMarkArray addObject:entry];
            } else if(isIncorrect){
                [redXArray addObject:entry];
            }
        } else {
            [questionMarkArray addObject:entry];
        }
    }
    
    if(segment.selectedSegmentIndex == 0){
        _jsonItems = checkMarkArray;
    } else if(segment.selectedSegmentIndex == 1){
        _jsonItems = redXArray;
    } else if(segment.selectedSegmentIndex == 2){
        _jsonItems = questionMarkArray;
    } else {
        _jsonItems = _temp_jsonItems;
        //   NSLog(@"TOTALLLLLLL--- %lu", _temp_jsonItems.count);
    }
    
    [[self tableView] reloadData];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    NSLog(@"ItemViewController : viewWillDisappear -- cancelling %@",_audioCache);
    [_audioCache cancelAllOperations];
    [super viewWillDisappear:animated];
}

-(void)viewWillAppear:(BOOL)animated {
    NSLog(@"ItemViewController : viewWillAppear ");
    [super viewWillAppear:animated];
    [self askServerForJson];
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
        NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:[self trim:exercise]];
        
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
                
                // NSLog(@"for %@ got tokens %@",exercise,tokens);
                //  NSLog(@"for words %lu count ",(unsigned long)tokens.count);
                
                if (tokens.count == 1 && words.count > 0) {
                    NSDictionary *entry = [words objectAtIndex:0];
                    NSString *wscore = [entry objectForKey:@"s"];
                    float score = [wscore floatValue];
                    UIColor *color = [self getColor2:score];
                    
                    [result addAttribute:NSBackgroundColorAttributeName
                                   value:color
                                   range:NSMakeRange(0, result.length)];
                }
                else {
                    for (NSDictionary *entry in words) {
                        NSString *word   = [entry objectForKey:@"w"];
                        if ([word isEqualToString:@"<s>"] || [word isEqualToString:@"</s>"]) {
                            continue;
                        }
                        NSString *wscore = [entry objectForKey:@"s"];
                        float score = [wscore floatValue];
                        
                        NSString *token = useToken ? [tokens objectAtIndex:i++] : word;
                        //    NSLog(@"token %@ score %@ vs %@",word,wscore,token);
                        
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
        }
        
        cell.textLabel.attributedText = result;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"WordListPrototype";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    NSDictionary *jsonObject=[_jsonItems objectAtIndex:indexPath.row];
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
            //   NSLog(@"tableView  : history %@", scoreHistory);
            //   NSLog(@"tableView  : exid %@ score %@",  exid,[_exToScore objectForKey:exid]);
            cell.imageView.image = [UIImage imageNamed:isCorrect ? @"checkmark32.png" : @"redx32.png"];
        }
    }
    
    [self colorEachWord:exid cell:cell exercise:exercise scoreHistory:scoreHistory];
    cell.detailTextLabel.text = englishPhrases;
    
    return cell;
}

- (NSString *)trim:(NSString *)untrimedToken {
    return [untrimedToken stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

-(NSArray *)getTokens:(NSString *)sentence {
    NSMutableArray * all = [[NSMutableArray alloc] init];
    NSError *error = nil;
    NSString *regexPattern = @"[\\?\\.,-\\/#!$%\\^&\\*;:{}=\\-_`~()]";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexPattern options:NSRegularExpressionCaseInsensitive error:&error];
    sentence = [regex stringByReplacingMatchesInString:sentence options:0 range:NSMakeRange(0, [sentence length]) withTemplate:@" "];
    
    for (NSString *untrimedToken in [sentence componentsSeparatedByString:@" "]) { // split on spaces
        NSString *token;
        token = [self trim:untrimedToken];
        
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


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    EAFRecoFlashcardController *flashcardController = [segue destinationViewController];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    NSInteger row = indexPath.row;
    NSLog(@"Item Table - got seque row %ld %@ %@ url %@",(long)indexPath.row, _chapterTitle, _currentChapter, _url );
    
    flashcardController.url = _url;
    flashcardController.isRTL = _isRTL;
    flashcardController.jsonItems = _jsonItems;
    flashcardController.index = row;
    flashcardController.language = _language;
 
    flashcardController.projectLanguage = _projectLanguage;
    [flashcardController setTitle:[NSString stringWithFormat:@"%@ %@ %@",_language,_chapterTitle, _currentChapter]];
    
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
    NSString *baseurl = [NSString stringWithFormat:@"%@scoreServlet?request=chapterHistory&user=%ld&%@=%@&%@=%@", _url, _user, _unitTitle, _unit, _chapterTitle, _currentChapter];
    
    baseurl =[baseurl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSLog(@"ItemViewController askServerForJson url %@",baseurl);
    
    NSURL *url = [NSURL URLWithString:baseurl];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    [urlRequest setTimeoutInterval:10];
    
    [urlRequest setHTTPMethod: @"GET"];
    [urlRequest setValue:@"application/x-www-form-urlencoded"
      forHTTPHeaderField:@"Content-Type"];
    
    [urlRequest setValue:[_projid stringValue] forHTTPHeaderField:@"projid"];
    NSLog(@"ItemViewController projid = %@",_projid);
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:true];
    
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         if (error != nil) {
             NSLog(@"ItemTableViewController Got error %@",error);
             dispatch_async(dispatch_get_main_queue(), ^{
                 [self connection:nil didFailWithError:error];
             });
         }
         else {
             //NSLog(@"ItemTableViewController Got normal resp");
             _responseData = data;
             [self performSelectorOnMainThread:@selector(connectionDidFinishLoading:)
                                    withObject:nil
                                 waitUntilDone:YES];
         }
     }];
}

- (BOOL)useJsonChapterData {
    NSLog(@"ItemTableViewController - useJsonChapterData --- num json %lu ",(unsigned long)_jsonItems.count);

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
    
    //NSLog(@"useJsonChapterData resp %@",_responseData);
    //NSLog(@"useJsonChapterData resp 2 %@",json);
    
    NSMutableDictionary *exToEntry = [[NSMutableDictionary alloc] init];
    
    for (NSDictionary *entry in _jsonItems) {
        NSString *ex = [entry objectForKey:@"id"];
        [exToEntry setObject:entry forKey:ex];
    }
    
    NSMutableArray *newOrder = [[NSMutableArray alloc] init];
    
    NSArray *jsonArray = [json objectForKey:@"scores"];
    NSString *lastCorrect = [json objectForKey:@"lastCorrect"];
    NSString *lastIncorrect = [json objectForKey:@"lastIncorrect"];
    NSNumberFormatter * formatter = [[NSNumberFormatter alloc] init];
    unsigned long checkMarkTotal = [[formatter numberFromString:lastCorrect] unsignedLongValue];
    unsigned long redXTotal = [[formatter numberFromString:lastIncorrect] unsignedLongValue];
    unsigned long questionIconTotal = (unsigned long)_lessonTotalItems - (checkMarkTotal + redXTotal);
    _checkMarkPercentage = (roundf) (100 * ((float)checkMarkTotal/(float)(_lessonTotalItems)));
    
    _redXPercentage = (roundf)(100 * ((float)redXTotal/(float)_lessonTotalItems));
    _questionIconPercentage = (roundf)(100 * ((float)questionIconTotal/(float)_lessonTotalItems));
    if (_checkMarkPercentage + _redXPercentage + _questionIconPercentage<100){
        if(checkMarkTotal!=0) {_checkMarkPercentage=_checkMarkPercentage+1;
        }else if (redXTotal!=0){ _redXPercentage =_redXPercentage +1;
        }
    }
    if (_checkMarkPercentage + _redXPercentage + _questionIconPercentage>100){
        if(checkMarkTotal!=0) {_checkMarkPercentage=_checkMarkPercentage-1;
        }else if (redXTotal!=0){ _redXPercentage =_redXPercentage -1;
        }
    }
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
            else {
                NSLog(@"WARN : item table view : nothing for %@ ", ex);
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
 
//            NSLog(@"item table view : reload table ----------- ");
            
            [[self tableView] reloadData];
        }
        else {
            NSLog(@"item table view : NOT reloading table ----------- ");
          }
    }
    
    [self performSelectorInBackground:@selector(cacheAudio:) withObject:_jsonItems];
    //  [self createBtnAndLabelForHeaderView];
    return true;
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // The request is complete and data has been received
    [self useJsonChapterData];
    [self createBtnAndLabelForHeaderView];
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

- (BOOL)isiPhone
{
    return [[UIDevice currentDevice].model rangeOfString:@"iPhone"].location != NSNotFound;
}

- (BOOL)isiPad
{
    return ![self isiPhone];
}

@end

