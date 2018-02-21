//
//  UIColor_netprofColors.m
//  Record
//
//  Created by Budd, Raymond - 0552 - MITLL on 2/3/18.
//  Copyright © 2018 MIT Lincoln Laboratory. All rights reserved.
//

#import <Foundation/Foundation.h>

@implementation UIColor (Extensions)

+ (UIColor *)npDarkBlue {
    return [UIColor colorWithRed:9/255.0 green:65/255.0 blue:105/255.0 alpha:1.0] ;
}

+ (UIColor *)npDarkBlueBorder {
    //    return [UIColor colorWithRed:202/255.0 green:238/255.0 blue:252/255.0 alpha:1.0] ;
    return [UIColor colorWithRed:0/255.0 green:50/255.0 blue:90/255.0 alpha:1.0] ;
}

+ (UIColor *)npLightBlue {
//    return [UIColor colorWithRed:202/255.0 green:238/255.0 blue:252/255.0 alpha:1.0] ;
        return [UIColor colorWithRed:202/255.0 green:238/255.0 blue:252/255.0 alpha:1.0] ;
}

+ (UIColor *)npLightBlueBorder {
    //    return [UIColor colorWithRed:202/255.0 green:238/255.0 blue:252/255.0 alpha:1.0] ;
    return [UIColor colorWithRed:187/255.0 green:223/255.0 blue:237/255.0 alpha:1.0] ;
}

+ (UIColor *)npRecordBorder {
    //    return [UIColor colorWithRed:202/255.0 green:238/255.0 blue:252/255.0 alpha:1.0] ;
    return [UIColor colorWithRed:255/255.0 green:0/255.0 blue:0/255.0 alpha:1.0] ;
}

+ (UIColor *)npRecordBG {
    //    return [UIColor colorWithRed:202/255.0 green:238/255.0 blue:252/255.0 alpha:1.0] ;
    return [UIColor colorWithRed:255/255.0 green:167/255.0 blue:167/255.0 alpha:1.0] ;
}


+ (UIColor *)npMedPurple {
    return [UIColor colorWithRed:99/255.0 green:109/255.0 blue:201/255.0 alpha:1.0] ;
}

+ (UIColor *)npLightYellow {
    return [UIColor colorWithRed:255/255.0 green:226/255.0 blue:149/255.0 alpha:1.0] ;
}


+ (UIColor *)npAltPressButtonBGOn {
    return [UIColor colorWithRed:69/255.0 green:124/255.0 blue:182/255.0 alpha:1.0] ;
}

+ (UIColor *)npAltPressButtonFGOn {
    //    return [UIColor colorWithRed:202/255.0 green:238/255.0 blue:252/255.0 alpha:1.0] ;
    return [UIColor colorWithRed:218/255.0 green:229/255.0 blue:239/255.0 alpha:1.0] ;
}

+ (UIColor *)npAltPressButtonFGOff {
    //    return [UIColor colorWithRed:202/255.0 green:238/255.0 blue:252/255.0 alpha:1.0] ;
    return [UIColor colorWithRed:107/255.0 green:150/255.0 blue:196/255.0 alpha:1.0] ;
}

@end
