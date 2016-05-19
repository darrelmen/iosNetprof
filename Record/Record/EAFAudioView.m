//
//  EAFAudioView.m
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 11/13/14.
//  Copyright (c) 2011-2016 Massachusetts Institute of Technology, Lincoln Laboratory
//
#import "EAFAudioView.h"

@implementation EAFAudioView

- (void)touchesBegan:(NSSet *)touches
           withEvent:(UIEvent *)event {
//    NSLog(@"got touch event %@",event);
}

- (IBAction)gotClick:(id)sender {
  //  NSLog(@"gotClick %@",sender);
}

-(void)handleGesture:(UITapGestureRecognizer *)gestureRecognizer
{
   // NSLog(@"got gesture at %@",p);
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

@end
