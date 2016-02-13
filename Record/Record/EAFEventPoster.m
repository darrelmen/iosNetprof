//
//  EAFEventPoster.m
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 11/20/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import "EAFEventPoster.h"
#import "SSKeychain.h"
#import "EAFGetSites.h"

@interface EAFEventPoster ()

@property NSString *urlToUse;

@end

@implementation EAFEventPoster


- (id) init {
    if ( self = [super init] ) {
        _urlToUse = @"unset";
        return self;
    } else
        return nil;
}

- (id) initWithURL:(NSString *) url {
    if ( self = [super init] ) {
        _urlToUse = url;
        return self;
    } else
        return nil;
}

- (void) setURL:(NSString *) url {
    _urlToUse = url;
}

- (void) postEvent:(NSString *)context exid:(NSString *)exid widget:(NSString *)widget  widgetType:(NSString *)widgetType {
    NSString *userid = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"userid"];
    NSString *retrieveuuid = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"UUID"];
    
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)0];   
    NSString *baseurl = [NSString stringWithFormat:@"%@/scoreServlet", _urlToUse];

    NSLog(@"postEvent post %@ to %@ or %@",context,_urlToUse,baseurl);
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:baseurl]];
    [urlRequest setHTTPMethod: @"POST"];
    [urlRequest setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [urlRequest setValue:@"application/x-www-form-urlencoded"
      forHTTPHeaderField:@"Content-Type"];
    
    // add request parameters
    
    [urlRequest setValue:userid forHTTPHeaderField:@"user"];
    
    [urlRequest setValue:retrieveuuid forHTTPHeaderField:@"device"];
    [urlRequest setValue:context forHTTPHeaderField:@"context"];
    [urlRequest setValue:exid forHTTPHeaderField:@"exid"];
    [urlRequest setValue:widget forHTTPHeaderField:@"widget"];
    [urlRequest setValue:widgetType forHTTPHeaderField:@"widgetType"];
    [urlRequest setValue:@"event" forHTTPHeaderField:@"request"];
    
    // post the audio
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         if (error != nil) {
             NSLog(@"postEvent : Got error %@",error);
         }
         else {
           //  NSLog(@"postEvent : reply %@",data);

         }
     }];
}

- (void) postRT:(NSString *)resultID rtDur:(NSString *)rtDur {
    NSString *baseurl = [NSString stringWithFormat:@"%@/scoreServlet", _urlToUse];
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:baseurl]];
    [urlRequest setHTTPMethod: @"POST"];
    
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)0];
    
    [urlRequest setValue:postLength forHTTPHeaderField:@"Content-Length"];
    
    [urlRequest setValue:@"application/x-www-form-urlencoded"
      forHTTPHeaderField:@"Content-Type"];
    
    [urlRequest setValue:@"roundTrip" forHTTPHeaderField:@"request"];
    
    // add request parameters
    [urlRequest setValue:resultID forHTTPHeaderField:@"resultID"];
    [urlRequest setValue:rtDur forHTTPHeaderField:@"roundTrip"];
    // post the audio
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         if (error != nil) {
             NSLog(@"postRT : Got error %@",error);
         }
         else {
         }
     }];
}

//- (NSString *)getURL:(NSString *) lang
//{
//    return  [_siteGetter.nameToURL objectForKey:lang];
//}
#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // A response has been received, this is where we initialize the instance var you created
    // so that we can append data to it in the didReceiveData method
    // Furthermore, this method is called each time there is a redirect so reinitializing it
    // also serves to clear it
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // Append the new data to the instance variable you declared
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
}

//
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    //    NSString *destFileName = [self getCurrentCachePath];
    //   [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];
    //  NSLog(@"connectionDidFinishLoading : writing to      %@",destFileName);
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    //   [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];
}

@end
