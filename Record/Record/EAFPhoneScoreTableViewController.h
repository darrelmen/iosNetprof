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
//  EAFPhoneScoreTableViewController
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 7/16/14.
//  Copyright (c) 2011-2016 Massachusetts Institute of Technology, Lincoln Laboratory
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "EAFAudioPlayer.h"

@interface EAFPhoneScoreTableViewController : UITableViewController<AVAudioPlayerDelegate, UIGestureRecognizerDelegate,AudioPlayerNotification>

@property NSString *language;
@property NSNumber *projid;

@property NSString *chapterName;
@property NSString *chapterSelection;

@property NSString *unitName;
@property NSString *unitSelection;

@property NSDictionary *phoneToWords;
@property NSDictionary *resultToRef;
@property NSDictionary *resultToAnswer;
@property NSDictionary *resultToWords;
@property NSArray *phonesInOrder;
@property NSArray *phonesInOrderScores;
@property AVPlayer *player;
@property NSString *url;
@property BOOL isRTL;

@property long user;
@property NSNumber *listid;

-(void)setCurrentTitle;

@end
