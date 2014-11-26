//
//  EAFEventPoster.m
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 11/20/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import "EAFEventPoster.h"
#import "SSKeychain.h"

@implementation EAFEventPoster

// called from EAFItemTableViewController
- (void) postEvent:(NSString *)context exid:(NSString *)exid lang:(NSString *)lang widget:(NSString *)widget  widgetType:(NSString *)widgetType {
    
    NSString *userid = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"userid"];
    
//    [urlRequest setValue:userid forHTTPHeaderField:@"user"];
//    [urlRequest setValue:[UIDevice currentDevice].model forHTTPHeaderField:@"deviceType"];
    NSString *retrieveuuid = [SSKeychain passwordForService:@"mitll.proFeedback.device" account:@"UUID"];
    
    /**
     String user = request.getHeader("user");
     String context = request.getHeader("context");
     String exid = request.getHeader("exid");
     String widgetid = request.getHeader("widget");
     String widgetType = request.getHeader("widgetType");
     */
    
   // NSData *postData = [NSData dataWithContentsOfURL:_audioRecorder.url];
    // NSLog(@"data %d",[postData length]);
    
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)0];
    
    // NSLog(@"file length %@",postLength);
    NSString *baseurl = [NSString stringWithFormat:@"%@/scoreServlet", [self getURL:lang]];
      NSLog(@"talking to %@",baseurl);
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:baseurl]];
    [urlRequest setHTTPMethod: @"POST"];
    [urlRequest setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [urlRequest setValue:@"application/x-www-form-urlencoded"
      forHTTPHeaderField:@"Content-Type"];
    
    // add request parameters
    
    // old style
//    [urlRequest setValue:@"MyAudioMemo.wav" forHTTPHeaderField:@"fileName"];
    
    [urlRequest setValue:userid forHTTPHeaderField:@"user"];
 //   [urlRequest setValue:[UIDevice currentDevice].model forHTTPHeaderField:@"deviceType"];
    
    NSString *fullContext = [NSString stringWithFormat:@"%@ %@",retrieveuuid,context];
    [urlRequest setValue:fullContext forHTTPHeaderField:@"context"];
    [urlRequest setValue:exid forHTTPHeaderField:@"exid"];
    [urlRequest setValue:widget forHTTPHeaderField:@"widget"];
    [urlRequest setValue:widgetType forHTTPHeaderField:@"widgetType"];
    [urlRequest setValue:@"event" forHTTPHeaderField:@"request"];
    
    // post the audio
    
    //[urlRequest setHTTPBody:postData];
    
    NSURLConnection *connection = [NSURLConnection connectionWithRequest:urlRequest delegate:self];
    [connection start];
    

}
- (NSString *)getURL:(NSString *) lang
{
    return [NSString stringWithFormat:@"https://np.ll.mit.edu/npfClassroom%@/", lang];
}
#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // A response has been received, this is where we initialize the instance var you created
    // so that we can append data to it in the didReceiveData method
    // Furthermore, this method is called each time there is a redirect so reinitializing it
    // also serves to clear it
    
   // _mp3Audio = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // Append the new data to the instance variable you declared
   // [_mp3Audio appendData:data];
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
