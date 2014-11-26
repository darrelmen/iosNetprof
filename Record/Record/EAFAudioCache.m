//
//  EAFAudioCache.m
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 11/20/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import "EAFAudioCache.h"

@implementation EAFAudioCache

- (void) goGetAudio:(NSArray *)rawPaths paths:(NSArray *)ppaths language:(NSString *)lang {
    _itemIndex = 0;
    _rawPaths = [NSArray arrayWithArray:rawPaths];
    _paths = [NSArray arrayWithArray:ppaths];
    _language = lang;
    if ([_rawPaths count] > 0) {
        [self getAudioForCurrentItem];
    }
}

#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // A response has been received, this is where we initialize the instance var you created
    // so that we can append data to it in the didReceiveData method
    // Furthermore, this method is called each time there is a redirect so reinitializing it
    // also serves to clear it
    
    _mp3Audio = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // NSLog(@"didReceiveData ----- ");
    
    // Append the new data to the instance variable you declared
    [_mp3Audio appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
}

- (void)checkNextAudioFile {
    if (_itemIndex < _paths.count-1) {
        _itemIndex++;
       // NSLog(@"checkNextAudioFile %d downloads complete.",_itemIndex);

        [self getAudioForCurrentItem];
    }
    else {
        NSLog(@"%d downloads complete.",_itemIndex);
    }
}

// see getAudioForCurrentItem
- (NSString *)getCurrentCachePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *audioDir = [NSString stringWithFormat:@"%@_audio",_language];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:audioDir];
    NSString *rawRefAudioPath = [_rawPaths objectAtIndex: _itemIndex];
    NSString *destFileName = [filePath stringByAppendingPathComponent:rawRefAudioPath];
    return destFileName;
}

// go and get ref audio per item, make individual requests -- quite fast
- (void)getAudioForCurrentItem
{
    NSString *destFileName = [self getCurrentCachePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:destFileName] || [destFileName hasSuffix:@"NO"]) {
        [self checkNextAudioFile];
    }
    else {
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[_paths objectAtIndex:_itemIndex]]];
        
        // Create url connection and fire request
        NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:TRUE];
    }
}

// cache mp3 file
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSString *destFileName = [self getCurrentCachePath];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];
  //  NSLog(@"connectionDidFinishLoading : writing to      %@",destFileName);
    
    NSString *parent = [destFileName stringByDeletingLastPathComponent];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:parent]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:parent withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    [_mp3Audio writeToFile:destFileName atomically:YES];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:destFileName]) {
        NSLog(@"huh? can't find     %@",destFileName);
    }
    
    [self checkNextAudioFile];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];
}

@end
