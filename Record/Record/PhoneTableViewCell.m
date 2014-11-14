//
//  MyTableViewCell.m
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 11/4/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import "PhoneTableViewCell.h"
//#import "UITouchesEvent.h"

@implementation PhoneTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

//- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
//{
//    // 1 second holding triggers touchAndHOld
//    NSLog(@"PhoneTableViewCell got touch %@",event);
//    
//    
//    for (UIView *subview in [self subviews]) {
//        UITouchesEvent *touch = (UITouchesEvent *) event;
//        CGPoint convertedPoint = [subview convertPoint:[touch locationInView:self] fromView:self];
//        UIView *hitTestView = [subview hitTest:convertedPoint withEvent:event];
//        if (hitTestView) {
//            NSLog(@"got hit at %@",hitTestView);
//            //return hitTestView;
//        }
//    }
//    
//    [super touchesBegan:touches withEvent:event];
//}


@end
