//
//  EAFAudioCache.m
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 11/20/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import "EAFAudioCache.h"
#import "Reachability.h"

@interface EAFAudioCache ()

@property (strong) NSOperationQueue *operationQueue;
@property int completed;
@property BOOL reachable;
@property NSArray *paths;
@property NSArray *rawPaths;

@end


@implementation EAFAudioCache

- (id)init {
    if ( ( self = [super init] ) )
    {
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 2;
        _reachable = true;
    }
    [self setupReachability];
    return self;
}

- (void) setupReachability {
    //   NSLog(@"-----> setupReachability %@",self);
    
    // Allocate a reachability object
    Reachability* reach = [Reachability reachabilityForInternetConnection];
    
    // Set the blocks
    reach.reachableBlock = ^(Reachability*reach)
    {
        // keep in mind this is called on a background thread
        // and if you are updating the UI it needs to happen
        // on the main thread, like this:
        
        //  dispatch_async(dispatch_get_main_queue(), ^{
        //   NSLog(@"REACHABLE!");
        _reachable = true;
        //  });
    };
    
    reach.unreachableBlock = ^(Reachability*reach)
    {
        // NSLog(@"UNREACHABLE!");
        _reachable = false;
    };
    
    // Start the notifier, which will cause the reachability object to retain itself!
    [reach startNotifier];
}

- (void) cancelAllOperations {
    NSLog(@"-----> cancelAllOperations %@",self);
    [_operationQueue cancelAllOperations ];
}

// called from EAFItemTableViewController
- (void) goGetAudio:(NSArray *)rawPaths2 paths:(NSArray *)ppaths2 language:(NSString *)lang {
    _language = [lang copy];
    _completed = 0;
    _rawPaths = [rawPaths2 copy];
    _paths = [ppaths2 copy];
    
    NSLog(@"go get audio for %lu",(unsigned long)_rawPaths.count);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:TRUE];
    });

    for (int index = 0; index < _rawPaths.count; index++) {
        NSString *rawPath = [_rawPaths objectAtIndex:index];
        NSString *path = [_paths objectAtIndex:index];
        __weak NSString *weakRef = rawPath;
        __weak NSString *weakPathRef = path;
        
        NSString *destFileName = [self getFileInCache:weakRef];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:destFileName] || [destFileName hasSuffix:@"NO"]) {
            _completed++;
            if (_rawPaths.count == _completed) {
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];
                // NSLog(@"\t goGetAudio turning off network indicator");
            }
        }
        else {
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:weakPathRef]];
            NSBlockOperation *operation = [[NSBlockOperation alloc] init];
            __weak NSBlockOperation *weakOperation = operation;
            [operation addExecutionBlock:^{
                if (![weakOperation isCancelled]){
                    if (_reachable) {
                        NSURLResponse * response = nil;
                        NSError * error = nil;
                        NSData * data = [NSURLConnection sendSynchronousRequest:request
                                                              returningResponse:&response
                                                                          error:&error];
                        if (error != nil) {
                            NSLog(@"\t goGetAudio Got error %@",error);
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];
                            });
                        }
                        else {
                            //      _mp3Audio = data;
                            _completed++;
                            if (_completed % 10 == 0) NSLog(@"%@ completed %d",self,_completed);
                            
                            if (_rawPaths.count == _completed) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];
                                });
                                //               NSLog(@"\t goGetAudio turning off network indicator");
                            }
                            NSString *destFileName = [self getFileInCache:weakRef];
                            //         NSLog(@"operation destFileName %@", destFileName);
                            [self writeMP3DataToCacheAt:destFileName mp3AudioData:data];
                        }
                    }
                }
                else {
                    NSLog(@"operation cancelled...");
                }
            }];
            [_operationQueue addOperation:operation];
        }
    }
    
    NSLog(@"initial queue posting finished for %@",self);
}

- (NSString *)getFileInCache:(NSString *)rawRefAudioPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *audioDir = [NSString stringWithFormat:@"%@_audio",_language];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:audioDir];
    return[filePath stringByAppendingPathComponent:rawRefAudioPath];
}

- (void)writeMP3DataToCacheAt:(NSString *)destFileName mp3AudioData:(NSData *)mp3AudioData {
    //  NSLog(@"connectionDidFinishLoading : writing to      %@",destFileName);
    
    NSString *parent = [destFileName stringByDeletingLastPathComponent];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:parent]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:parent withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    [mp3AudioData writeToFile:destFileName atomically:YES];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:destFileName]) {
        NSLog(@"huh? can't find     %@",destFileName);
    }
}

@end
