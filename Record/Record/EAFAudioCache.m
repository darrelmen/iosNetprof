//
//  EAFAudioCache.m
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 11/20/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import "EAFAudioCache.h"
#import "Reachability.h"

@interface AudioCacheOperation : NSOperation

-(id)initWithNumber:(unsigned long)total rawPath:(NSString *)rawPath path:(NSString *) path filePath:(NSString *) filePath;
@property unsigned long total;
@property NSString *rawPath;
@property NSString *path;
@property NSString *filePath;

@end

@implementation AudioCacheOperation

-(id)initWithNumber:(unsigned long)total rawPath:(NSString *)rawPath path:(NSString *) path filePath:(NSString *) filePath {
    self = [super init];
    if( !self ) return nil;
    
    _total = total;
    _rawPath = [rawPath copy];
    _path = [path copy];
    _filePath = [filePath copy];
    
    return self;
}

- (void)writeMP3DataToCacheAt:(NSString *)destFileName mp3AudioData:(NSData *)mp3AudioData {
   // NSLog(@"AudioCache : writeMP3DataToCacheAt : writing to      %@",destFileName);
    NSString *parent = [destFileName stringByDeletingLastPathComponent];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:parent]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:parent withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    [mp3AudioData writeToFile:destFileName atomically:YES];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:destFileName]) {
        NSLog(@"writeMP3DataToCacheAt huh? can't find     %@",destFileName);
    }
}

- (NSString *)getFileInCache:(NSString *)rawRefAudioPath filePath:(NSString *)filePath
{
    return [filePath stringByAppendingPathComponent:rawRefAudioPath];
}

-(void) main {
    if (![self isCancelled]){
        // NSLog(@"queue posting finished for %@ and %lu items, queue has %lu",self,(unsigned long)_rawPaths.count,_operationQueue.operationCount);
        
        //NSLog(@"AudioCacheOperation audio cache url talking to %@ raw %@ file %@",_path,_rawPath,_filePath);
        
        NSString *destFileName = [self getFileInCache:_rawPath filePath:_filePath];
        //NSLog(@"%@ started to check %@.",self,destFileName);
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:destFileName] || [destFileName hasSuffix:@"NO"]) {
            //            _completed++;
            //            if (total == _completed) {
            //                NSLog(@"\t goGetAudio turning off network indicator");
            //
            //                dispatch_async(dispatch_get_main_queue(), ^{
            //                    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:FALSE];
            //                });
            //            }
            //  NSLog(@"%@ checked file %@.",self,destFileName);
            
        }
        else {
            NSURLResponse * response = nil;
            NSError * error = nil;
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:_path]];
            NSData * data = [NSURLConnection sendSynchronousRequest:request
                                                  returningResponse:&response
                                                              error:&error];
            if (error != nil) {
                NSLog(@"\t AudioCacheOperation main Got error %@",error);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];
                });
            }
            else {
              //  NSLog(@"%@ completed %@",self,destFileName);
                //                _completed++;
                //                if (_completed % 10 == 0) NSLog(@"%@ completed %d",self,_completed);
                //
                //                if (_rawPaths.count == _completed) {
                //                    NSLog(@"\t goGetAudio turning off network indicator 2");
                //
                //                    dispatch_async(dispatch_get_main_queue(), ^{
                //                        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];
                //                    });
                //                }
                //         NSLog(@"operation destFileName %@", destFileName);
                [self writeMP3DataToCacheAt:destFileName mp3AudioData:data];
            }
        }
    }
    else {
        NSLog(@"AudioCacheOperation operation cancelled...");
    }
}
@end

@interface EAFAudioCache ()

@property (strong) NSOperationQueue *operationQueue;
@property int completed;
@property NSArray *paths;
@property NSArray *rawPaths;

@end


@implementation EAFAudioCache

- (id)init {
    if ( ( self = [super init] ) )
    {
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 2;
    }
    return self;
}

- (void) cancelAllOperations {
  //  NSLog(@"-----> cancelAllOperations %@ %lu pending",self,(unsigned long)_operationQueue.operationCount);
    [_operationQueue cancelAllOperations ];
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:FALSE];
//    });
}

// called from EAFItemTableViewController
- (void) goGetAudio:(NSArray *)rawPaths2 paths:(NSArray *)ppaths2 language:(NSString *)lang {
    [_operationQueue cancelAllOperations ];
    
    _completed = 0;
    _rawPaths = [rawPaths2 copy];
    _paths = [ppaths2 copy];
    
  //  NSLog(@"EAFAudioCache - go get audio for %lu",(unsigned long)_rawPaths.count);
    @try {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
       // NSLog(@"got doc dir %@",documentsDirectory);
        NSString *audioDir = [NSString stringWithFormat:@"%@_audio",lang];
        NSString *filePath = [documentsDirectory stringByAppendingPathComponent:audioDir];
        Reachability* reach = [Reachability reachabilityForInternetConnection];
        if ([reach isReachable]) {
            //NSLog(@"_rawPaths count %d",_rawPaths.count);
            //NSLog(@"_paths count %d",_paths .count);

            for (int index = 0; index < _rawPaths.count; index++) {
                NSString *rawPath = [_rawPaths objectAtIndex:index];
                NSString *path = [_paths objectAtIndex:index];
                AudioCacheOperation *operation = [[AudioCacheOperation alloc] initWithNumber:_rawPaths.count rawPath:rawPath path:path filePath:filePath];
                [_operationQueue addOperation:operation];
            }
        }
    //    NSLog(@"EAFAudioCache - initial queue posting finished for %@ and %lu items, queue has %lu",self,(unsigned long)_rawPaths.count,(unsigned long)_operationQueue.operationCount);
    }
    @catch (NSException *exception)
    {
        // Print exception information
        NSLog( @"NSException caught" );
        NSLog( @"Name: %@", exception.name);
        NSLog( @"Reason: %@", exception.reason );
        return;
    }
}

@end
