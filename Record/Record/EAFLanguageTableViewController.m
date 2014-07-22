//
//  EAFLanguageTableViewController.m
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 7/16/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import "EAFLanguageTableViewController.h"
#import "EAFChapterTableViewController.h"
#import "SSZipArchive.h"

@interface EAFLanguageTableViewController ()

@end

@implementation EAFLanguageTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    return self;
}

NSArray *languages;
int languageIndex = 0;

- (void)viewDidLoad
{
    [super viewDidLoad];
    languages = [NSArray arrayWithObjects:@"Dari", @"English",@"Farsi", @"MSA", @"Pashto1", @"Pashto2", @"Pashto3", @"Urdu",  nil];
 
    // begin process of downloading audio...
    [self getAudioForCurrentLanguage];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)getAudioForCurrentLanguage
{
    NSString * dest = [self getAudioDestDir:languageIndex];
    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:dest];
    if (!fileExists) {
        NSString *langToGet = [languages objectAtIndex:languageIndex];
        NSLog(@"getting audio for %@",langToGet);
        NSString *baseurl = [NSString stringWithFormat:@"https://np.ll.mit.edu/npfClassroom%@/downloadAudio", langToGet];
        
        // Create the request.
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:baseurl]];
        
        // Create url connection and fire request
        NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    }
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
    return languages.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    static NSString *CellIdentifier = @"LanguageListPrototypeCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    cell.textLabel.text =  [languages objectAtIndex:indexPath.row];
    
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

#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // A response has been received, this is where we initialize the instance var you created
    // so that we can append data to it in the didReceiveData method
    // Furthermore, this method is called each time there is a redirect so reinitializing it
    // also serves to clear it
    
    NSLog(@"didReceiveResponse ----- ");

    _audioZip = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
   // NSLog(@"didReceiveData ----- ");

    // Append the new data to the instance variable you declared
    [_audioZip appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *destDir = [self getAudioDestDir:languageIndex];
    [[NSFileManager defaultManager] removeItemAtPath:destDir error:nil];
    
    NSString *fileName = [NSString stringWithFormat:@"%@_audio.zip",[languages objectAtIndex:languageIndex]];
    NSString *audioZip = [documentsDirectory stringByAppendingPathComponent:fileName];

    NSLog(@"writing to %@",audioZip);
    [_audioZip writeToFile:audioZip atomically:YES];
    
    // The request is complete and data has been received
    // You can parse the stuff in your instance variable now
    [SSZipArchive unzipFileAtPath:audioZip toDestination:destDir];
    NSLog(@"unzip  to %@",destDir);
    
    if (languageIndex < languages.count-1) {
        languageIndex++;
        [self getAudioForCurrentLanguage];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"All audio downloaded."
                                                        message: @"All mp3 files downloaded."
                                                       delegate: nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

-(NSString *) getAudioDestDir:(int) whichLanguage {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *destFileName = [NSString stringWithFormat:@"%@_audio",[languages objectAtIndex:whichLanguage]];
    return [documentsDirectory stringByAppendingPathComponent:destFileName];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // The request has failed for some reason!
    // Check the error var
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    EAFChapterTableViewController *chapterController = [segue destinationViewController];
    
    //NSLog(@"selected %@",selectedRow);
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
 //   NSLog(@"language row %ld",indexPath.row  );
    NSString *tappedItem = [languages objectAtIndex:indexPath.row];
    
    [chapterController setTitle:tappedItem];
    [chapterController setLanguage:tappedItem];
}


@end
