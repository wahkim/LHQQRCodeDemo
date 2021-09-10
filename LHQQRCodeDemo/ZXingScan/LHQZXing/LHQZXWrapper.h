//
//  LHQZXWrapper.h
//  LHQQRCodeDemo
//
//  Created by Xhorse_iOS3 on 2021/9/6.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <ZXingObjC/ZXingObjC.h>
//#import <ZXingObjC/ZXQRCodeReader.h>

NS_ASSUME_NONNULL_BEGIN

@interface LHQZXWrapper : NSObject

///连续扫码，默认NO
@property (nonatomic, assign) BOOL continuous;

//相机启动完成
@property (nonatomic, copy) void (^onStarted)(void);

@property (nonatomic, assign) NSInteger  orientation;
@property (nonatomic, assign) CGRect videoLayerframe;

@property (nonatomic, assign) CGFloat scale;
@property (nonatomic, assign) int defaultFPS;

/**
初始化ZXing

@param preView 视频预览视图
@param success 返回识别结果,resultPoints 表示条码在图像scanImg上的坐标
@return 返回封装对象
*/
- (id)initWithPreView:(UIView*)preView success:(void(^)(ZXBarcodeFormat barcodeFormat,NSString *str,UIImage *scanImg,NSArray* resultPoints))success;

/**
 设置识别区域，不设置默认全屏识别

 @param scanRect 识别区域
 */
- (void)setScanRect:(CGRect)scanRect;

/*!
 *  开始扫码
 */
- (void)start;

/*!
 *  停止扫码
 */
- (void)stop;

/*!
 *  打开关闭闪光灯
 *
 *  @param on_off YES:打开闪光灯,NO:关闭闪光灯
 */
- (void)openTorch:(BOOL)on_off;

/*!
 *  根据闪光灯状态，自动切换
 */
- (void)openOrCloseTorch;


//最小缩放值
- (CGFloat)minZoomFactor;
//最大缩放值
- (CGFloat)maxZoomFactor;
// 改变缩放因子
- (void)changeFactor:(CGFloat)currentZoomFactor;

// 手动聚焦
- (void)focusAtPoint:(CGPoint)point;

/*!
 *  生成二维码
 *
 *  @param str  二维码字符串
 *  @param size 二维码图片大小
 *  @param format 码的类型
 *  @return 返回生成的图像
 */
+ (UIImage*)createCodeWithString:(NSString*)str size:(CGSize)size CodeFomart:(ZXBarcodeFormat)format;

/*!
 *  识别各种码图片
 *
 *  @param image 图像
 *  @param block 返回识别结果
 */
+ (void)recognizeImage:(UIImage*)image block:(void(^)(ZXBarcodeFormat barcodeFormat,NSString *str))block;

@end

NS_ASSUME_NONNULL_END
