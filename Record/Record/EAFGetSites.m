//
//  EAFGetSites.m
//  Record
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
@end

@implementation EAFGetSites

- (void) getSites {
    _languagesLocal = [[NSMutableArray alloc] init];
    _languages =_languagesLocal;
    
    NSString *baseurl = @"https://np.ll.mit.edu/sites.json";
    
    NSURL *url = [NSURL URLWithString:baseurl];
    NSLog(@"EAFGetSites getSites url %@",url);
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    [urlRequest setHTTPMethod: @"GET"];
    [urlRequest setTimeoutInterval:10];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:true];
   
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         //      NSLog(@"Got response %@",error);
         //     NSLog(@"Got data %@",data);
         
         if (error != nil) {
             NSLog(@"\tGot error %@",error);
             //             dispatch_async(dispatch_get_main_queue(), ^{
             //                 [self connection:nil didFailWithError:error];
             //             });
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

- (NSString *)getCachePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"sites.json"];
    return filePath;
}

- (void)getCacheOrDefault {
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self getCachePath]]) {
        NSLog(@"reading from %@",[self getCachePath]);
        _sitesData = [NSData dataWithContentsOfFile:[self getCachePath]];
        [self useJsonSitesData];
    }
    else {
        _nameToURL = [NSDictionary dictionaryWithObjectsAndKeys:
                      @"Dari",	@"https://np.ll.mit.edu/npfClassroomDari"
                      @"Egyptian",	@"https://np.ll.mit.edu/npfClassroomEgyptian"
                      @"English",	@"https://np.ll.mit.edu/npfClassroomEnglish"
                      @"Farsi",	@"https://np.ll.mit.edu/npfClassroomFarsi"
                      @"Korean",	@"https://np.ll.mit.edu/npfClassroomKorean"
                      @"Levantine",	@"https://np.ll.mit.edu/npfClassroomLevantine"
                      @"Mandarin",	@"https://np.ll.mit.edu/npfClassroomCM"
                      @"MSA",	@"https://np.ll.mit.edu/npfClassroomMSA"
                      @"Pashto1",	@"https://np.ll.mit.edu/npfClassroomPashto1"
                      @"Pashto2",	@"https://np.ll.mit.edu/npfClassroomPashto2"
                      @"Pashto3",	@"https://np.ll.mit.edu/npfClassroomPashto3"
                      @"Russian",	@"https://np.ll.mit.edu/npfClassroomRussian"
                      @"Spanish",	@"https://np.ll.mit.edu/npfClassroomSpanish"
                      @"Sudanese",	@"https://np.ll.mit.edu/npfClassroomSudanese"
                      @"Tagalog",	@"https://np.ll.mit.edu/npfClassroomTagalog"
                      @"Urdu",@"https://np.ll.mit.edu/npfClassroomUrdu",
                      nil                                      ];
        [self setLanguagesGivenData];
    }
    [_delegate sitesReady];
}

- (void)useJsonSitesData {
    NSError * error;
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:_sitesData
                          options:NSJSONReadingAllowFragments
                          error:&error];
    
    if (error) {
        NSLog(@"got error %@",error);
        NSLog(@"useJsonChapterData error %@",error.description);
        [self getCacheOrDefault];
    }
    
    NSArray *fetchedArr = [json objectForKey:@"sites"];
    
    NSMutableDictionary *nameToURLLocal = [[NSMutableDictionary alloc] init];
    _nameToURL =nameToURLLocal;
    
    for (int i = 0; i<fetchedArr.count; i++) {
        NSDictionary* site = fetchedArr[i];
        // NSLog(@"got %@",site);
        
        BOOL showOnIOS = [[site valueForKey:@"showOnIOS"] boolValue];
        if (showOnIOS) {
            NSString *name = [site objectForKey:@"name"];
            [nameToURLLocal setObject:[site objectForKey:@"url"] forKey:name];
        }
    }
    
    [self setLanguagesGivenData];
    NSLog(@"name to url now %@",_nameToURL);
    NSLog(@"_languages now %@",_languages);
    
    [self writeSitesDataToCacheAt:[self getCachePath] mp3AudioData:_sitesData];
    [_delegate sitesReady];
}

- (void)setLanguagesGivenData {
    NSMutableArray *languagesLocal = [[NSMutableArray alloc] init];
    
    for (NSString *name in _nameToURL.allKeys) {
        [languagesLocal addObject:name];
    }
    
    //sorting
    [languagesLocal sortUsingComparator:^NSComparisonResult(NSString *str1, NSString *str2) {
        return [str1 compare:str2 options:(NSNumericSearch)];
    }];

    _languages =languagesLocal;
}

- (void)writeSitesDataToCacheAt:(NSString *)destFileName mp3AudioData:(NSData *)mp3AudioData {
    NSLog(@"writeSitesDataToCacheAt : writing to      %@",destFileName);
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