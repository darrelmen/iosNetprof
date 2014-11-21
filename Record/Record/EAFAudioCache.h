//
//  EAFAudioCache.h
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 11/20/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EAFAudioCache : NSObject<NSURLConnectionDelegate>

@property NSArray *paths;
@property NSArray *rawPaths;
@property NSString *language;

@property NSMutableData *mp3Audio;
@property int itemIndex;

- (void) goGetAudio:(NSArray *)rawPaths paths:(NSArray *)ppaths language:(NSString *)lang;

@end
