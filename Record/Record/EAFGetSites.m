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
//  EAFGetSites.m
//  Record
//  Talk to the server to get a json file that lists the set of available languages/websites.
//  Cache the result so that if later we don't have connectivity, we'll work normally until we do.
//  Keeps track of which languages are RTL languages.
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 2/12/16.
//  Copyright © 2016 MIT Lincoln Laboratory. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EAFGetSites.h"
#import "SSKeychain.h"


@interface EAFGetSites ()
@property (strong, nonatomic) NSData *sitesData;
@property (strong, nonatomic) NSMutableArray *languagesLocal;

@property NSString *server;

@end

@interface NSURLRequest(Private)
+(void)setAllowsAnyHTTPSCertificate:(BOOL)inAllow forHost:(NSString *)inHost;
@end

@implementation EAFGetSites

// Set the NetProf server here!
- (instancetype)init
{
    self = [super init];
    if (self) {
        _server = @"https://np.ll.mit.edu/";
     //   _server = @"https://129.55.210.144/";
        NSLog(@"EAFGetSites server now %@",_server);
    }
    return self;
}

// do an async get request to the server to get the json defining the set of languages we can practice and their properties
- (void) getSites {
    _languagesLocal = [[NSMutableArray alloc] init];
    _rtlLanguages   = [[NSMutableSet alloc] init];
    _languages =_languagesLocal;
    
    NSString *baseurl = [NSString stringWithFormat:@"%@/sites.json", _server];
    
    NSURL *url = [NSURL URLWithString:baseurl];
    NSLog(@"EAFGetSites getSites url %@",url);
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    
    // TODO : REMOVE ME - TEMPORARY HACK FOR BAD CERTS ON DEV MACHINE
    [NSMutableURLRequest setAllowsAnyHTTPSCertificate:YES forHost:[url host]];
    
    [urlRequest setHTTPMethod: @"GET"];
    [urlRequest setTimeoutInterval:10];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:true];
    
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         if (error != nil) {
             NSLog(@"\tgetSites Got error %@",error);
             [self getCacheOrDefault];
         }
         else {
             _sitesData = data;
             [self performSelectorOnMainThread:@selector(useJsonSitesData)
                                    withObject:nil
                                 waitUntilDone:YES];
         }
     }];
}

// cache the file as sites.json
- (NSString *)getCachePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"sites.json"];
    return filePath;
}

// only in the case where we have no connectivity and can't talk to the server.
// Consider falling back to a canned set of sites if we've never been able to talk to the server.
- (void)getCacheOrDefault {
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self getCachePath]]) {
        NSLog(@"getCacheOrDefault reading from %@",[self getCachePath]);
        _sitesData = [NSData dataWithContentsOfFile:[self getCachePath]];
        
        NSError * error;
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:_sitesData
                              options:NSJSONReadingAllowFragments
                              error:&error];
        
        if (error) {
            NSLog(@"getCacheOrDefault got error %@",error);
            NSLog(@"getCacheOrDefault error %@",error.description);
        }
        else {
            [self parseJSON:json];
        }
    }
    [_delegate sitesReady];
}

// only include languages whose showOnIOS flag is set
- (void)parseJSON:(NSDictionary *)json {
    NSArray *fetchedArr = [json objectForKey:@"sites"];
    
    NSMutableDictionary *nameToURLLocal = [[NSMutableDictionary alloc] init];
    _nameToURL =nameToURLLocal;
    
    NSMutableSet *localRTL = [[NSMutableSet alloc] init];
    _rtlLanguages = localRTL;
    
    for (int i = 0; i<fetchedArr.count; i++) {
        NSDictionary* site = fetchedArr[i];
        //   NSLog(@"got %@",site);
        
        BOOL showOnIOS = [[site valueForKey:@"showOnIOS"] boolValue];
        if (showOnIOS) {
            NSString *name = [site objectForKey:@"name"];
            NSString *url  = [site objectForKey:@"url"];
            if (![url hasSuffix:@"/"]) {
                url = [NSString stringWithFormat:@"%@/",url];
            }
            BOOL isRTL = [[site valueForKey:@"rtl"] boolValue];
            
            if (isRTL) [localRTL addObject:name];
            
            [nameToURLLocal setObject:url forKey:name];
        }
    }
    
    [self setLanguagesGivenData];
}

// tell the delegate the site list is ready
- (void)useJsonSitesData {
    NSError * error;
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:_sitesData
                          options:NSJSONReadingAllowFragments
                          error:&error];
    
    if (error) {
        NSLog(@"useJsonSitesData got error %@",error);
        NSLog(@"useJsonChapterData error %@",error.description);
        
        [self getCacheOrDefault];
    }
    else {
        [self parseJSON:json];
        //  NSLog(@"name to url now %@",_nameToURL);
        //  NSLog(@"_languages now %@",_languages);
        [self writeSitesDataToCacheAt:[self getCachePath] mp3AudioData:_sitesData];
        [_delegate sitesReady];
    }
}

// sort the language names
- (void)setLanguagesGivenData {
    NSMutableArray *languagesLocal = [[NSMutableArray alloc] init];
    
    for (NSString *name in _nameToURL.allKeys) {
        [languagesLocal addObject:name];
    }
    
    //sorting
    [languagesLocal sortUsingComparator:^NSComparisonResult(NSString *str1, NSString *str2) {
        return [str1 compare:str2 options:(NSNumericSearch)];
    }];
    
    _languages = languagesLocal;
}

// write the json we get back from the server to a local file
- (void)writeSitesDataToCacheAt:(NSString *)destFileName mp3AudioData:(NSData *)mp3AudioData {
    NSLog(@"writeSitesDataToCacheAt : writing to      %@",destFileName);
    NSString *parent = [destFileName stringByDeletingLastPathComponent];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:parent]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:parent withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    [mp3AudioData writeToFile:destFileName atomically:YES];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:destFileName]) {
        NSLog(@"writeSitesDataToCacheAt huh? can't find     %@",destFileName);
    }
}
@end
