//
//  LHQScanView.h
//  LHQQRCodeDemo
//
//  Created by Xhorse_iOS3 on 2021/9/6.
//

#import <UIKit/UIKit.h>
#import "LHQScanLineAnimation.h"
#import "LHQScanNetAnimation.h"
#import "LHQScanViewStyle.h"

NS_ASSUME_NONNULL_BEGIN

@interface LHQScanView : UIView

//扫码区域各种参数
@property (nonatomic, strong) LHQScanViewStyle* viewStyle;
/**
 @brief  初始化
 @param frame 位置大小
 @param style 类型

 @return instancetype
 */
-(id)initWithFrame:(CGRect)frame style:(LHQScanViewStyle*)style;

/**
 *  设备启动中文字提示
 */
- (void)startDeviceReadyingWithText:(NSString*)text;

/**
 *  设备启动完成
 */
- (void)stopDeviceReadying;

/**
 *  开始扫描动画
 */
- (void)startScanAnimation;

/**
 *  结束扫描动画
 */
- (void)stopScanAnimation;

//

/**
 @brief  根据矩形区域，获取Native扫码识别兴趣区域
 @param view  视频流显示UIView
 @param style 效果界面参数
 @return 识别区域
 */
+ (CGRect)getScanRectWithPreView:(UIView*)view style:(LHQScanViewStyle*)style;



/**
 根据矩形区域，获取ZXing库扫码识别兴趣区域

 @param view 视频流显示视图
 @param style 效果界面参数
 @return 识别区域
 */
+ (CGRect)getZXingScanRectWithPreView:(UIView*)view style:(LHQScanViewStyle*)style;

@end

NS_ASSUME_NONNULL_END
