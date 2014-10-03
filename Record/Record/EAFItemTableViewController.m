//
//  EAFItemTableViewController.m
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 7/11/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import "EAFItemTableViewController.h"
#import "EAFExercise.h"
#import "EAFViewController.h"
//#import "EAFFlashcardViewController.h"

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
    
    self.items = [[NSMutableArray alloc] init];
    self.englishPhrases = [[NSMutableArray alloc] init];
    self.translitPhrases = [[NSMutableArray alloc] init];
    self.examples = [[NSMutableArray alloc] init];
    self.paths = [[NSMutableArray alloc] init];
    self.rawPaths = [[NSMutableArray alloc] init];
  //  NSArray *items =[_chapterToItems objectForKey:currentChapter];
    NSArray *items =_jsonItems;

    for (NSDictionary *object in items) {
        [_items addObject:[object objectForKey:@"fl"]];
        [_englishPhrases addObject:[object objectForKey:@"en"]];
        [_translitPhrases addObject:[object objectForKey:@"tl"]];
        [_examples addObject:[object objectForKey:@"ct"]];
        
        NSString *refPath = [object objectForKey:@"ref"];
        if (refPath) {
            refPath = [refPath stringByReplacingOccurrencesOfString:@".wav"
                                                 withString:@".mp3"];
            
            NSMutableString *mu = [NSMutableString stringWithString:refPath];
            [mu insertString:[self getURL] atIndex:0];
            [_paths addObject:mu];
            [_rawPaths addObject:refPath];
        }
        else {
            [_paths addObject:@"NO"];
            [_rawPaths addObject:@"NO"];
        }
    }
    
    _itemIndex = 0;
    [self getAudioForCurrentItem];
    
    //NSLog(@"viewDidLoad found '%@' = %ld",currentChapter,(unsigned long)self.items.count);

    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
    [self setTitle:[NSString stringWithFormat:@"%@ %@ %@",_language,chapterTitle,currentChapter]];
   
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(NSString *) getAudioDestDir:(NSString *) whichLanguage {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *destFileName = [NSString stringWithFormat:@"%@_audio",whichLanguage];
    return [documentsDirectory stringByAppendingPathComponent:destFileName];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

NSString *currentChapter;
NSString *chapterTitle = @"Chapter";

- (void)setChapter:(NSString *) chapter {
    currentChapter = chapter;
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
    return [self.items count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"WordListPrototype";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NSString *exercise = [self.items objectAtIndex:indexPath.row];
    cell.textLabel.text = exercise;
    cell.detailTextLabel.text = [self.englishPhrases objectAtIndex:indexPath.row];;
    
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
    
    EAFViewController *itemController = [segue destinationViewController];
   // EAFFlashcardViewController *itemController = [segue destinationViewController];

    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    NSInteger row = indexPath.row;
  //  NSLog(@"row %d",indexPath.row  );
    NSString *foreignLanguageItem = [self.items objectAtIndex:row];
    NSString *englishItem = [self.englishPhrases objectAtIndex:row];
    
    [itemController setForeignText:foreignLanguageItem];
    [itemController setEnglishText:englishItem];
    //[itemController setTranslitText:[self.translitPhrases objectAtIndex:row]];
  //  [itemController setExampleText:[self.examples objectAtIndex:row]];
    itemController.refAudioPath = [_paths objectAtIndex:row];
    itemController.rawRefAudioPath = [_rawPaths objectAtIndex:row];
    itemController.index = row;
    itemController.items = [self items];
    itemController.language = _language;
    itemController.englishWords = [self englishPhrases];
    itemController.translitWords = [self translitPhrases];
   // itemController.examples = [self examples];
    itemController.paths = _paths;
    itemController.rawPaths = _rawPaths;
    itemController.url = [self getURL];
    [itemController setTitle:[NSString stringWithFormat:@"%@ Chapter %@",_language,currentChapter]];
    [itemController setHasModel:_hasModel];
}

// see getAudioForCurrentItem
- (NSString *)getCurrentCachePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *audioDir = [NSString stringWithFormat:@"%@_audio",_language];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:audioDir];
    NSString *rawRefAudioPath = [_rawPaths objectAtIndex: _itemIndex];
    NSString *destFileName = [filePath stringByAppendingPathComponent:rawRefAudioPath];
    return destFileName;
}

// go and get ref audio per item, make individual requests -- quite fast
- (void)getAudioForCurrentItem
{
    NSString *destFileName = [self getCurrentCachePath];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:destFileName];
    
    if (fileExists || [destFileName hasSuffix:@"NO"]) {
        [self checkNextAudioFile];
    }
    else {
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[_paths objectAtIndex:_itemIndex]]];
        
        // Create url connection and fire request
        NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:TRUE];
    }
}

#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // A response has been received, this is where we initialize the instance var you created
    // so that we can append data to it in the didReceiveData method
    // Furthermore, this method is called each time there is a redirect so reinitializing it
    // also serves to clear it
    
    _mp3Audio = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // NSLog(@"didReceiveData ----- ");
    
    // Append the new data to the instance variable you declared
    [_mp3Audio appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
}

- (void)checkNextAudioFile {
    if (_itemIndex < _paths.count-1) {
        _itemIndex++;
        [self getAudioForCurrentItem];
    }
    else {
        NSLog(@"%d downloads complete.",_itemIndex);
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSString *destFileName = [self getCurrentCachePath];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];

   // NSLog(@"writing to      %@",destFileName);
    
    NSString *parent = [destFileName stringByDeletingLastPathComponent];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:parent]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:parent withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    [_mp3Audio writeToFile:destFileName atomically:YES];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:destFileName]) {
        NSLog(@"huh? can't find     %@",destFileName);
    }
    
    [self checkNextAudioFile];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];
}


@end
