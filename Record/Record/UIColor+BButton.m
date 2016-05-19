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
//  Created by Mathieu Bolard on 31/07/12.
//  Copyright (c) 2012 Mathieu Bolard. All rights reserved.
//
//  https://github.com/mattlawer/BButton
//
//
//  BButton is licensed under the MIT license
//  http://opensource.org/licenses/MIT
//
//
//  -----------------------------------------
//  Edited and refactored by Jesse Squires on 2 April, 2013.
//
//  http://github.com/jessesquires/BButton
//
//  http://hexedbits.com
//

#import "UIColor+BButton.h"

@implementation UIColor (BButton)

#pragma mark - Custom colors

+ (UIColor *)bb_defaultColorV2
{
    return [UIColor colorWithRed:0.85f green:0.85f blue:0.85f alpha:1.00f];
}

+ (UIColor *)bb_defaultColorV3
{
    return [UIColor colorWithHue:0.0f saturation:0.0f brightness:1.0f alpha:1.0f];
}

+ (UIColor *)bb_primaryColorV2
{
    return [UIColor colorWithRed:0.00f green:0.33f blue:0.80f alpha:1.00f];
}

+ (UIColor *)bb_primaryColorV3
{
    return [UIColor colorWithHue:208.0f/360.0f saturation:0.72f brightness:0.69f alpha:1.0f];
}

+ (UIColor *)bb_infoColorV2
{
    return [UIColor colorWithRed:0.18f green:0.59f blue:0.71f alpha:1.00f];
}

+ (UIColor *)bb_infoColorV3
{
    return [UIColor colorWithHue:194.0f/360.0f saturation:0.59f brightness:0.87f alpha:1.0f];
}

+ (UIColor *)bb_successColorV2
{
    return [UIColor colorWithRed:0.32f green:0.64f blue:0.32f alpha:1.00f];
}

+ (UIColor *)bb_successColorV3
{
    return [UIColor colorWithHue:120.0f/360.0f saturation:0.50f brightness:0.72f alpha:1.0f];
}

+ (UIColor *)bb_warningColorV2
{
    return [UIColor colorWithRed:0.97f green:0.58f blue:0.02f alpha:1.00f];
}

+ (UIColor *)bb_warningColorV3
{
    return [UIColor colorWithHue:35.0f/360.0f saturation:0.68f brightness:0.94f alpha:1.0f];
}

+ (UIColor *)bb_dangerColorV2
{
    return [UIColor colorWithRed:0.74f green:0.21f blue:0.18f alpha:1.00f];
}

+ (UIColor *)bb_dangerColorV3
{
    return [UIColor colorWithHue:2.0f/360.0f saturation:0.64f brightness:0.85f alpha:1.0f];
}

+ (UIColor *)bb_inverseColorV2
{
    return [UIColor colorWithRed:0.13f green:0.13f blue:0.13f alpha:1.00f];
}

+ (UIColor *)bb_inverseColorV3
{
    return [UIColor colorWithHue:0.0f saturation:0.0f brightness:0.75f alpha:1.0f];
}

+ (UIColor *)bb_twitterColor
{
    return [UIColor colorWithRed:0.25f green:0.60f blue:1.00f alpha:1.00f];
}

+ (UIColor *)bb_facebookColor
{
    return [UIColor colorWithRed:0.23f green:0.35f blue:0.60f alpha:1.00f];
}

+ (UIColor *)bb_purpleBButtonColor
{
    return [UIColor colorWithRed:0.45f green:0.30f blue:0.75f alpha:1.00f];
}

+ (UIColor *)bb_grayBButtonColor
{
    return [UIColor colorWithRed:0.60f green:0.60f blue:0.60f alpha:1.00f];
}

#pragma mark - Utilities

- (UIColor *)bb_desaturatedColorToPercentSaturation:(CGFloat)percent
{
    CGFloat h, s, b, a;
    [self getHue:&h saturation:&s brightness:&b alpha:&a];
    return [UIColor colorWithHue:h saturation:s * percent brightness:b alpha:a];
}

- (UIColor *)bb_lightenColorWithValue:(CGFloat)value
{
    NSUInteger totalComponents = CGColorGetNumberOfComponents(self.CGColor);
    BOOL isGreyscale = (totalComponents == 2) ? YES : NO;
    
    CGFloat *oldComponents = (CGFloat *)CGColorGetComponents(self.CGColor);
    CGFloat newComponents[4];
    
    if(isGreyscale) {
        newComponents[0] = oldComponents[0] + value > 1.0f ? 1.0f : oldComponents[0] + value;
        newComponents[1] = oldComponents[0] + value > 1.0f ? 1.0f : oldComponents[0] + value;
        newComponents[2] = oldComponents[0] + value > 1.0f ? 1.0f : oldComponents[0] + value;
        newComponents[3] = oldComponents[1];
    }
    else {
        newComponents[0] = oldComponents[0] + value > 1.0f ? 1.0f : oldComponents[0] + value;
        newComponents[1] = oldComponents[1] + value > 1.0f ? 1.0f : oldComponents[1] + value;
        newComponents[2] = oldComponents[2] + value > 1.0f ? 1.0f : oldComponents[2] + value;
        newComponents[3] = oldComponents[3];
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGColorRef newColor = CGColorCreate(colorSpace, newComponents);
	CGColorSpaceRelease(colorSpace);
    
	UIColor *retColor = [UIColor colorWithCGColor:newColor];
	CGColorRelease(newColor);
    
    return retColor;
}

- (UIColor *)bb_darkenColorWithValue:(CGFloat)value
{
    NSUInteger totalComponents = CGColorGetNumberOfComponents(self.CGColor);
    BOOL isGreyscale = (totalComponents == 2) ? YES : NO;
    
    CGFloat *oldComponents = (CGFloat *)CGColorGetComponents(self.CGColor);
    CGFloat newComponents[4];
    
    if(isGreyscale) {
        newComponents[0] = oldComponents[0] - value < 0.0f ? 0.0f : oldComponents[0] - value;
        newComponents[1] = oldComponents[0] - value < 0.0f ? 0.0f : oldComponents[0] - value;
        newComponents[2] = oldComponents[0] - value < 0.0f ? 0.0f : oldComponents[0] - value;
        newComponents[3] = oldComponents[1];
    }
    else {
        newComponents[0] = oldComponents[0] - value < 0.0f ? 0.0f : oldComponents[0] - value;
        newComponents[1] = oldComponents[1] - value < 0.0f ? 0.0f : oldComponents[1] - value;
        newComponents[2] = oldComponents[2] - value < 0.0f ? 0.0f : oldComponents[2] - value;
        newComponents[3] = oldComponents[3];
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGColorRef newColor = CGColorCreate(colorSpace, newComponents);
	CGColorSpaceRelease(colorSpace);
    
	UIColor *retColor = [UIColor colorWithCGColor:newColor];
	CGColorRelease(newColor);
    
    return retColor;
}

- (BOOL)bb_isLightColor
{
    NSUInteger totalComponents = CGColorGetNumberOfComponents(self.CGColor);
    BOOL isGreyscale = (totalComponents == 2) ? YES : NO;
    
    CGFloat *components = (CGFloat *)CGColorGetComponents(self.CGColor);
    CGFloat sum;
    
    if(isGreyscale) {
        sum = components[0];
    }
    else {
        sum = (components[0] + components[1] + components[2]) / 3.0f;
    }
    
    return (sum >= 0.75f);
}

@end