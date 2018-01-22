//
//  MoreSelection.m
//  Record
//
//  Created by Zebin Xia on 5/30/17.
//  Copyright © 2017 MIT Lincoln Laboratory. All rights reserved.
//

#import "MoreSelection.h"

@interface MoreSelection ()

@end

@implementation MoreSelection

-(id)initWithLanguageIndex:(NSInteger )languageIndex withVoiceIndex:(NSInteger )voiceIndex{
    self = [super init];
    self.languageIndex = languageIndex;
    self.voiceIndex = voiceIndex;
    return self;
}

@end
