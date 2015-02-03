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
@end


@implementation EAFAudioCache

- (id)init {
    if ( ( self = [super init] ) )
    {
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 2;
    }
    _reachable = true;
    [self setupReachability];
    return self;
}

- (void) setupReachability {
    NSLog(@"-----> setupReachability %@",self);

    // Allocate a reachability object
    Reachability* reach = [Reachability reachabilityForInternetConnection];
    
    // Set the blocks
    reach.reachableBlock = ^(Reachability*reach)
    {
        // keep in mind this is called on a background thread
        // and if you are updating the UI it needs to happen
        // on the main thread, like this:
        
        dispatch_async(dispatch_get_main_queue(), ^{
         //   NSLog(@"REACHABLE!");
            _reachable = true;
        });
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
- (void) goGetAudio:(NSArray *)rawPaths paths:(NSArray *)ppaths language:(NSString *)lang {
    _language = lang;
    _completed = 0;
    
    NSLog(@"go get audio for %lu",(unsigned long)rawPaths.count);
    
    if (true) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:TRUE];
        for (int index = 0; index < rawPaths.count; index++) {
            NSString *rawPath = [rawPaths objectAtIndex:index];
            NSString *path = [ppaths objectAtIndex:index];
            __weak NSString *weakRef = rawPath;
            __weak NSString *weakPathRef = path;
            
            NSString *destFileName = [self getFileInCache:weakRef];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:destFileName] || [destFileName hasSuffix:@"NO"]) {
                _completed++;
                if (rawPaths.count == _completed) {
                    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];
                   // NSLog(@"\t goGetAudio turning off network indicator");
                }
            }
            else {
                NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:weakPathRef]];
                
                //                  NSLog(@"operation request %@", request);
                
                // Create url connection and fire request
                // NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
                
                if (false) {
                    [NSURLConnection sendAsynchronousRequest:request queue:_operationQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
                     {
                               NSLog(@"Got response %@ = %@",weakRef,error);
                         
                         if (error != nil) {
                             NSLog(@"\t goGetAudio Got error %@",error);
                             [self connection:nil didFailWithError:error];
                         }
                         else {
                             //      _mp3Audio = data;
                             _completed++;
                             if (_completed % 10 == 0) NSLog(@"%@ completed %d",self,_completed);
                             
                             if (rawPaths.count == _completed) {
                                 [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];
                                 NSLog(@"\t goGetAudio turning off network indicator");
                             }
                             NSString *destFileName = [self getFileInCache:weakRef];
                             //         NSLog(@"operation destFileName %@", destFileName);
                             [self writeMP3DataToCacheAt:destFileName mp3AudioData:data];
                         }
                     }];
                }
                
                NSBlockOperation *operation = [[NSBlockOperation alloc] init];
                __weak NSBlockOperation *weakOperation = operation;
                [operation addExecutionBlock:^{
                    if (![weakOperation isCancelled]){
                        //do something...
                        
                        if (_reachable) {
                            NSURLResponse * response = nil;
                            NSError * error = nil;
                            NSData * data = [NSURLConnection sendSynchronousRequest:request
                                                                  returningResponse:&response
                                                                              error:&error];
                            if (error != nil) {
                                NSLog(@"\t goGetAudio Got error %@",error);
                                [self connection:nil didFailWithError:error];
                            }
                            else {
                                //      _mp3Audio = data;
                                _completed++;
                                if (_completed % 10 == 0) NSLog(@"%@ completed %d",self,_completed);
                                
                                if (rawPaths.count == _completed) {
                                    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];
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
            //     }];
            
        }
    }
    else {
        if ([rawPaths count] > 0) {
            // [self getAudioForCurrentItem];
        }
    }
    
    NSLog(@"initial queue posting finished for %@",self);
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
    // Append the new data to the instance variable you declared
    //   [_mp3Audio appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
}

//- (void)checkNextAudioFile {
//    if (_itemIndex < _paths.count-1) {
//        _itemIndex++;
//        NSLog(@"checkNextAudioFile %d downloads complete.",_itemIndex);
//
//        [self getAudioForCurrentItem];
//    }
//    else {
//        NSLog(@"%d downloads complete.",_itemIndex);
//    }
//}

- (NSString *)getFileInCache:(NSString *)rawRefAudioPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *audioDir = [NSString stringWithFormat:@"%@_audio",_language];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:audioDir];
    return[filePath stringByAppendingPathComponent:rawRefAudioPath];
}

// see getAudioForCurrentItem
//- (NSString *)getCurrentCachePath
//{
//    NSString *rawRefAudioPath = [_rawPaths objectAtIndex: _itemIndex];
//
//    return [self getFileInCache:rawRefAudioPath];
//}
//
//// go and get ref audio per item, make individual requests -- quite fast
//- (void)getAudioForCurrentItem
//{
//    NSString *destFileName = [self getCurrentCachePath];
//    if ([[NSFileManager defaultManager] fileExistsAtPath:destFileName] || [destFileName hasSuffix:@"NO"]) {
//        [self checkNextAudioFile];
//    }
//    else {
//        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[_paths objectAtIndex:_itemIndex]]];
//
//        NSLog(@"Made request - %@",request);
//
//        // Create url connection and fire request
//       // NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
//        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:TRUE];
//
//        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
//         {
//             // NSLog(@"\n\n\n1 Got response %@",error);
//
//             if (error != nil) {
//                 NSLog(@"\t getAudioForCurrentItem Got error %@",error);
//                 [self connection:nil didFailWithError:error];
//             }
//             else {
//                 _mp3Audio = data;
//                 [self connectionDidFinishLoading:nil];
//             }
//         }];
//    }
//}

- (void)writeMP3DataToCacheAt:(NSString *)destFileName mp3AudioData:(NSData *)mp3AudioData {
    //   [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];
    
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

//- (void)writeMP3ToCache:(NSData *)mp3AudioData {
//
//    NSString *destFileName = [self getCurrentCachePath];
//
//    [self writeMP3DataToCacheAt:destFileName mp3AudioData:mp3AudioData];
//}

// cache mp3 file
//- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
//    [self writeMP3ToCache:_mp3Audio];
//
//    [self checkNextAudioFile];
//}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];
}

@end
