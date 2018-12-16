//
//  UIViewController+ForceOrientation.h
//  ScreenForceRotation
//
//  Created by huweitao on 2017/5/9.
//  Copyright © 2017年 huweitao. All rights reserved.
//

#import <UIKit/UIKit.h>

#define ABS_LONG [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height ? [UIScreen mainScreen].bounds.size.width : [UIScreen mainScreen].bounds.size.height
#define ABS_SHORT [UIScreen mainScreen].bounds.size.width < [UIScreen mainScreen].bounds.size.height ? [UIScreen mainScreen].bounds.size.width : [UIScreen mainScreen].bounds.size.height

#define IOS9_LOWER ([UIViewController fetchSystemVersion] < 9)
#define IOS8_LOWER ([UIViewController fetchSystemVersion] < 8)

//判断PLUS机型
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define PLUS_H (!IOS8_LOWER ? [UIScreen mainScreen].nativeBounds:[UIScreen mainScreen].bounds).size.height
#define PLUS_W (!IOS8_LOWER ? [UIScreen mainScreen].nativeBounds:[UIScreen mainScreen].bounds).size.width
#define SC_MAX_LENGTH (MAX(PLUS_H, PLUS_W))
#define IS_IPHONE_PLUS (IS_IPHONE && SC_MAX_LENGTH >= 1920.0)
#define IS_SCALE_MODE (IOS8_OR_HIGHER && [UIScreen mainScreen].nativeScale > 2.8)

#define AUTO_RETURN(plus,normal) (normal)

@interface UIViewController (ForceOrientation)

@property (nonatomic, assign) UIInterfaceOrientationMask preferredOrientationMask;
@property (nonatomic, assign) UIInterfaceOrientation preferredSupportedOrientation;

// statusBar + View + Devide
- (void)forceChangeOrientation:(UIInterfaceOrientation)orientation;
//- (BOOL)statusBarIsEqualToSupportedOrientation;
- (void)detectPlusAutotoRotation; // viewDidLoad中

+ (double)fetchSystemVersion;

@end
