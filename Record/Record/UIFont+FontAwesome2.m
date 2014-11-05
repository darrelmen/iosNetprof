//
//  UIFont+FontAwesome.m
//  FontAwesome-iOS Demo
//
//  Created by Alex Usbergo on 1/16/13.
//  Copyright (c) 2013 Alex Usbergo. All rights reserved.
//

#import "UIFont+FontAwesome2.h"
#import "NSString+FontAwesome2.h"

@implementation UIFont (FontAwesome)

#pragma mark - Public API
+ (UIFont*)fontAwesomeFontOfSize:(CGFloat)size {
    return [UIFont fontWithName:kFontAwesomeFamilyName size:size];
}

@end
