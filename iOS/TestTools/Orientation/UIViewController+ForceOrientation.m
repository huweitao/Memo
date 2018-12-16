//
//  UIViewController+ForceOrientation.m
//  ScreenForceRotation
//
//  Created by huweitao on 2017/5/9.
//  Copyright © 2017年 huweitao. All rights reserved.
//

#import "UIViewController+ForceOrientation.h"
#import <objc/runtime.h>

static BOOL AllowedPlusAutoRatation = NO;
static UIInterfaceOrientation originOrientation = UIInterfaceOrientationPortrait;

@interface UIViewController()

@property (nonatomic, assign) BOOL isPlusAutoRatation;
@property (nonatomic, assign) UIInterfaceOrientation plusOriginOrientation;

@end

@implementation UIViewController (ForceOrientation)

static inline bool In_SwizzleMethod(Class origClass, SEL origSel, Class newClass, SEL newSel)
{
    Method origMethod = class_getInstanceMethod(origClass, origSel);
    if (!origMethod) {
        NSLog(@"Original method %@ not found for class %@", NSStringFromSelector(origSel), [origClass class]);
        return false;
    }
    
    Method newMethod = class_getInstanceMethod(newClass, newSel);
    if (!newMethod) {
        NSLog( @"New method %@ not found for class %@", NSStringFromSelector(newSel), [newClass class]);
        return false;
    }
    
    if (class_addMethod(origClass,origSel,class_getMethodImplementation(origClass, origSel),method_getTypeEncoding(origMethod))) {
        NSLog(@"Original method %@ is is not owned by class %@",NSStringFromSelector(origSel), [origClass class]);
        return false;
    }
    
    // 如果不是同一个类，需要添加method
    if (![NSStringFromClass(origClass) isEqualToString:NSStringFromClass(newClass)]) {
        if (!class_addMethod(origClass,newSel,class_getMethodImplementation(newClass, newSel),method_getTypeEncoding(newMethod))) {
        NSLog(@"New method %@ can not be added in class %@",NSStringFromSelector(newSel), [newClass class]);
        }
    }
    
    method_exchangeImplementations(class_getInstanceMethod(origClass, origSel), class_getInstanceMethod(origClass, newSel));
    return true;
}

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        In_SwizzleMethod([self class],@selector(viewDidLoad),[self class],@selector(ori_viewDidLoad));
    });
}

- (void)ori_viewDidLoad
{
    // default Orientation
    self.preferredOrientationMask = UIInterfaceOrientationMaskPortrait;
    self.preferredSupportedOrientation = UIInterfaceOrientationPortrait;
    
    [self ori_viewDidLoad];
    
    [self detectPlusAutotoRotation];
}

#pragma mark - Public

// statusBar + View + Devide
- (void)forceChangeOrientation:(UIInterfaceOrientation)orientation
{
    if (orientation == UIDeviceOrientationUnknown) {
        return;
    }
    
    [self forceViewOrientationChange:orientation];
}

- (BOOL)statusBarIsEqualToSupportedOrientation:(UIInterfaceOrientationMask)orientationMask
{
    if (orientationMask == UIInterfaceOrientationMaskAll) {
        return YES;
    }
    switch (orientationMask) {
        case UIInterfaceOrientationMaskPortrait:
            return ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait);
            break;
        case UIInterfaceOrientationMaskPortraitUpsideDown:
            return ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortraitUpsideDown);
            break;
        case UIInterfaceOrientationMaskLandscapeLeft:
            return ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft);
            break;
        case UIInterfaceOrientationMaskLandscapeRight:
            return ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight);
            break;
        case UIInterfaceOrientationMaskLandscape:
            return ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight
                    || ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft));
            break;
        case UIInterfaceOrientationMaskAll:
            return YES;
            break;
        case UIInterfaceOrientationMaskAllButUpsideDown:
            return ([UIApplication sharedApplication].statusBarOrientation != UIInterfaceOrientationPortraitUpsideDown);
            break;
        default:
            break;
    }
    return NO;
}

- (void)detectPlusAutotoRotation
{
    if ([self isKindOfClass:[UIInputViewController class]]) {
        return;
    }
    
    // Keyboard controller UICompatibilityInputViewController UIInputWindowController
    NSString *classStr = NSStringFromClass([self class]);
    if ([classStr hasPrefix:@"UIInput"]
        || [classStr hasPrefix:@"UIComp"]) {
        return;
    }

    if (IS_IPHONE_PLUS) {
        self.isPlusAutoRatation = ![self statusBarIsEqualToSupportedOrientation:self.preferredOrientationMask];
        self.plusOriginOrientation = [UIApplication sharedApplication].statusBarOrientation;
        AllowedPlusAutoRatation = ![self statusBarIsEqualToSupportedOrientation:self.preferredOrientationMask];
        originOrientation = [UIApplication sharedApplication].statusBarOrientation;
    }
    else {
        self.isPlusAutoRatation = NO;
        AllowedPlusAutoRatation = NO;
    }
    
//     NSLog(@"detect isPlusAutoRatation %@",self.isPlusAutoRatation ? @"YES":@"NO");
//     NSLog(@"detect plusOriginOrientation %d",self.plusOriginOrientation);
}

+ (double)fetchSystemVersion
{
    static double v;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        v = [UIDevice currentDevice].systemVersion.doubleValue;
    });
    return v;
}

#pragma mark - Private
// device setting
- (void)forceChangeDeviceOrientation:(UIDeviceOrientation)orientation
{
    if ([UIDevice currentDevice].orientation == orientation || orientation == UIDeviceOrientationUnknown) {
        return;
    }
    
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        NSString *selStr = @"setOrie";
        selStr = [selStr stringByAppendingString:@"ntation:"];
        SEL selector = NSSelectorFromString(selStr);
        if (selector) {
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
            [invocation setSelector:selector];
            [invocation setTarget:[UIDevice currentDevice]];
            int val  = orientation;
            // 从2开始是因为0 1 两个参数已经被selector和target占用
            [invocation setArgument:&val atIndex:2];
            [invocation invoke];
        }
    }
}

// view + status bar setting
- (void)forceViewOrientationChange:(UIInterfaceOrientation)orientation
{
    if (orientation == UIDeviceOrientationUnknown
        || [UIApplication sharedApplication].statusBarOrientation == orientation) {
        return;
    }
    
    [[UIApplication sharedApplication] setStatusBarOrientation:orientation];
    
    UIWindow *wind = [self keyboardWindow];
    CGAffineTransform needTransform = CGAffineTransformIdentity;
    CGRect needBounds = CGRectMake(0, 0, ABS_SHORT, ABS_LONG);
    UIInterfaceOrientation oriet = AUTO_RETURN(originOrientation, self.plusOriginOrientation);
    CGFloat ratio = (oriet == UIInterfaceOrientationLandscapeLeft) ? -1.0:1.0;
    BOOL validChange = YES;
    
//    NSLog(@"force isPlusAutoRatation %@",self.isPlusAutoRatation ? @"YES":@"NO");
//    NSLog(@"force plusOriginOrientation %d",self.plusOriginOrientation);
    
    switch (orientation)
    {
        case UIInterfaceOrientationPortrait:
        {
            needTransform = AUTO_RETURN(AllowedPlusAutoRatation, self.isPlusAutoRatation) ? CGAffineTransformMakeRotation(-M_PI * 0.5 * ratio) :CGAffineTransformIdentity;
            needBounds = CGRectMake(0, 0, ABS_SHORT, ABS_LONG);
        }
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
        {
            needTransform = AUTO_RETURN(AllowedPlusAutoRatation, self.isPlusAutoRatation) ? CGAffineTransformMakeRotation(M_PI * 0.5 * ratio) :CGAffineTransformMakeRotation(M_PI*1);
            needBounds = CGRectMake(0, 0, ABS_SHORT, ABS_LONG);
        }
            break;
        case UIInterfaceOrientationLandscapeLeft:
        {
            needTransform = AUTO_RETURN(AllowedPlusAutoRatation, self.isPlusAutoRatation) ? ((oriet == orientation) ? CGAffineTransformIdentity : CGAffineTransformMakeRotation(M_PI * 1.0 * ratio)):CGAffineTransformMakeRotation(-M_PI*0.5);
            needBounds = CGRectMake(0, 0, ABS_LONG, ABS_SHORT);
        }
            break;
        case UIInterfaceOrientationLandscapeRight:
        {
            needTransform = AUTO_RETURN(AllowedPlusAutoRatation, self.isPlusAutoRatation)  ? ((oriet == orientation) ? CGAffineTransformIdentity : CGAffineTransformMakeRotation(M_PI * 1.0 * ratio)) : CGAffineTransformMakeRotation(M_PI*0.5);
            needBounds = CGRectMake(0, 0, ABS_LONG, ABS_SHORT);
        }
            break;
        default:
        {
            validChange = NO;
        }
            break;
    }
    
    if (!validChange) {
        return;
    }
    
    [UIView animateWithDuration:0.2 animations:^{
        self.view.transform = needTransform;
        self.view.bounds = needBounds;
        if (IOS9_LOWER) {
            wind.transform = needTransform;
            wind.bounds = needBounds;
        }
    }];
}

// iOS8 键盘有问题
- (UIWindow *)keyboardWindow
{
    UIWindow *window = nil;
    for (window in [UIApplication sharedApplication].windows) {
        if ([self _getKeyboardViewFromWindow:window]) return window;
    }
    window = [UIApplication sharedApplication].keyWindow;
    if ([self _getKeyboardViewFromWindow:window]) return window;
    
    NSMutableArray *kbWindows = nil;
    for (window in [UIApplication sharedApplication].windows) {
        NSString *windowName = NSStringFromClass(window.class);
        if (IOS9_LOWER) {
            // UITextEffectsWindow
            if (windowName.length == 19 &&
                [windowName hasPrefix:@"UI"] &&
                [windowName hasSuffix:@"TextEffectsWindow"]) {
                if (!kbWindows) kbWindows = [NSMutableArray new];
                [kbWindows addObject:window];
            }
        } else {
            // UIRemoteKeyboardWindow
            if (windowName.length == 22 &&
                [windowName hasPrefix:@"UI"] &&
                [windowName hasSuffix:@"RemoteKeyboardWindow"]) {
                if (!kbWindows) kbWindows = [NSMutableArray new];
                [kbWindows addObject:window];
            }
        }
    }
    
    if (kbWindows.count == 1) {
        return kbWindows.firstObject;
    }
    
    return nil;
}

- (UIView *)_getKeyboardViewFromWindow:(UIWindow *)window
{
    /*
     iOS 6/7:
     UITextEffectsWindow
     UIPeripheralHostView << keyboard
     
     iOS 8:
     UITextEffectsWindow
     UIInputSetContainerView
     UIInputSetHostView << keyboard
     
     iOS 9:
     UIRemoteKeyboardWindow
     UIInputSetContainerView
     UIInputSetHostView << keyboard
     */
    if (!window) return nil;
    
    // Get the window
    NSString *windowName = NSStringFromClass(window.class);
    if (IOS9_LOWER) {
        // UITextEffectsWindow
        if (windowName.length != 19) return nil;
        if (![windowName hasPrefix:@"UI"]) return nil;
        if (![windowName hasSuffix:@"TextEffectsWindow"]) return nil;
    } else {
        // UIRemoteKeyboardWindow
        if (windowName.length != 22) return nil;
        if (![windowName hasPrefix:@"UI"]) return nil;
        if (![windowName hasSuffix:@"RemoteKeyboardWindow"]) return nil;
    }
    
    // Get the view
    if (IOS8_LOWER) {
        // UIPeripheralHostView
        for (UIView *view in window.subviews) {
            NSString *viewName = NSStringFromClass(view.class);
            if (viewName.length != 20) continue;
            if (![viewName hasPrefix:@"UI"]) continue;
            if (![viewName hasSuffix:@"PeripheralHostView"]) continue;
            return view;
        }
    } else {
        // UIInputSetContainerView
        for (UIView *view in window.subviews) {
            NSString *viewName = NSStringFromClass(view.class);
            if (viewName.length != 23) continue;
            if (![viewName hasPrefix:@"UI"]) continue;
            if (![viewName hasSuffix:@"InputSetContainerView"]) continue;
            // UIInputSetHostView
            for (UIView *subView in view.subviews) {
                NSString *subViewName = NSStringFromClass(subView.class);
                if (subViewName.length != 18) continue;
                if (![subViewName hasPrefix:@"UI"]) continue;
                if (![subViewName hasSuffix:@"InputSetHostView"]) continue;
                return subView;
            }
        }
    }
    
    return nil;
}

#pragma mark - Runtime

- (void)setIsPlusAutoRatation:(BOOL)isPlusAutoRatation
{
    objc_setAssociatedObject(self, @selector(isPlusAutoRatation), @(isPlusAutoRatation), OBJC_ASSOCIATION_ASSIGN);
}

- (BOOL)isPlusAutoRatation
{
    NSNumber *num = objc_getAssociatedObject(self, @selector(isPlusAutoRatation));
    if (num) {
        return [num boolValue];
    }
    else {
        return NO;
    }
}

- (void)setPlusOriginOrientation:(UIInterfaceOrientation)plusOriginOrientation
{
    objc_setAssociatedObject(self, @selector(plusOriginOrientation), @(plusOriginOrientation), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIInterfaceOrientation)plusOriginOrientation
{
    NSNumber *num = objc_getAssociatedObject(self, @selector(plusOriginOrientation));
    if (num) {
        return [num integerValue];
    }
    else {
        return UIInterfaceOrientationUnknown;
    }
}

- (UIInterfaceOrientation)preferredSupportedOrientation
{
    NSNumber *num = objc_getAssociatedObject(self, @selector(preferredSupportedOrientation));
    if (num) {
        return [num integerValue];
    }
    else {
        return UIInterfaceOrientationUnknown;
    }
}

- (void)setPreferredSupportedOrientation:(UIInterfaceOrientation)preferredSupportedOrientation
{
    objc_setAssociatedObject(self, @selector(preferredSupportedOrientation), @(preferredSupportedOrientation), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIInterfaceOrientationMask)preferredOrientationMask
{
    NSNumber *num = objc_getAssociatedObject(self, @selector(preferredOrientationMask));
    if (num) {
        return [num integerValue];
    }
    else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)setPreferredOrientationMask:(UIInterfaceOrientationMask)preferredOrientationMask
{
    objc_setAssociatedObject(self, @selector(preferredOrientationMask), @(preferredOrientationMask), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Override
/*
- (BOOL)shouldAutorotate
{
    return YES;
}

- (UIInterfaceOrientationMask) supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationLandscapeLeft;
}

- (BOOL)prefersStatusBarHidden
{
    return NO; //返回NO表示要显示，返回YES将hiden    默认隐藏
}
*/

@end
