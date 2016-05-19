//
//  MyTableViewCell.h
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 11/4/14.
//  Copyright (c) 2011-2016 Massachusetts Institute of Technology, Lincoln Laboratory
//

#import <UIKit/UIKit.h>
//#import <SplunkMint-iOS/SplunkMint-iOS.h>

@interface MyTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *fl;
@property (nonatomic, weak) IBOutlet UILabel *english;
@property (nonatomic, weak) IBOutlet UIView *first;
@property (nonatomic, weak) IBOutlet UIView *second;
@property (nonatomic, weak) IBOutlet UIView *third;
@property (nonatomic, weak) IBOutlet UIView *fourth;
@property (nonatomic, weak) IBOutlet UIView *fifth;

@end
