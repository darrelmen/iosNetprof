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
    self.paths = [[NSMutableArray alloc] init];
    NSArray *items =[_chapterToItems objectForKey:currentChapter];
    
    for (NSDictionary *object in items) {
        [_items addObject:[object objectForKey:@"fl"]];
        [_englishPhrases addObject:[object objectForKey:@"en"]];
        [_translitPhrases addObject:[object objectForKey:@"tl"]];
        
        NSString *refPath = [object objectForKey:@"ref"];
        if (refPath) {
            NSMutableString *mu = [NSMutableString stringWithString:refPath];
            [mu insertString:[self getURL] atIndex:0];
            [_paths addObject:mu];
        }
        else {
            [_paths addObject:@"NO"];
        }
    }
    
    NSLog(@"viewDidLoad found '%@' = %ld",currentChapter,(unsigned long)self.items.count);

    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
    [self setTitle:[NSString stringWithFormat:@"%@ Chapter %@",_language,currentChapter]];
    
    
  //  UIBarButtonItem *customBarItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:self action:@selector(popView)];
    
   // self.navigationItem.leftBarButtonItem = customBarItem;
  //  [self.navigationItem.leftBarButtonItem setTitle:[NSString stringWithFormat:@"Chapter %@",currentChapter]];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

NSString *currentChapter;

- (void)setChapter:(NSString *) chapter {
    currentChapter = chapter;
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
    
    // EAFExercise *exercise = [self.items objectAtIndex:indexPath.row];
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
    
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
  //  NSLog(@"row %d",indexPath.row  );
    NSString *foreignLanguageItem = [self.items objectAtIndex:indexPath.row];
    NSString *englishItem = [self.englishPhrases objectAtIndex:indexPath.row];
    
    [itemController setForeignText:foreignLanguageItem];
    [itemController setEnglishText:englishItem];
    [itemController setTranslitText:[self.translitPhrases objectAtIndex:indexPath.row]];
    itemController.refAudioPath = [_paths objectAtIndex:indexPath.row];
    itemController.index = indexPath.row;
    itemController.items = [self items];
    itemController.englishWords = [self englishPhrases];
    itemController.translitWords = [self translitPhrases];
    itemController.paths = _paths;
    itemController.url = [self getURL];
    [itemController setTitle:[NSString stringWithFormat:@"%@ Chapter %@",_language,currentChapter]];

    //[itemController setTitle:<#(NSString *)#>]
}


@end
