//
//  FloatView.m
//  FloatView
//
//  Created by wangrui on 2017/3/16.
//  Copyright © 2017年 wangrui. All rights reserved.
//

#import "FloatView.h"
#import <objc/runtime.h>

#define NavBarBottom 64
#define TabBarHeight 49

static char kJLActionHandlerTapBlockKey;
static char kJLActionHandlerTapGestureKey;

@implementation FloatView


- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self = [[FloatView alloc] initWithImage:[UIImage imageNamed:@"FloatBonus"]];
        self.userInteractionEnabled = YES;
        self.stayEdgeDistance = 5;
        self.stayAnimateTime = 0.3;
        [self initStayLocation];
    }
    return self;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    // 先让悬浮图片的alpha为1
    self.alpha = 1;
    // 获取手指当前的点
    UITouch * touch = [touches anyObject];
    CGPoint  curPoint = [touch locationInView:self];
    
    CGPoint prePoint = [touch previousLocationInView:self];
    
    // x方向移动的距离
    CGFloat deltaX = curPoint.x - prePoint.x;
    CGFloat deltaY = curPoint.y - prePoint.y;
    CGRect frame = self.frame;
    frame.origin.x += deltaX;
    frame.origin.y += deltaY;
    self.frame = frame;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self moveStay];
    // 这里可以设置过几秒，alpha减小
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(self) pThis = weakSelf;
//        [pThis animateHidden];
    });
}

#pragma mark - 设置浮动图片的初始位置
- (void)initStayLocation
{
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    CGRect frame = self.frame;
    CGFloat stayWidth = frame.size.width;
    CGFloat initX = screenWidth - self.stayEdgeDistance - stayWidth;
    CGFloat initY = (screenHeight - NavBarBottom - TabBarHeight) * (2.0 / 3.0) + NavBarBottom;
    frame.origin.x = initX;
    frame.origin.y = initY;
    self.frame = frame;
}

#pragma mark - 根据 stayModel 来移动悬浮图片
- (void)moveStay
{
    bool isLeft = [self judgeLocationIsLeft];
    switch (_stayMode) {
        case STAYMODE_LEFTANDRIGHT:
        {
            if (isLeft == YES) {
                [self moveToLeft];
            } else {
                [self moveToRight];
            }
        }
            break;
        case STAYMODE_LEFT:
        {
            [self moveToLeft];
        }
            break;
        case STAYMODE_RIGHT:
        {
            [self moveToRight];
        }
            break;
        default:
            break;
    }
}

#pragma mark - 设置悬浮图片以动画的方式隐藏
- (void)animateHidden
{
    {
        [UIView animateWithDuration:0.5 animations:^{
            self.alpha = _stayAlpha;
        }];
    }
}

#pragma mark - 移动当前view到屏幕左边
- (void)moveToLeft
{
    CGRect frame = self.frame;
    frame.origin.x = self.stayEdgeDistance;
    frame.origin.y = [self moveSafeLocationY];
    [UIView animateWithDuration:_stayAnimateTime animations:^{
        self.frame = frame;
    }];
}

#pragma mark - 移动当前view到屏幕右边
- (void)moveToRight
{
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGRect frame = self.frame;
    CGFloat stayWidth = frame.size.width;
    frame.origin.x = screenWidth - self.stayEdgeDistance - stayWidth;
    frame.origin.y = [self moveSafeLocationY];
    [UIView animateWithDuration:_stayAnimateTime animations:^{
        self.frame = frame;
    }];
}

#pragma mark - 设置悬浮图片不高于屏幕顶端，不低于屏幕底端
- (CGFloat)moveSafeLocationY
{
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    CGRect frame = self.frame;
    CGFloat stayHeight = frame.size.height;
    // 当前view的y值
    CGFloat curY = self.frame.origin.y;
    CGFloat destinationY = frame.origin.y;
    // 悬浮图片的最顶端Y值
    CGFloat stayMostTopY = NavBarBottom + _stayEdgeDistance;
    if (curY <= stayMostTopY) {
        destinationY = stayMostTopY;
    }
    // 悬浮图片的低端Y值
    CGFloat stayMostBottomY = screenHeight - TabBarHeight - _stayEdgeDistance - stayHeight;
    if (curY >= stayMostBottomY) {
        destinationY = stayMostBottomY;
    }
    return destinationY;
}

#pragma mark -  判断当前view是否在父界面的左边
- (bool)judgeLocationIsLeft
{
    // 手机屏幕中间位置x值
    CGFloat middleX = [UIScreen mainScreen].bounds.size.width / 2.0;
    // 当前view的x值
    CGFloat curX = self.frame.origin.x;
    if (curX <= middleX) {
        return YES;
    } else {
        return NO;
    }
}

#pragma mark -  设置简单的轻点 block事件
- (void)setTapActionWithBlock:(void (^)(void))block
{
    UITapGestureRecognizer *gesture = objc_getAssociatedObject(self, &kJLActionHandlerTapGestureKey);
    
    if (!gesture)
    {
        gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(__handleActionForTapGesture:)];
        [self addGestureRecognizer:gesture];
        objc_setAssociatedObject(self, &kJLActionHandlerTapGestureKey, gesture, OBJC_ASSOCIATION_RETAIN);
    }
    
    objc_setAssociatedObject(self, &kJLActionHandlerTapBlockKey, block, OBJC_ASSOCIATION_COPY);
}

- (void)__handleActionForTapGesture:(UITapGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateRecognized)
    {
        void(^action)(void) = objc_getAssociatedObject(self, &kJLActionHandlerTapBlockKey);
        if (action)
        {
            // 先让悬浮图片的alpha为1
            self.alpha = 1;
            [self moveStay];
            action();
        }
    }
}

#pragma mark - getter / setter
- (void)setStayAlpha:(CGFloat)stayAlpha
{
    if (stayAlpha <= 0) {
        stayAlpha = 1;
    }
    _stayAlpha = stayAlpha;
}

@end