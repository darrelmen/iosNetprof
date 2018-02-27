//
//  EAFFlashcardViewController.h
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 7/22/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface EAFFlashcardViewController : UIViewController

@property (strong, nonatomic) IBOutlet UILabel *foreignLanguage;
@property (strong, nonatomic) IBOutlet UILabel *english;

-(void) setForeignText:(NSString *)foreignLang;
-(void) setEnglishText:(NSString *)english;

@property NSString *language;
@property (strong, nonatomic) IBOutlet NSString *refAudioPath;
@property (strong, nonatomic) IBOutlet NSString *rawRefAudioPath;
@property AVPlayer *player;

@property unsigned long index;
@property NSArray *ids;
@property NSArray *items;
@property NSArray *englishWords;
@property NSArray *translitWords;
@property NSArray *paths;
@property NSArray *rawPaths;

@property (strong, nonatomic) IBOutlet UIView *cardBackground;
@property (strong, nonatomic) IBOutlet UISwitch *shuffleSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *audioOnSelector;
@property BOOL hasModel;
@property NSString *url;

@end
