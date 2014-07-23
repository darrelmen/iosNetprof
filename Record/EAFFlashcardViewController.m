//
//  EAFFlashcardViewController.m
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 7/22/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import "EAFFlashcardViewController.h"

@interface EAFFlashcardViewController ()

@end

@implementation EAFFlashcardViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSLog(@"view did load with %@",ffl);
    
    _foreignLanguage.text = ffl;
    _english.text =fen;
    [_foreignLanguage setHidden:YES];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

BOOL playAudio = TRUE;

- (IBAction)audioValueChange:(id)sender {
   BOOL value = [_audioOnSelector isOn];
    
    NSLog(@"audioValueChange Got value %hhd",value);
}

- (IBAction)gotUpSwipe:(id)sender {
    //NSLog(@"got up swipe");
    if (_foreignLanguage.isHidden) {
        [_foreignLanguage setHidden:NO];
        [_english setHidden:YES];
        if ([_audioOnSelector isOn]) {
            [self playRefAudio:nil];
        }
    }
    else {
        [_foreignLanguage setHidden:YES];
        [_english setHidden:NO];
    }
}
- (IBAction)gotDownSwipe:(id)sender {
   // NSLog(@"got down swipe");

    [self gotUpSwipe:nil];
}
- (IBAction)gotLeftSwipe:(id)sender {
   // NSLog(@"got left swipe");
    _index++;
    if (_index == _items.count) _index = 0;
    
    [self respondToSwipe];
}

- (IBAction)gotRightSwipe:(id)sender {
  //  NSLog(@"got right swipe");
    _index--;
    if (_index == -1) _index = _items.count  -1UL;
    
    [self respondToSwipe];
}
- (IBAction)shuffleChange:(id)sender {
    
    NSLog(@"got shuffleChange");

    BOOL value = [_shuffleSwitch isOn];
    if (value) {
        [self shuffle];
    }
    else {
        _items = originalItems;
        _englishWords = originalEnglish;
        _rawPaths = originalPaths;
    }
    [self respondToSwipe];
}

NSArray *originalItems;
NSArray *originalEnglish;
NSArray *originalPaths;

- (void) shuffle {
    NSMutableArray *newArray = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < _items.count; i++) {
        [newArray addObject:[NSNumber numberWithInteger:i]];
    }
    
    NSUInteger count = [newArray count];
    for (NSUInteger i = 0; i < count; ++i) {
        // Select a random element between i and end of array to swap with.
        NSInteger remainingCount = count - i;
        NSInteger exchangeIndex = i + arc4random_uniform(remainingCount);
        [newArray exchangeObjectAtIndex:i withObjectAtIndex:exchangeIndex];
    }
    
    NSMutableArray *newItems   = [NSMutableArray arrayWithArray:_items];
    NSMutableArray *newEnglish = [NSMutableArray arrayWithArray:_englishWords];
    NSMutableArray *newPaths   = [NSMutableArray arrayWithArray:_rawPaths];

   // NSLog(@"size %d %d %d",newItems.count,newEnglish.count,newPaths.count);
    
    for (NSUInteger i = 0; i < _items.count; i++) {
        int j = [[newArray objectAtIndex:i] integerValue];
        
        [newItems exchangeObjectAtIndex:i withObjectAtIndex:j];
        [newEnglish exchangeObjectAtIndex:i withObjectAtIndex:j];
        [newPaths exchangeObjectAtIndex:i withObjectAtIndex:j];
    }
    
    originalItems = _items;
    originalEnglish = _englishWords;
    originalPaths = _rawPaths;
    
    _items = newItems;
    _englishWords = newEnglish;
    _rawPaths = newPaths;
    
    _index = 0;
}


// so if we swipe while the ref audio is playing, remove the observer that will tell us when it's complete
- (void)respondToSwipe {
    _refAudioPath =[_paths objectAtIndex:_index];
    
    NSString *flAtIndex = [_items objectAtIndex:_index];
    NSString *enAtIndex = [_englishWords objectAtIndex:_index];
    [_foreignLanguage setText:flAtIndex];
    [_english setText:enAtIndex];
    _rawRefAudioPath =[_rawPaths objectAtIndex:_index];
    ffl = flAtIndex;
    fen = enAtIndex;

    if (!_foreignLanguage.isHidden) {
        if ([_audioOnSelector isOn]) {
            [self playRefAudio:nil];
        }
    }
}

// look for local file with mp3 and use it if it's there.
- (IBAction)playRefAudio:(id)sender {
    NSURL *url = [NSURL URLWithString:_refAudioPath];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *audioDir = [NSString stringWithFormat:@"%@_audio",_language];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:audioDir];
    
    NSString *destFileName = [filePath stringByAppendingPathComponent:_rawRefAudioPath];
    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:destFileName];
    if (fileExists) {
        NSLog(@"playRefAudio Raw URL %@", _rawRefAudioPath);
        NSLog(@"using local url %@",destFileName);
        url = [[NSURL alloc] initFileURLWithPath: destFileName];
    }
    else {
        NSLog(@"can't find local url %@",destFileName);
        NSLog(@"playRefAudio URL     %@", _refAudioPath);
    }
    NSString *PlayerStatusContext;
    
    if (_player) {
        
        @try {
            [_player removeObserver:self forKeyPath:@"status"];
        }
        @catch (NSException *exception) {
            NSLog(@"observeValueForKeyPath : got exception %@",exception.description);
        }
    }
    
    UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
    AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
    AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,sizeof (audioRouteOverride),&audioRouteOverride);
    
    _player = [AVPlayer playerWithURL:url];
    
    [_player addObserver:self forKeyPath:@"status" options:0 context:&PlayerStatusContext];
    //_playRefAudioButton.enabled = NO;
}

// So this is more complicated -- we have to wait until the mp3 has arrived from the server before we can play it
// we remove the observer, or else we will later get a message when the player discarded
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    //NSLog(@" observeValueForKeyPath %@",keyPath);
    
    if (object == _player && [keyPath isEqualToString:@"status"]) {
        if (_player.status == AVPlayerStatusReadyToPlay) {
            NSLog(@" audio ready so playing...");
            
            [_player play];
            
            @try {
                [_player removeObserver:self forKeyPath:@"status"];
            }
            @catch (NSException *exception) {
                NSLog(@"observeValueForKeyPath : got exception %@",exception.description);
            }
            
        } else if (_player.status == AVPlayerStatusFailed) {
            // something went wrong. player.error should contain some information
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Connection problem" message: @"Couldn't play audio file." delegate: nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            
            NSLog(@"player status failed");
            
            [_player removeObserver:self forKeyPath:@"status"];
        }
    }
    else {
        NSLog(@"ignoring value... %@",keyPath);
    }
}


NSString *ffl = @"";
NSString *fen = @"";

-(void) setForeignText:(NSString *)foreignLangText
{
    ffl = foreignLangText;
}

-(void) setEnglishText:(NSString *)english
{
    fen = english;
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
