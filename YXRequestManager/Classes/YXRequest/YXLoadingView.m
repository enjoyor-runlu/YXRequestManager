//
//  YXLoadingView.m
//  Pods
//
//  Created by jiaguoshang on 2017/10/31.
//
//

#import "YXLoadingView.h"

static YXLoadingView *loadingView = nil;

@interface YXLoadingView ()

@property (nonatomic, strong) UIView *floatingView;//蒙层

@property (nonatomic, strong) UIView *bottomView;//底层view

@property (nonatomic, strong) UIImageView *rotationView;//旋转view

@property (nonatomic, strong) UIWindow *iWindow;//Window

@end

@implementation YXLoadingView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self addSubview:self.floatingView];
        [self addSubview:self.bottomView];
        [self.bottomView addSubview:self.rotationView];
    }
    return self;
}

- (UIWindow *)iWindow
{
    if (!_iWindow) {
        _iWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _iWindow.windowLevel = UIWindowLevelAlert;
        _iWindow.opaque = NO;
    }
    return _iWindow;
}

- (UIView *)floatingView
{
    if (!_floatingView) {
        _floatingView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _floatingView.backgroundColor = [UIColor colorWithRed:46 / 255.0 green:49 / 255.0 blue:51 / 255.0 alpha:0.9];
        _floatingView.opaque = NO;
        
    }
    return _floatingView;
}

- (UIView *)bottomView
{
    if (!_bottomView) {
        _bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100.f, 100.f)];
        _bottomView.center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, [UIScreen mainScreen].bounds.size.height / 2);
        _bottomView.backgroundColor = [UIColor whiteColor];
        _bottomView.layer.cornerRadius = 3.f;
        _bottomView.layer.masksToBounds = YES;
    }
    return _bottomView;
}

- (UIImageView *)rotationView
{
    if (!_rotationView) {
        _rotationView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 24.f, 24.f)];
        _rotationView.center = CGPointMake(50.f, 50.f);
        UIImage *image = [UIImage imageNamed:@"common_icon_loading"];
        _rotationView.image = image;
    }
    return _rotationView;
}

+ (void)show
{
    if (!loadingView) {
        YXLoadingView *onLoadingView = [[YXLoadingView alloc] init];
        loadingView = onLoadingView;
    }
    [loadingView doAnimation];
}

- (void)doAnimation
{
    self.floatingView.alpha = 0.f;
    [UIView animateWithDuration:.3f animations:^{
        self.floatingView.alpha = 0.9f;
    }];
    [self.iWindow addSubview:self];
    [self.iWindow makeKeyAndVisible];
    CABasicAnimation *animation = [ CABasicAnimation
                                   animationWithKeyPath: @"transform"];
    animation.fromValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
    
    //围绕Z轴旋转，垂直与屏幕
    animation.toValue = [ NSValue valueWithCATransform3D:
                         
                         CATransform3DMakeRotation(M_PI, 0.0, 0.0, 1.0)];
    animation.duration = 0.5;
    //旋转效果累计，先转180度，接着再旋转180度，从而实现360旋转
    animation.cumulative = YES;
    animation.repeatCount = 1000;
    [loadingView.rotationView.layer addAnimation:animation forKey:nil];
}

+ (void)hide
{
    [loadingView.rotationView.layer removeAllAnimations];
    [loadingView removeFromSuperview];
    loadingView.iWindow = nil;
    [[[[UIApplication sharedApplication] delegate] window] makeKeyAndVisible];
}


@end
