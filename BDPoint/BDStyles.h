//
//  Created by Bluedot Innovation
//  Copyright (c) 2016 Bluedot Innovation. All rights reserved.
//
//  Style-related Marco defined across the project
//

#define UIColorFromRGB(hexValue) [UIColor colorWithRed:(( hexValue & 0xFF0000 ) >> 16 ) / 255.0f \
                                                 green:(( hexValue &   0xFF00 ) >> 8  ) / 255.0f \
                                                  blue:(  hexValue &     0xFF         ) / 255.0f alpha:1.0]

#define BDBlueColor UIColorFromRGB(0x429bd5)
#define BDGrayColor UIColor.grayColor

#define BDButtonCornerRadii 5.0f

#define BDButtonEnabledColor  BDBlueColor
#define BDButtonDisabledColor BDGrayColor