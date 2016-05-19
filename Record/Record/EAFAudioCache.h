//
//  EAFAudioCache.h
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 11/20/14.
//  Copyright (c) 2011-2016 Massachusetts Institute of Technology, Lincoln Laboratory
//

#import <Foundation/Foundation.h>

@interface EAFAudioCache : NSObject

@property NSString *language;
@property NSData *mp3Audio;

- (void) goGetAudio:(NSArray *)rawPaths paths:(NSArray *)ppaths language:(NSString *)lang;
- (void) cancelAllOperations;

@end
