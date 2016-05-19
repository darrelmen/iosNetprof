//
//  EAFAudioCache.h
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 11/20/14.
//  Copyright (c) 2011-2016 Massachusetts Institute of Technology, Lincoln Laboratory
//

#import <Foundation/Foundation.h>

@interface EAFEventPoster : NSObject<NSURLConnectionDelegate>

@property NSMutableData *response;

- (id) initWithURL:(NSString *) url;
- (void) postEvent:(NSString *)context exid:(NSString *)exid widget:(NSString *)widget  widgetType:(NSString *)widgetType ;
- (void) postRT:(NSString *)resultID rtDur:(NSString *)rtDur;
- (void) setURL:(NSString *) url;
@end
