//
//  LHQZXCapture.h
//  LHQQRCodeDemo
//
//  Created by Xhorse_iOS3 on 2021/9/6.
//

#import <Foundation/Foundation.h>
#import <ZXingObjC/ZXingObjC.h>
#import "LHQZXWrapper.h"
#import "LHQZXCaptureDelegate.h"

@protocol LBXZXCaptureDelegate, ZXReader;
@class ZXDecodeHints;

@interface LHQZXCapture : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate, CAAction>

@property (nonatomic, assign) int camera;
@property (nonatomic, strong) AVCaptureDevice *captureDevice;
@property (nonatomic, copy) NSString *captureToFilename;
@property (nonatomic, weak) id<LHQZXCaptureDelegate> delegate;
@property (nonatomic, assign) AVCaptureFocusMode focusMode;
@property (nonatomic, strong) ZXDecodeHints *hints;
@property (nonatomic, assign) CGImageRef lastScannedImage;
@property (nonatomic, assign) BOOL invert;
@property (nonatomic, strong, readonly) CALayer *layer;
@property (nonatomic, assign) BOOL mirror;
@property (nonatomic, strong, readonly) AVCaptureVideoDataOutput *output;
@property (nonatomic, strong) AVCaptureDeviceInput *input;
@property (nonatomic, strong) id<ZXReader> reader;
@property (nonatomic, assign) CGFloat rotation;
@property (nonatomic, assign) BOOL running;
@property (nonatomic, assign) CGRect scanRect;
@property (nonatomic, copy) NSString *sessionPreset;
@property (nonatomic, assign) BOOL torch;
@property (nonatomic, assign) CGAffineTransform transform;
@property (nonatomic, assign) CGFloat captureFramesPerSec;

@property (nonatomic, assign) int defaultFPS;

//相机启动完成
@property (nonatomic, copy) void (^onStarted)(void);

- (int)back;
- (int)front;
- (BOOL)hasBack;
- (BOOL)hasFront;
- (BOOL)hasTorch;

- (void)setTorch:(BOOL)torch;

- (void)changeTorch;

- (CALayer *)binary;
- (void)setBinary:(BOOL)on_off;

- (CALayer *)luminance;
- (void)setLuminance:(BOOL)on_off;

- (void)hard_stop;
- (void)order_skip;
- (void)start;
- (void)stop;

//最小缩放值
- (CGFloat)minZoomFactor;
//最大缩放值
- (CGFloat)maxZoomFactor;

@end

