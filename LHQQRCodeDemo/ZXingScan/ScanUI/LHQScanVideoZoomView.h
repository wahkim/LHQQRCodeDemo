//
//  LHQScanVideoZoomView.h
//  LHQQRCodeDemo
//
//  Created by Xhorse_iOS3 on 2021/9/6.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LHQScanVideoZoomView : UIView

/**
 @brief 控件值变化
 */
@property (nonatomic, copy,nullable) void (^block)(float value);

- (void)setMaximunValue:(CGFloat)value;

@end

NS_ASSUME_NONNULL_END
