//
//  EAFAudioCache.m
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 11/20/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import "EAFHistory.h"

@implementation EAFHistory

//- (void) goGetAudio:(NSArray *)rawPaths paths:(NSArray *)ppaths language:(NSString *)lang {
//    _itemIndex = 0;
//    _rawPaths = [NSArray arrayWithArray:rawPaths];
//    _paths = [NSArray arrayWithArray:ppaths];
//    _language = lang;
//    if ([_rawPaths count] > 0) {
//        [self getAudioForCurrentItem];
//    }
//}

- (void)askServerForJson {
    // NSString *baseurl = [NSString stringWithFormat:@"https://np.ll.mit.edu/npfClassroom%@/scoreServlet?request=chapterHistory&user=%ld&%@=%@&%@=%@", _language, _user, _unitName, _unitSelection, _chapterName, _chapterSelection];
    NSString *baseurl = [NSString stringWithFormat:@"https://np.ll.mit.edu/npfClassroom%@/scoreServlet?request=chapterHistory&user=%ld&%@=%@", _language, _user, _chapterName, _chapterSelection];
    
    NSLog(@"url %@",baseurl);
    
    NSURL *url = [NSURL URLWithString:baseurl];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    [urlRequest setCachePolicy:NSURLRequestReturnCacheDataElseLoad];
    
    [urlRequest setHTTPMethod: @"GET"];
    [urlRequest setValue:@"application/x-www-form-urlencoded"
      forHTTPHeaderField:@"Content-Type"];
    
    NSURLConnection *connection = [NSURLConnection connectionWithRequest:urlRequest delegate:self];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:true];
    
    [connection start];
}

#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // A response has been received, this is where we initialize the instance var you created
    // so that we can append data to it in the didReceiveData method
    // Furthermore, this method is called each time there is a redirect so reinitializing it
    // also serves to clear it
    
    //  NSLog(@"didReceiveResponse ----- ");
    
    _responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // NSLog(@"didReceiveData ----- ");
    
    // Append the new data to the instance variable you declared
    [_responseData appendData:data];
}
//NSDictionary* chapterInfo;
//BOOL hasModel;

- (BOOL)useJsonChapterData {
    NSError * error;
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:_responseData
                          options:NSJSONReadingAllowFragments
                          error:&error];
    
    if (error) {
        NSLog(@"useJsonChapterData error %@",error.description);
        return false;
    }
    
    NSArray *jsonArray = [json objectForKey:@"scores"];
    
    if (jsonArray != nil) {
        _jsonContentArray = jsonArray; // remove
        _exToScore   = [[NSMutableDictionary alloc] init];
        _exToHistory = [[NSMutableDictionary alloc] init];
        _exList = [[NSMutableArray alloc] init];
        for (NSDictionary *entry in jsonArray) {
            NSString *ex = [entry objectForKey:@"ex"];
            if ([_exToFL objectForKey:ex] != nil) {
                //   NSLog(@"ex key %@",ex);
                NSString *score = [entry objectForKey:@"s"];
                
                //   NSLog(@"score  %@",score);
                [_exToScore setValue:score forKey:ex];
                
                NSArray *jsonArrayHistory = [entry objectForKey:@"h"];
                
                [_exToHistory setValue:jsonArrayHistory forKey:ex];
                [_exList addObject:ex];
            }
        }
        //NSLog(@"ex to score %lu",(unsigned long)[_exToScore count]);
        NSString *correct = [json objectForKey:@"lastCorrect"];
        NSString *incorrect = [json objectForKey:@"lastIncorrect"];
        float total = [correct floatValue] + [incorrect floatValue];
        float percent = total == 0.0f ? 0.0f : [correct floatValue]/total;
        percent *= 100;
        int percentInt = round(percent);
        int totalInt = round(total);
        UIViewController  *parent = [self parentViewController];
        NSString *wordReport;
        wordReport = [NSString stringWithFormat:@"%@ of %d Correct (%d%%)",correct,totalInt,percentInt];
        parent.navigationItem.title = wordReport;
        myCurrentTitle = wordReport;
        // [self setTitle:[NSString stringWithFormat:@"%@ of %d Correct (%d%%)",correct,totalInt,percentInt]];
    }
    
    [[self tableView] reloadData];
    
    return true;
}

NSString *myCurrentTitle;

-(void)setCurrentTitle {
    UIViewController  *parent = [self parentViewController];
    parent.navigationItem.title = myCurrentTitle;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // The request is complete and data has been received
    
    //[loadingContentAlert dismissWithClickedButtonIndex:0 animated:true];
    [self useJsonChapterData];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // The request has failed for some reason!
    // Check the error var
    NSLog(@"Download content failed with %@",error);
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];
}

@end
