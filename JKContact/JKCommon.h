//
//  JKCommon.h
//  JKUtilDemo
//
//  Created by emerys on 16/4/20.
//  Copyright © 2016年 Emerys. All rights reserved.
//

#ifndef JKCommon_h
#define JKCommon_h


/**************************************日志*******************************************************/
#ifndef __OPTIMIZE__
# define NSLog(...) NSLog(__VA_ARGS__)
#else
# define NSLog(...)
#endif

// ## 起连接作用
#define JKWeak(type) __weak typeof(type) weak##type = type

// # 的意思是为后面紧跟的标识符添加一个双引号""
#define JKString(str) [NSString stringWithFormat:@"%@",@#str]
#define JKMsg(str)  NSLog(@"%@",@#str)

#define JKLogMethodName NSLog(@"%s", __func__)
#define JKLogPoint(var) (NSLog(@"X:%f,  Y:%f",var.x,var.y))
#define JKLogSize(var) (NSLog(@"width:%f,   height:%f",var.width,var.height))
#define JKLogRect(var) (NSLog(@"X:%f,   Y:%f,  width:%f,    height:%f",var.origin.x,var.origin.y,var.size.width,var.size.height))

/**************************************颜色*******************************************************/
// var 为0x开头十六进制数
#define colorFromHexRGBAlpha(var,alp) [UIColor colorWithRed:((var & 0xff0000) >> 16) / 255.0 \
                                                   green:((var & 0xff00) >> 8) / 255.0 \
                                                    blue:(var & 0xff) / 255.0 \
                                                   alpha:(alp)]

#define colorFromHexRGB(var) colorFromHexRGBAlpha(var,(1.0))

// r,g,b为0～255的浮点数
#define colorWithRGBAlpha(r,g,b,alp) [UIColor colorWithRed:(r) / 255.0 \
                                                  green:(g) / 255.0 \
                                                   blue:(b) / 255.0 \
                                                  alpha:(alp)]

#define colorWithRGB(r,g,b) colorWithRGBAlpha(r,g,b,(1.0))

/**************************************屏幕*******************************************************/
#define JK_ScreenWidth ([UIScreen mainScreen].bounds.size.width)
#define JK_ScreenHeigh ([UIScreen mainScreen].bounds.size.height)
#define JK_TABBAR_HEIGHT 49
#define JK_NAVIGATIONBAR_HEIGHT 64

/**************************************系统版本****************************************************/
/** iOS7或以上 */
#define JK_iOS7OrLater ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
/** iOS8或以上 */
#define JK_iOS8OrLater ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
/** iOS9或以上 */
#define JK_iOS9OrLater ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0)

/**************************************手机版本****************************************************/
#define JK_iPhone4 ([UIScreen mainScreen].bounds.size.height == 480)
#define JK_iPhone5 ([UIScreen mainScreen].bounds.size.height == 568)
#define JK_iPhone6 ([UIScreen mainScreen].bounds.size.height == 667)
#define JK_iPhone6P ([UIScreen mainScreen].bounds.size.height == 736)


#endif /* JKCommon_h */
