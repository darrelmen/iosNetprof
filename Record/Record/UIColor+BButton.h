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

#import <UIKit/UIKit.h>

@interface UIColor (BButton)

#pragma mark - Custom colors

+ (UIColor *)bb_defaultColorV2;
+ (UIColor *)bb_defaultColorV3;

+ (UIColor *)bb_primaryColorV2;
+ (UIColor *)bb_primaryColorV3;

+ (UIColor *)bb_infoColorV2;
+ (UIColor *)bb_infoColorV3;

+ (UIColor *)bb_successColorV2;
+ (UIColor *)bb_successColorV3;

+ (UIColor *)bb_warningColorV2;
+ (UIColor *)bb_warningColorV3;

+ (UIColor *)bb_dangerColorV2;
+ (UIColor *)bb_dangerColorV3;

+ (UIColor *)bb_inverseColorV2;
+ (UIColor *)bb_inverseColorV3;

+ (UIColor *)bb_twitterColor;
+ (UIColor *)bb_facebookColor;
+ (UIColor *)bb_purpleBButtonColor;
+ (UIColor *)bb_grayBButtonColor;

#pragma mark - Utilities

- (UIColor *)bb_desaturatedColorToPercentSaturation:(CGFloat)percent;
- (UIColor *)bb_lightenColorWithValue:(CGFloat)value;
- (UIColor *)bb_darkenColorWithValue:(CGFloat)value;
- (BOOL)bb_isLightColor;

@end