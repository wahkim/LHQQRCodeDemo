//
//  LHQScanLineAnimation.m
//  LHQQRCodeDemo
//
//  Created by Xhorse_iOS3 on 2021/9/6.
//

#import "LHQScanLineAnimation.h"

@interface LHQScanLineAnimation()
{
    int num;
    BOOL down;
    NSTimer * timer;
    
    BOOL isAnimationing;
}

@property (nonatomic,assign) CGRect animationRect;

@end

@implementation LHQScanLineAnimation


- (void)stepAnimation
{
    if (!isAnimationing) {
        return;
    }
   
    CGFloat leftx = _animationRect.origin.x + 5;
    CGFloat width = _animationRect.size.width - 10;
    
    self.frame = CGRectMake(leftx, _animationRect.origin.y + 8, width, 8);
    
    self.alpha = 0.0;
    
    self.hidden = NO;
    
    
    [UIView animateWithDuration:0.5 animations:^{
        self.alpha = 1.0;
        
    } completion:^(BOOL finished)
     {
         
     }];
    
    [UIView animateWithDuration:3 animations:^{
        CGFloat leftx = self.animationRect.origin.x + 5;
        CGFloat width = self.animationRect.size.width - 10;
        
        self.frame = CGRectMake(leftx, self.animationRect.origin.y + self.animationRect.size.height - 8, width, 4);
        
    } completion:^(BOOL finished)
     {
         self.hidden = YES;
         [self performSelector:@selector(stepAnimation) withObject:nil afterDelay:0.3];
     }];
}



- (void)startAnimatingWithRect:(CGRect)animationRect InView:(UIView *)parentView Image:(UIImage*)image
{
    if (isAnimationing) {
        return;
    }
    
    isAnimationing = YES;

    
    self.animationRect = animationRect;
    down = YES;
    num =0;
    
    CGFloat centery = CGRectGetMinY(animationRect) + CGRectGetHeight(animationRect)/2;
    CGFloat leftx = animationRect.origin.x + 5;
    CGFloat width = animationRect.size.width - 10;
    
    self.frame = CGRectMake(leftx, centery+2*num, width, 2);
    self.image = image;
    
    [parentView addSubview:self];
    
    [self startAnimating_UIViewAnimation];
    
//    [self startAnimating_NSTimer];
    
    
}

- (void)startAnimating_UIViewAnimation
{
     [self stepAnimation];
}

- (void)startAnimating_NSTimer
{
    timer = [NSTimer scheduledTimerWithTimeInterval:.02 target:self selector:@selector(scanLineAnimation) userInfo:nil repeats:YES];
}

-(void)scanLineAnimation
{
    CGFloat centery = CGRectGetMinY(_animationRect) + CGRectGetHeight(_animationRect)/2;
    CGFloat leftx = _animationRect.origin.x + 5;
    CGFloat width = _animationRect.size.width - 10;
    
    if (down)
    {
        num++;
        
        self.frame = CGRectMake(leftx, centery+2*num, width, 2);
        
        if (centery+2*num > (CGRectGetMinY(_animationRect) + CGRectGetHeight(_animationRect) - 5 ) )
        {
            down = NO;
        }
    }
    else {
        num --;
        self.frame = CGRectMake(leftx, centery+2*num, width, 2);
        if (centery+2*num < (CGRectGetMinY(_animationRect) + 5 ) )
        {
            down = YES;
        }
    }
}

- (void)dealloc
{
    [self stopAnimating];
}

- (void)stopAnimating
{
    if (isAnimationing) {
        
        isAnimationing = NO;
        
        if (timer) {
            [timer invalidate];
            timer = nil;
        }
        
        [self removeFromSuperview];
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}


@end
