//
//  EAFPopoverViewController.m
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 1/29/15.
//  Copyright (c) 2015 Ferme, Elizabeth - 0553 - MITLL. All rights reserved.
//

#import "EAFPopoverViewController.h"

@interface EAFPopoverViewController ()

@end

@implementation EAFPopoverViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   // _contentSizeForViewInPopover = CGSizeMake(80,50);
    NSLog(@"view did load - popover!");
    NSMutableAttributedString *att = [[NSMutableAttributedString alloc] initWithString:@"Press and hold to record"];
    
    
    NSRange range = [@"Press and hold to record" rangeOfString:@"Press and hold"];
  
    [att setAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:_message.font.pointSize]} range:range];

    _message.attributedText = att;
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
