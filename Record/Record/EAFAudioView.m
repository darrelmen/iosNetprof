//
//  EAFAudioView.m
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 11/13/14.
//  Copyright (c) 2014 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//
#import "EAFAudioView.h"

@implementation EAFAudioView

- (void)touchesBegan:(NSSet *)touches
           withEvent:(UIEvent *)event {
    NSLog(@"got touch event %@",event);
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


- (IBAction)gotClick:(id)sender {
    NSLog(@"gotClick %@",sender);
}

-(void)handleGesture:(UITapGestureRecognizer *)gestureRecognizer
{
    CGPoint p = [gestureRecognizer locationInView:self];
    
   
   // NSLog(@"got gesture at %@",p);
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

@end
