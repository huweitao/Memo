//
//  UIWebView+DelegateHooker.m
//  AppGetter
//
//  Created by huweitao on 17/2/15.
//  Copyright © 2017年 huweitao. All rights reserved.
//

#import "UIWebView+DelegateHooker.h"
#import "JRSwizzle.h"
#import <objc/runtime.h>

const char *keyFakeDelegate;

@interface UIWebView()

@property (nonatomic, weak) id<UIWebViewDelegate>fakeDelegate;

@end

@implementation UIWebView (DelegateHooker)



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
    
    // 添加新方法以及实现到需要被swizzle的class里
    if (!class_addMethod(origClass,newSel,class_getMethodImplementation(newClass, newSel),method_getTypeEncoding(newMethod))) {
        NSLog(@"New method %@ can not be added in class %@",NSStringFromSelector(newSel), [newClass class]);
        return false;
    }
    
    method_exchangeImplementations(class_getInstanceMethod(origClass, origSel), class_getInstanceMethod(origClass, newSel));
    return true;
}

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *error = nil;
        [UIWebView jr_swizzleMethod:@selector(setDelegate:) withMethod:@selector(swz_setDelegate:) error:&error];
        if (error) {
            NSLog(@"UIWebView Swizzling Method 失败：%@",error);
        }
    });
}

- (void)swz_setDelegate:(id<UIWebViewDelegate>)delegate
{
//    self.fakeDelegate = delegate;
    NSLog(@"Delegate Owner %@",delegate);
    if ([delegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]) {
        NSLog(@"Respond Delegate");
        // 方案1
        In_SwizzleMethod([delegate class], @selector(webView:shouldStartLoadWithRequest:navigationType:), [self class], @selector(swz_webView:shouldStartLoadWithRequest:navigationType:));
        
        // 方案2
//        exchangeMethod([delegate class], @selector(webView:shouldStartLoadWithRequest:navigationType:), [self class], @selector(swz_webView:shouldStartLoadWithRequest:navigationType:));
//        
//        // 方案3
//        addSelectorInOriginal([delegate class], [self class], @selector(swz_webView:shouldStartLoadWithRequest:navigationType:));
//        NSError *err = nil;
//        [[delegate class] jr_swizzleMethod:@selector(webView:shouldStartLoadWithRequest:navigationType:) withMethod:@selector(swz_webView:shouldStartLoadWithRequest:navigationType:) error:&err];
//        if (err) {
//            NSLog(@"Swizzling Method 失败：%@",err);
//        }
    }
    
    [self swz_setDelegate:delegate];
}

- (BOOL)swz_webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSLog(@"Delegate Hooker!");
    return [self swz_webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
}

#pragma mark - Runtime

- (void)setFakeDelegate:(id<UIWebViewDelegate>)fakeDelegate
{
    objc_setAssociatedObject(self, &keyFakeDelegate, fakeDelegate, OBJC_ASSOCIATION_ASSIGN);
}

- (id<UIWebViewDelegate>)fakeDelegate
{
    return objc_getAssociatedObject(self, &keyFakeDelegate);
}

#pragma mark - Borrowed

void exchangeMethod(Class originalClass, SEL original_SEL, Class replacedClass, SEL replaced_SEL)
{
    // 1.这里是为了防止App中多次(偶数次)调用setDelegete时,导致后面的IMP替换又回到没替换之前的结果了!(这步是猜测,没来急在sample中测试)
    static NSMutableArray * classList =nil;
    if (classList == nil) {
        classList = [[NSMutableArray alloc] init];
    }
    NSString * className = [NSString stringWithFormat:@"%@__%@", NSStringFromClass(originalClass), NSStringFromSelector(original_SEL)];
    for (NSString * item in classList) {
        if ([className isEqualToString:item]) {
            NSLog(@"tweak : setDelegate 2nd for (%@)==> return!", className);
            return;
        }
    }
    NSLog(@"tweak : setDelegate 1st for (%@)==> return!", className);
    [classList addObject:className];
    
    // 2.原delegate 方法
    Method originalMethod = class_getInstanceMethod(originalClass, original_SEL);
    assert(originalMethod);
    //IMP originalMethodIMP = method_getImplementation(originalMethod);
    
    // 3.新delegate 方法
    Method replacedMethod = class_getInstanceMethod(replacedClass, replaced_SEL);
    assert(replacedMethod);
    IMP replacedMethodIMP = method_getImplementation(replacedMethod);
    
    // 4.先向实现delegate的classB添加新的方法
    if (!class_addMethod(originalClass, replaced_SEL, replacedMethodIMP, method_getTypeEncoding(replacedMethod))) {
        NSLog(@"tweak : class_addMethod ====> Error! (replaced_SEL)");
    }
    else
    {
        NSLog(@"tweak : class_addMethod ====> OK! (replaced_SEL)");
    }
    
    // 5.重新拿到添加被添加的method,这部是关键(注意这里originalClass, 不replacedClass)
    Method newMethod = class_getInstanceMethod(originalClass, replaced_SEL);
    //IMP newMethodIMP = method_getImplementation(newMethod);
    
    // 6.正式交换这两个函数指针的实现
    method_exchangeImplementations(originalMethod, newMethod);
    
    // 7.如果把第6步换成下面的方法,或者去掉5.6两步直接用下面的方法试试,有惊喜~
    //method_exchangeImplementations(originalMethod, replacedMethod);
    
}

// JRSwizzle只能swizzle同一个class的方法，所以这里动态添加一个方法；
static inline void addSelectorInOriginal(Class originalClass, Class replacedClass, SEL replaced_SEL)
{
    Method replacedMethod = class_getInstanceMethod(replacedClass, replaced_SEL);
    assert(replacedMethod);
    IMP replacedMethodIMP = method_getImplementation(replacedMethod);
    
    // 向实现delegate的classB添加新的方法
    if (!class_addMethod(originalClass, replaced_SEL, replacedMethodIMP, method_getTypeEncoding(replacedMethod))) {
        NSLog(@"tweak : class_addMethod ====> Error! (replaced_SEL)");
    }
    else
    {
        NSLog(@"tweak : class_addMethod ====> OK! (replaced_SEL)");
    }
}

@end
