//
//  EAFGetSites.h
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 2/12/16.
//  Copyright © 2016 MIT Lincoln Laboratory. All rights reserved.
//


#import <Foundation/Foundation.h>


@protocol SitesNotification <NSObject>

@optional
- (void) sitesReady;

@end

@interface EAFGetSites : NSObject

@property (strong, nonatomic) NSDictionary *nameToURL;
@property (strong, nonatomic) NSArray *languages;
- (void) getSites;

@property(assign) id<SitesNotification> delegate;

@end
