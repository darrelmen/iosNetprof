//
//  EAFAppDelegate.h
//  Record
//
//  Created by Ferme, Elizabeth - 0553 - MITLL on 4/2/14.
//  Copyright (c) 2011-2016 Massachusetts Institute of Technology, Lincoln Laboratory
//

#import <UIKit/UIKit.h>
//#import <SplunkMint-iOS/SplunkMint-iOS.h>
#import "EAFRecoFlashcardController.h"

@interface EAFAppDelegate : UIResponder <UIApplicationDelegate>

// required!
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) EAFRecoFlashcardController *recoController;


@property (strong, nonatomic) NSDictionary *nameToURL;

@end
