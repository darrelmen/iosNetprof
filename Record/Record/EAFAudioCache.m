/*
 * DISTRIBUTION STATEMENT C. Distribution authorized to U.S. Government Agencies
 * and their contractors; 2015. Other request for this document shall be referred
 * to DLIFLC.
 *
 * WARNING: This document may contain technical data whose export is restricted
 * by the Arms Export Control Act (AECA) or the Export Administration Act (EAA).
 * Transfer of this data by any means to a non-US person who is not eligible to
 * obtain export-controlled data is prohibited. By accepting this data, the consignee
 * agrees to honor the requirements of the AECA and EAA. DESTRUCTION NOTICE: For
 * unclassified, limited distribution documents, destroy by any method that will
 * prevent disclosure of the contents or reconstruction of the document.
 *
 * This material is based upon work supported under Air Force Contract No.
 * FA8721-05-C-0002 and/or FA8702-15-D-0001. Any opinions, findings, conclusions
 * or recommendations expressed in this material are those of the author(s) and
 * do not necessarily reflect the views of the U.S. Air Force.
 *
 * © 2015 Massachusetts Institute of Technology.
 *
 * The software/firmware is provided to you on an As-Is basis
 *
 * Delivered to the US Government with Unlimited Rights, as defined in DFARS
 * Part 252.227-7013 or 7014 (Feb 2014). Notwithstanding any copyright notice,
 * U.S. Government rights in this work are defined by DFARS 252.227-7013 or
 * DFARS 252.227-7014 as detailed above. Use of this work other than as specifically
 * authorized by the U.S. Government may violate any copyrights that exist in this work.
 *
 */

//
//  EAFAudioCache.m
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 11/20/14.
//  Copyright (c) 2011-2016 Massachusetts Institute of Technology, Lincoln Laboratory
//

#import "EAFAudioCache.h"
#import "Reachability.h"

@interface AudioCacheOperation : NSOperation

-(id)initWithNumber:(unsigned long)total rawPath:(NSString *)rawPath path:(NSString *) path filePath:(NSString *) filePath;
@property unsigned long total;
@property NSString *rawPath;
@property NSString *path;
@property NSString *filePath;
@property int completed;

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
    //NSLog(@"AudioCache : writeMP3DataToCacheAt : writing to      %@",destFileName);
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
                //    NSLog(@"%@ completed %@",self,destFileName);
                
                _completed++;
                if (_completed % 10 == 0) NSLog(@"%@ completed %d",self,_completed);
                
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

- (void)cacheAudio:(NSArray *)items url:(NSString *) url
{
    NSString *msg=[NSString stringWithFormat:@" cacheAudio getting audio for %lu",(unsigned long)items.count];
    NSLog(@"%@", msg);
    
    NSMutableArray *paths = [[NSMutableArray alloc] init];
    NSMutableArray *rawPaths = [[NSMutableArray alloc] init];
    
    NSArray *fields = [NSArray arrayWithObjects:@"ref",@"mrr",@"msr",@"frr",@"fsr",@"ctmref",@"ctfref",@"ctref",nil];
    
 //   NSString *url =[self getServerURL];
    
    for (NSDictionary *object in items) {
        for (NSString *id in fields) {
            if ([[object objectForKey:id] isKindOfClass:[NSString class]]) {
                NSString *refPath = [object objectForKey:id];
                
                if (refPath != NULL && refPath.length > 2) { //i.e. not NO
                    //NSLog(@"adding %@ %@",id,refPath);
                    refPath = [refPath stringByReplacingOccurrencesOfString:@".wav"
                                                                 withString:@".mp3"];
                    
                    NSMutableString *mu = [NSMutableString stringWithString:refPath];
                    [mu insertString:url atIndex:0];
                    [paths addObject:mu];
                    [rawPaths addObject:refPath];
                }
            }
            //            else {
            //                NSLog(@"skip %@",id);
            //            }
        }
    }
    
    //   NSLog(@"ItemTableViewController.cacheAudio Got get audio -- %@ ",_audioCache);
    [self goGetAudio:rawPaths paths:paths language:_language];
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
    
    NSLog(@"EAFAudioCache - go get audio for %lu",(unsigned long)_rawPaths.count);
    @try {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        // NSLog(@"got doc dir %@",documentsDirectory);
        NSString *audioDir = [NSString stringWithFormat:@"%@_audio",lang];
        NSString *filePath = [documentsDirectory stringByAppendingPathComponent:audioDir];
        NSLog(@"goGetAudio got filePath %@",filePath);
       // Reachability* reach = [Reachability reachabilityForInternetConnection];
        if ([[Reachability reachabilityForInternetConnection] isReachable]) {
            //NSLog(@"_rawPaths count %d",_rawPaths.count);
            //NSLog(@"_paths count %d",_paths .count);
            
            for (int index = 0; index < _rawPaths.count; index++) {
                NSString *rawPath = [_rawPaths objectAtIndex:index];
                NSString *path = [_paths objectAtIndex:index];
                AudioCacheOperation *operation = [[AudioCacheOperation alloc] initWithNumber:_rawPaths.count rawPath:rawPath path:path filePath:filePath];
                [_operationQueue addOperation:operation];
            }
        }
        NSLog(@"EAFAudioCache - initial queue posting finished for %@ and %lu items, queue has %lu",self,(unsigned long)_rawPaths.count,(unsigned long)_operationQueue.operationCount);
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
