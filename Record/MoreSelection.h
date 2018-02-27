//
//  MoreSelection.h
//  Record
//
//  Created by Zebin Xia on 5/30/17.
//  Copyright © 2017 MIT Lincoln Laboratory. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MoreSelection : NSObject

@property NSInteger languageIndex;
@property NSInteger voiceIndex;

@property BOOL hasTwoGenders;
@property BOOL hasMaleReg;
@property BOOL hasMaleSlow;
@property BOOL hasFemaleReg;
@property BOOL hasFemaleSlow;

@property BOOL isAudioSelected;
@property NSString *identityRestorationID;

-(id)initWithLanguageIndex:(NSInteger )languageIndex withVoiceIndex:(NSInteger )voiceIndex;

@end
