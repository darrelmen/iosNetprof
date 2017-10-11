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

@property (strong, nonatomic) NSMutableOrderedSet *languagesLocal;
@property (strong, nonatomic) NSMutableSet *mutableRTLLanguages;

@property (strong, nonatomic) NSMutableDictionary *mutableNameToURL;
@property (strong, nonatomic) NSMutableDictionary *mutableNameToProjectID;
@property (strong, nonatomic) NSMutableDictionary *mutableNameToHost;

@property (strong, nonatomic) NSString *oldServer;
@property (strong, nonatomic) NSString *nServer;

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
        _oldServer = @"https://np.ll.mit.edu/";
        //   _oldServer = @"https://129.55.210.144/";
        //NSLog(@"EAFGetSites server now %@",_oldServer);
      //  _nServer = @"https://netprof1-dev.llan.ll.mit.edu/netprof/";
        _nServer = @"https://netprof1.ll.mit.edu/netprof/";
        //   _nServer = @"http://127.0.0.1:8888/netprof/";
    }
    
    return self;
}

- (NSNumber *) getProject:(NSString*) language {
    //if ([language isEqualToString:@"Russian"]) return [NSNumber numberWithInt:-1];
    return [_nameToProjectID objectForKey:language];
}

// PUBLIC
// do an async get request to the server to get the json defining the set of languages we can practice and their properties
- (void) getSites {
    _languagesLocal = [[NSMutableOrderedSet alloc] init];
    _languages =_languagesLocal;
    
    _mutableRTLLanguages = [[NSMutableSet alloc] init];
    _rtlLanguages = _mutableRTLLanguages;
    
    _mutableNameToURL  = [[NSMutableDictionary alloc] init];
    _nameToURL = _mutableNameToURL;
    
    _mutableNameToProjectID = [[NSMutableDictionary alloc] init];
    _nameToProjectID = _mutableNameToProjectID;
    
    _mutableNameToHost = [[NSMutableDictionary alloc] init];
    _nameToHost = _mutableNameToHost;
    
    [self getSitesFromServer:_oldServer];
}

// we talk to the old server, then the new server...
- (void)getSitesFromServer:(NSString *) theServer {
    NSString *baseurl;
    if ([theServer isEqualToString:_oldServer]) {
        baseurl = [NSString stringWithFormat:@"%@/sites.json", theServer];
    }
    else {
        baseurl = [NSString stringWithFormat:@"%@scoreServlet?projects", theServer];
    }
    
    NSURL *url = [NSURL URLWithString:baseurl];
    // NSLog(@"EAFGetSites getSites url %@",url);
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    
    // TODO : REMOVE ME - TEMPORARY HACK FOR BAD CERTS ON DEV MACHINE
    [NSMutableURLRequest setAllowsAnyHTTPSCertificate:YES forHost:[url host]];
    
    [urlRequest setHTTPMethod: @"GET"];
    [urlRequest setTimeoutInterval:10];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:true];
    
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:Nil];
    
    
    NSURLSessionDataTask *downloadTask = [session
                                          dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                              
                                              [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];
                                              if (error != nil) {
                                                  NSLog(@"\tgetSites Got error %@",error);
                                                  [self getCacheOrDefault:theServer];
                                              }
                                              else {
                                                  NSLog(@"\tgetSites Got response %@",response);
                                                  
                                                  _sitesData = data;
                                                  [self performSelectorOnMainThread:@selector(useJsonSitesData:)
                                                                         withObject:theServer
                                                                      waitUntilDone:YES];
                                              }
                                          }];
    [downloadTask resume];
}

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler{
    if([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]){
        // if([challenge.protectionSpace.host isEqualToString:@"mydomain.com"]){
        NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential,credential);
        //  }
    }
}

// cache the file as sites.json
- (NSString *)getCachePath:(NSString *) theServer {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *fileToGet;
    if ([theServer isEqualToString:_oldServer]) {
        fileToGet = @"oldSites.json";
    }
    else {
        fileToGet = @"newSites.json";
    }
    
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:fileToGet];
    return filePath;
}

// only in the case where we have no connectivity and can't talk to the server.
// Consider falling back to a canned set of sites if we've never been able to talk to the server.
- (void)getCacheOrDefault:(NSString *) theServer {
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self getCachePath:theServer]]) {
        NSLog(@"getCacheOrDefault reading from %@",[self getCachePath:theServer]);
        _sitesData = [NSData dataWithContentsOfFile:[self getCachePath:theServer]];
        
        NSError * error;
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:_sitesData
                              options:NSJSONReadingAllowFragments
                              error:&error];
        
        if (error) {
            NSLog(@"getCacheOrDefault got error %@",error);
            NSLog(@"getCacheOrDefault error     %@",error.description);
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
    
    NSMutableSet *localRTL = [[NSMutableSet alloc] init];
    _rtlLanguages = localRTL;
    
    for (int i = 0; i<fetchedArr.count; i++) {
        NSDictionary* site = fetchedArr[i];
       
//        NSLog(@"parseJSON got %@",site);
        
        BOOL showOnIOS = [[site valueForKey:@"showOnIOS"] boolValue];
        if (showOnIOS) {
            NSString *name = [site objectForKey:@"name"];
            NSString *url  = [site objectForKey:@"url"];
            if (url == NULL) {
                url = _nServer;
            }
            //            if ([name isEqualToString:@"Spanish"]) {
            //                url = _nServer;
            //                 NSLog(@"parseJSON using %@",url);
            //            }
            if (![url hasSuffix:@"/"]) {
                url = [NSString stringWithFormat:@"%@/",url];
            }
            BOOL isRTL = [[site valueForKey:@"rtl"] boolValue];
            
            if (isRTL) [localRTL addObject:name];
            
            NSNumber *id  = [site objectForKey:@"id"];
            
            [_mutableNameToURL   setObject:url     forKey:name];
            if (id != NULL) {
                [_mutableNameToProjectID  setObject:id forKey:name];
                NSString *host  = [site objectForKey:@"host"];
                NSLog(@"parseJSON host %@",host);
                if (host == NULL) host = @"";
                [_mutableNameToHost  setObject:host forKey:name];
            }
            else {
                [_mutableNameToProjectID  setObject: [NSNumber numberWithInt:-1] forKey:name];
                [_mutableNameToHost  setObject:@"" forKey:name];
            }
        }
    }
    
    [self setLanguagesGivenData];
}

// tell the delegate the site list is ready
- (void)useJsonSitesData:(NSString *) theServer {
    NSError * error;
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:_sitesData
                          options:NSJSONReadingAllowFragments
                          error:&error];
    if (error) {
        NSLog(@"useJsonSitesData got error %@",error);
        NSLog(@"useJsonChapterData error %@",error.description);
        
        [self getCacheOrDefault:theServer];
    }
    else {
        [self parseJSON:json];
        //  NSLog(@"name to url now %@",_nameToURL);
        //  NSLog(@"_languages now %@",_languages);
        [self writeSitesDataToCacheAt:[self getCachePath:theServer] mp3AudioData:_sitesData];
        if ([theServer isEqualToString:_oldServer]) {
            [self getSitesFromServer:_nServer];
        }
        else {

//            for(id key in _nameToURL)
//                NSLog(@"useJsonSitesData name=%@ url=%@", key, [_nameToURL objectForKey:key]);
            
//            for(id key in _nameToProjectID)
//                NSLog(@"key=%@ value=%@", key, [_nameToProjectID objectForKey:key]);
//            
            
         //   NSLog(@"useJsonSitesData all New %@",[_nameToProjectID allKeys]);
            
            NSMutableOrderedSet *copy = [_languages mutableCopy];
         //   NSLog(@"useJsonSitesData copy %@",copy);
            
            for(id key in _nameToProjectID) {
           //     NSLog(@"useJsonSitesData key=%@ project id=%@", key, [_nameToProjectID objectForKey:key]);
                if ([[_nameToProjectID objectForKey:key] intValue] > -1) {
                    [copy removeObject:key];
                }
            }
            
            _oldSites = copy;
            
         //   NSLog(@"useJsonSitesData _oldSites %@",_oldSites);

            [_delegate sitesReady];
        }
    }
}

// sort the language names
- (void)setLanguagesGivenData {
    for (NSString *name in _nameToURL.allKeys) {
        [_languagesLocal addObject:name];
    }
    
    //sorting
    [_languagesLocal sortUsingComparator:^NSComparisonResult(NSString *str1, NSString *str2) {
        return [str1 compare:str2 options:(NSNumericSearch)];
    }];
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
