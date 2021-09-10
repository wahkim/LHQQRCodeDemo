//
//  LHQZXCapture.m
//  LHQQRCodeDemo
//
//  Created by Xhorse_iOS3 on 2021/9/6.
//

#import "LHQZXCapture.h"

@interface LHQZXCapture ()

@property (nonatomic, strong) CALayer *binaryLayer;
@property (nonatomic, assign) BOOL cameraIsReady;
@property (nonatomic, assign) int captureDeviceIndex;
@property (nonatomic, strong) dispatch_queue_t captureQueue;
@property (nonatomic, assign) BOOL hardStop;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *layer;
@property (nonatomic, strong) CALayer *luminanceLayer;
@property (nonatomic, assign) int orderInSkip;
@property (nonatomic, assign) int orderOutSkip;
@property (nonatomic, assign) BOOL onScreen;
@property (nonatomic, strong) AVCaptureVideoDataOutput *output;
@property (nonatomic, strong) AVCaptureSession *session;

@property (nonatomic, assign) BOOL heuristic;
@property (nonatomic, copy) dispatch_queue_t parallelQueue;

@end

@implementation LHQZXCapture

- (LHQZXCapture *)init {
  if (self = [super init]) {
    _captureDeviceIndex = -1;
    _captureQueue = dispatch_queue_create("com.zxing.captureQueue", NULL);
    _focusMode = AVCaptureFocusModeContinuousAutoFocus;
    _hardStop = NO;
    _hints = [ZXDecodeHints hints];
    _lastScannedImage = NULL;
    _onScreen = NO;
    _orderInSkip = 0;
    _orderOutSkip = 0;
    _captureFramesPerSec = 1.0f;

    if (NSClassFromString(@"ZXMultiFormatReader")) {
      _reader = [NSClassFromString(@"ZXMultiFormatReader") performSelector:@selector(reader)];
    }

    _rotation = 0.0f;
    _running = NO;
    _sessionPreset = [self canSetSessionPreset];
    _transform = CGAffineTransformIdentity;
    _scanRect = CGRectZero;
      
    _parallelQueue = dispatch_queue_create("com.zxing.parallelQueue", DISPATCH_QUEUE_CONCURRENT);
  }

  return self;
}

- (void)dealloc {
  if (_lastScannedImage) {
    CGImageRelease(_lastScannedImage);
  }

  if (_session && _session.inputs) {
    for(AVCaptureInput *input in _session.inputs) {
      [_session removeInput:input];
    }
      
      [self.layer removeFromSuperlayer];
  }

  if (_session && _session.outputs) {
    for(AVCaptureOutput *output in _session.outputs) {
      [_session removeOutput:output];
    }
  }
}

#pragma mark - Lazy Load

- (CALayer *)layer {
    AVCaptureVideoPreviewLayer *layer = (AVCaptureVideoPreviewLayer *)_layer;
    if (!_layer) {
        layer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
//        layer.affineTransform = self.transform;
//        layer.delegate = self;
//        layer.videoGravity = AVLayerVideoGravityResizeAspect;
        layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        
        _layer = layer;
    }
    return layer;
}

- (AVCaptureVideoDataOutput *)output {
    if (!_output) {
        _output = [[AVCaptureVideoDataOutput alloc] init];
        [_output setVideoSettings:@{
            (NSString *)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA]
        }];
        [_output setAlwaysDiscardsLateVideoFrames:YES];
        [_output setSampleBufferDelegate:self queue:_captureQueue];
        
        [self.session addOutput:_output];
    }
    
    return _output;
}

#pragma mark - Setter Method

- (void)setCamera:(int)camera {
    if (_camera != camera) {
        _camera = camera;
        self.captureDeviceIndex = -1;
        self.captureDevice = nil;
        [self replaceInput];
    }
}

- (void)setDelegate:(id<LHQZXCaptureDelegate>)delegate {
    _delegate = delegate;
    
    //  if (delegate) {
    //    self.hardStop = NO;
    //  }
    //  [self startStop];
}

- (void)setFocusMode:(AVCaptureFocusMode)focusMode {
    if ([self.input.device isFocusModeSupported:focusMode] && self.input.device.focusMode != focusMode) {
        _focusMode = focusMode;
        
        [self.input.device lockForConfiguration:nil];
        self.input.device.focusMode = focusMode;
        [self.input.device unlockForConfiguration];
    }
}

- (void)setLastScannedImage:(CGImageRef)lastScannedImage {
    if (_lastScannedImage) {
        CGImageRelease(_lastScannedImage);
    }
    
    if (lastScannedImage) {
        CGImageRetain(lastScannedImage);
    }
    
    _lastScannedImage = lastScannedImage;
}

- (void)setMirror:(BOOL)mirror {
    if (_mirror != mirror) {
        _mirror = mirror;
        if (self.layer) {
            CGAffineTransform transform = self.transform;
            transform.a = - transform.a;
            self.transform = transform;
            [self.layer setAffineTransform:self.transform];
        }
    }
}

- (void)setTorch:(BOOL)torch {
    _torch = torch;
    if ([self.input.device hasTorch]) {
        [self.input.device lockForConfiguration:nil];
        self.input.device.torchMode = self.torch ? AVCaptureTorchModeOn : AVCaptureTorchModeOff;
        [self.input.device unlockForConfiguration];
    }
}

- (void)changeTorch
{
    AVCaptureTorchMode torch = self.input.device.torchMode;
    
    switch (self.input.device.torchMode) {
        case AVCaptureTorchModeAuto:
            break;
        case AVCaptureTorchModeOff:
            torch = AVCaptureTorchModeOn;
            break;
        case AVCaptureTorchModeOn:
            torch = AVCaptureTorchModeOff;
            break;
        default:
            break;
    }
    
    [self.input.device lockForConfiguration:nil];
    self.input.device.torchMode = torch;
    [self.input.device unlockForConfiguration];
}


- (void)setTransform:(CGAffineTransform)transform {
    _transform = transform;
    [self.layer setAffineTransform:transform];
}

#pragma mark - Back, Front, Torch

- (int)back {
    return 1;
}

- (int)front {
    return 0;
}

- (BOOL)hasFront {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    return [devices count] > 1;
}

- (BOOL)hasBack {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    return [devices count] > 0;
}

- (BOOL)hasTorch {
    if ([self device]) {
        return [self device].hasTorch;
    } else {
        return NO;
    }
}

#pragma mark - Binary

- (CALayer *)binary {
    return self.binaryLayer;
}

- (void)setBinary:(BOOL)on {
    if (on && !self.binaryLayer) {
        self.binaryLayer = [CALayer layer];
    } else if (!on && self.binaryLayer) {
        self.binaryLayer = nil;
    }
}

#pragma mark - Luminance

- (CALayer *)luminance {
    return self.luminanceLayer;
}

- (void)setLuminance:(BOOL)on {
    if (on && !self.luminanceLayer) {
        self.luminanceLayer = [CALayer layer];
    } else if (!on && self.luminanceLayer) {
        self.luminanceLayer = nil;
    }
}

#pragma mark - Start, Stop

- (void)hard_stop {
    self.hardStop = YES;
    
    if (self.running) {
        [self stop];
    }
}

- (void)order_skip {
    self.orderInSkip = 1;
    self.orderOutSkip = 1;
}

- (void)start {
    
    if (self.running) {
        return;
    }
    
    if (self.hardStop) {
        return;
    }
    
//    if (self.delegate || self.luminanceLayer || self.binaryLayer) {
//        (void)[self output];
//    }
    
    if (!self.session.running) {
        static int i = 0;
        if (++i == -2) {
            abort();
        }
        
        [self.session startRunning];
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//
//            [self.session startRunning];
//
//            dispatch_async(dispatch_get_main_queue(), ^{
//
//                if (self.onStarted) {
//                    self.onStarted();
//                }
//            });
//
//        });
       
    }
    self.running = YES;
}

- (void)stop
{
    if (!self.running) {
        return;
    }
    
    if (self.session.running) {
        // [self.layer removeFromSuperlayer];
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            [self.session stopRunning];
//        });
        [self.session stopRunning];
    }
    self.running = NO;
}

#pragma mark - FPS

- (void)setDefaultFPS:(int)defaultFPS {
    _defaultFPS = defaultFPS;

    CMTime frameDuration = CMTimeMake(1, defaultFPS);
    BOOL frameRateSupported = NO;
    
    for (AVFrameRateRange *range in [self.captureDevice.activeFormat videoSupportedFrameRateRanges]) {
        if (CMTIME_COMPARE_INLINE(frameDuration, >=, range.minFrameDuration) &&
            CMTIME_COMPARE_INLINE(frameDuration, <=, range.maxFrameDuration)) {
            frameRateSupported = YES;
        }
    }
    
    NSError *error = nil;
    if (frameRateSupported && [self.captureDevice lockForConfiguration:&error]) {
        [self.captureDevice setActiveVideoMaxFrameDuration:frameDuration];
        [self.captureDevice setActiveVideoMinFrameDuration:frameDuration];
        [self.captureDevice unlockForConfiguration];
    }
}

#pragma mark - Zoom

//最小缩放值
- (CGFloat)minZoomFactor
{
    CGFloat minZoomFactor = 1.0;
    if (@available(iOS 11.0, *)) {
        minZoomFactor = self.device.minAvailableVideoZoomFactor;
    }
    return minZoomFactor;
}
 
//最大缩放值
- (CGFloat)maxZoomFactor
{
    CGFloat maxZoomFactor = self.device.activeFormat.videoMaxZoomFactor;
    if (@available(iOS 11.0, *)) {
        maxZoomFactor = self.device.maxAvailableVideoZoomFactor;
    }
    
    if (maxZoomFactor > 6.0) {
        maxZoomFactor = 6.0;
    }
    return maxZoomFactor;
}

#pragma mark - CAAction

- (id<CAAction>)actionForLayer:(CALayer *)_layer forKey:(NSString *)event {
    [CATransaction setValue:[NSNumber numberWithFloat:0.0f] forKey:kCATransactionAnimationDuration];
    
    if ([event isEqualToString:kCAOnOrderIn] || [event isEqualToString:kCAOnOrderOut]) {
        return self;
    }
    
    return nil;
}

- (void)runActionForKey:(NSString *)key object:(id)anObject arguments:(NSDictionary *)dict {
    if ([key isEqualToString:kCAOnOrderIn]) {
        if (self.orderInSkip) {
            self.orderInSkip--;
            return;
        }
        
        self.onScreen = YES;
        //    [self startStop];
    } else if ([key isEqualToString:kCAOnOrderOut]) {
        if (self.orderOutSkip) {
            self.orderOutSkip--;
            return;
        }
        
        self.onScreen = NO;
        //    [self startStop];
    }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {

    static NSInteger sampleBufferNums = 0;

    sampleBufferNums++;

    if (sampleBufferNums != 2) {
        return;
    }
    sampleBufferNums = 0;

    @autoreleasepool {
        if (!self.cameraIsReady) {
            self.cameraIsReady = YES;
            if ([self.delegate respondsToSelector:@selector(captureCameraIsReady:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate LHQCaptureCameraIsReady:self];
                });
            }
        }

        if (!self.captureToFilename && !self.luminanceLayer && !self.binaryLayer && !self.delegate) {
            return;
        }
        /// 每秒处理 _captureFramesPerSec个帧
        float kMinMargin = 1.0 / _captureFramesPerSec;

        // Gets the timestamp for each frame.
        CMTime presentTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);

        static double curFrameTimeStamp = 0;
        static double lastFrameTimeStamp = 0;

        curFrameTimeStamp = (double)presentTimeStamp.value / presentTimeStamp.timescale;

        if (curFrameTimeStamp - lastFrameTimeStamp > kMinMargin) {
            lastFrameTimeStamp = curFrameTimeStamp;
            
            CVImageBufferRef videoFrame = CMSampleBufferGetImageBuffer(sampleBuffer);

            CGImageRef videoFrameImage = [ZXCGImageLuminanceSource createImageFromBuffer:videoFrame];
            CGImageRef rotatedImage = [self createRotatedImage:videoFrameImage degrees:self.rotation];
            CGImageRelease(videoFrameImage);

            // If scanRect is set, crop the current image to include only the desired rect
            if (!CGRectIsEmpty(self.scanRect)) {
                CGImageRef croppedImage = CGImageCreateWithImageInRect(rotatedImage, self.scanRect);
                CFRelease(rotatedImage);
                rotatedImage = croppedImage;
            }

            self.lastScannedImage = rotatedImage;

            if (self.captureToFilename) {
                NSURL *url = [NSURL fileURLWithPath:self.captureToFilename];
                CGImageDestinationRef dest = CGImageDestinationCreateWithURL((__bridge CFURLRef)url, (__bridge CFStringRef)@"public.png", 1, nil);
                CGImageDestinationAddImage(dest, rotatedImage, nil);
                CGImageDestinationFinalize(dest);
                CFRelease(dest);
                self.captureToFilename = nil;
            }

            ZXCGImageLuminanceSource *source = [[ZXCGImageLuminanceSource alloc] initWithCGImage:rotatedImage];
            CGImageRelease(rotatedImage);

            if (self.luminanceLayer) {
                CGImageRef image = source.image;
                CGImageRetain(image);
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0), dispatch_get_main_queue(), ^{
                    self.luminanceLayer.contents = (__bridge id)image;
                    CGImageRelease(image);
                });
            }


            if (self.binaryLayer || self.delegate)
            {
                ZXHybridBinarizer *binarizer = [[ZXHybridBinarizer alloc] initWithSource:self.invert ? [source invert] : source];

                if (self.binaryLayer)
                {
                    CGImageRef image = [binarizer createImage];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0), dispatch_get_main_queue(), ^{
                        self.binaryLayer.contents = (__bridge id)image;
                        CGImageRelease(image);
                    });
                }
                

                if (self.delegate)
                {

                    ZXBinaryBitmap *bitmap = [[ZXBinaryBitmap alloc] initWithBinarizer:binarizer];

                    NSError *error;
                    ZXResult *result = [self.reader decode:bitmap hints:self.hints error:&error];
                    if (result) {
                        //            CGImageRef iOffscreen = CGBitmapContextCreateImage(context);


                        //            NSLog(@"%@",result.resultPoints);

                        dispatch_async(dispatch_get_main_queue(), ^{
                            UIImage* image = [UIImage imageWithCGImage: self.lastScannedImage];
                            [self.delegate captureResult:self result:result scanImage:image];
                        });
                    }
                }
            }
        }
        


    }
}

//+ (ZXResult *)regocnizeImage:(UIImage*)image
//{
//    ZXCGImageLuminanceSource *source = [[ZXCGImageLuminanceSource alloc] initWithCGImage:image.CGImage];
//
//    ZXHybridBinarizer *binarizer = [[ZXHybridBinarizer alloc] initWithSource: source];
//
//    ZXBinaryBitmap *bitmap = [[ZXBinaryBitmap alloc] initWithBinarizer:binarizer];
//
//    NSError *error;
//
//    id<ZXReader> reader;
//
//    if (NSClassFromString(@"ZXMultiFormatReader")) {
//        reader = [NSClassFromString(@"ZXMultiFormatReader") performSelector:@selector(reader)];
//    }
//
//    ZXDecodeHints *_hints = [ZXDecodeHints hints];
//    ZXResult *result = [reader decode:bitmap hints:_hints error:&error];
//
//    return result;
//}


//- (void)captureOutput:(AVCaptureOutput *)captureOutput
//didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
//       fromConnection:(AVCaptureConnection *)connection {
//  if (!self.running) return;
//
//  @autoreleasepool {
//    if (!self.cameraIsReady) {
//      self.cameraIsReady = YES;
//      if ([self.delegate respondsToSelector:@selector(captureCameraIsReady:)]) {
//        dispatch_async(dispatch_get_main_queue(), ^{
////          [self.delegate captureCameraIsReady:self];
//        });
//      }
//    }
//
//    if (!self.captureToFilename && !self.luminanceLayer && !self.binaryLayer && !self.delegate) {
//      return;
//    }
//
//    // reduce CPU usage by around 30%, reference: https://github.com/TheLevelUp/ZXingObjC/issues/314
//    // Default capture 3 frames per second or customize them. if you want lower CPU usage, can adjust captureFramesPerSec to 1.0f make a better performace.
//    float kMinMargin = 1.0 / _captureFramesPerSec;
//
//    // Gets the timestamp for each frame.
//    CMTime presentTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
//
//    static double curFrameTimeStamp = 0;
//    static double lastFrameTimeStamp = 0;
//
//    curFrameTimeStamp = (double)presentTimeStamp.value / presentTimeStamp.timescale;
//
//    if (curFrameTimeStamp - lastFrameTimeStamp > kMinMargin) {
//      lastFrameTimeStamp = curFrameTimeStamp;
//
//      CVImageBufferRef videoFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
//      CGImageRef videoFrameImage = [ZXCGImageLuminanceSource createImageFromBuffer:videoFrame];
//      [self decodeImage:videoFrameImage];
//    }
//  }
//}

//- (void)decodeImage: (CGImageRef)image {
//  // If scanRect is set, crop the current image to include only the desired rect
//  if (!CGRectIsEmpty(self.scanRect)) {
//    CGImageRef croppedImage = CGImageCreateWithImageInRect(image, self.scanRect);
//    CGImageRelease(image);
//    image = croppedImage;
//  }
//
//  CGImageRef rotatedImage = [self createRotatedImage:image degrees:self.rotation];
//  CGImageRelease(image);
//  self.lastScannedImage = rotatedImage;
//
//  if (self.captureToFilename) {
//    NSURL *url = [NSURL fileURLWithPath:self.captureToFilename];
//    CGImageDestinationRef dest = CGImageDestinationCreateWithURL((__bridge CFURLRef)url, (__bridge CFStringRef)@"public.png", 1, nil);
//    CGImageDestinationAddImage(dest, rotatedImage, nil);
//    CGImageDestinationFinalize(dest);
//    CFRelease(dest);
//    self.captureToFilename = nil;
//  }
//
////  if (_heuristic) {
//    [self decodeImageAdv:rotatedImage];
////  }
//
//  ZXCGImageLuminanceSource *source = [[ZXCGImageLuminanceSource alloc] initWithCGImage: rotatedImage];
//  CGImageRelease(rotatedImage);
//
//  if (self.luminanceLayer) {
//    CGImageRef image = source.image;
//    CGImageRetain(image);
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0), dispatch_get_main_queue(), ^{
//      self.luminanceLayer.contents = (__bridge id)image;
//      CGImageRelease(image);
//    });
//  }
//
//  if (!self.binaryLayer && !self.delegate) { return; }
//
//  ZXHybridBinarizer *binarizer = [[ZXHybridBinarizer alloc] initWithSource:self.invert ? [source invert] : source];
//
//  if (self.binaryLayer) {
//    CGImageRef image = [binarizer createImage];
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0), dispatch_get_main_queue(), ^{
//      self.binaryLayer.contents = (__bridge id)image;
//      CGImageRelease(image);
//    });
//  }
//
//  if (self.delegate) {
//    ZXBinaryBitmap *bitmap = [[ZXBinaryBitmap alloc] initWithBinarizer:binarizer];
//
//    NSError *error;
//    ZXResult *result = [self.reader decode:bitmap hints:self.hints error:&error];
//    if (result) {
//      dispatch_async(dispatch_get_main_queue(), ^{
//        [self.delegate captureResult:self result:result scanImage:nil];
//      });
//    }
//  }
//}

//- (void)decodeImageAdv:(CGImageRef)cgImage {
//  CGImageRef img = CGImageCreateCopy(cgImage);
//  dispatch_async(_parallelQueue, ^{
//    ZXCGImageLuminanceSourceInfo *sourceInfo = [[ZXCGImageLuminanceSourceInfo alloc] initWithDecomposingMin];
//    ZXCGImageLuminanceSource *source = [[ZXCGImageLuminanceSource alloc] initWithCGImage:img
//                                                                              sourceInfo:sourceInfo];
//    CGImageRelease(img);
//
//    ZXHybridBinarizer *binarizer = [[ZXHybridBinarizer alloc] initWithSource:source];
//    ZXBinaryBitmap *bitmap = [[ZXBinaryBitmap alloc] initWithBinarizer:binarizer];
//    NSError *error;
//    ZXResult *result = [self.reader decode:bitmap hints: self.hints error:&error];
//    if (result && [self.delegate respondsToSelector: @selector(captureResult:result:)]) {
//      dispatch_async(dispatch_get_main_queue(), ^{
//        [self.delegate captureResult:self result:result scanImage:nil];
//      });
//    }
//  });
//}

#pragma mark - Private

// Adapted from http://blog.coriolis.ch/2009/09/04/arbitrary-rotation-of-a-cgimage/ and https://github.com/JanX2/CreateRotateWriteCGImage
- (CGImageRef)createRotatedImage:(CGImageRef)original degrees:(float)degrees CF_RETURNS_RETAINED {
    if (degrees == 0.0f) {
        CGImageRetain(original);
        return original;
    } else {
        double radians = degrees * M_PI / 180;
        
#if TARGET_OS_EMBEDDED || TARGET_IPHONE_SIMULATOR
        radians = -1 * radians;
#endif
        
        size_t _width = CGImageGetWidth(original);
        size_t _height = CGImageGetHeight(original);
        
        CGRect imgRect = CGRectMake(0, 0, _width, _height);
        CGAffineTransform __transform = CGAffineTransformMakeRotation(radians);
        CGRect rotatedRect = CGRectApplyAffineTransform(imgRect, __transform);
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(NULL,
                                                     rotatedRect.size.width,
                                                     rotatedRect.size.height,
                                                     CGImageGetBitsPerComponent(original),
                                                     0,
                                                     colorSpace,
                                                     kCGBitmapAlphaInfoMask & kCGImageAlphaPremultipliedFirst);
        CGContextSetAllowsAntialiasing(context, FALSE);
        CGContextSetInterpolationQuality(context, kCGInterpolationNone);
        CGColorSpaceRelease(colorSpace);
        
        CGContextTranslateCTM(context,
                              +(rotatedRect.size.width/2),
                              +(rotatedRect.size.height/2));
        CGContextRotateCTM(context, radians);
        
        CGContextDrawImage(context, CGRectMake(-imgRect.size.width/2,
                                               -imgRect.size.height/2,
                                               imgRect.size.width,
                                               imgRect.size.height),
                           original);
        
        CGImageRef rotatedImage = CGBitmapContextCreateImage(context);
        CFRelease(context);
        
        return rotatedImage;
    }
}

- (AVCaptureDevice *)device {
    if (self.captureDevice) {
        return self.captureDevice;
    }
    
    AVCaptureDevice *zxd = nil;
    
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    if ([devices count] > 0) {
        if (self.captureDeviceIndex == -1) {
            AVCaptureDevicePosition position = AVCaptureDevicePositionBack;
            if (self.camera == self.front) {
                position = AVCaptureDevicePositionFront;
            }
            
            for (unsigned int i = 0; i < [devices count]; ++i) {
                AVCaptureDevice *dev = [devices objectAtIndex:i];
                if (dev.position == position) {
                    self.captureDeviceIndex = i;
                    zxd = dev;
                    break;
                }
            }
        }
        
        if (!zxd && self.captureDeviceIndex != -1) {
            zxd = [devices objectAtIndex:self.captureDeviceIndex];
        }
    }
    
    if (!zxd) {
        zxd = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    
    self.captureDevice = zxd;
    
    return zxd;
}

- (void)replaceInput {
    [self.session beginConfiguration];
    
    if (self.session && self.input) {
        [self.session removeInput:self.input];
        self.input = nil;
    }
    
    AVCaptureDevice *zxd = [self device];
    
    if (zxd) {
        self.input = [AVCaptureDeviceInput deviceInputWithDevice:zxd error:nil];
        self.focusMode = self.focusMode;
    }
    
    if (self.input) {
        self.session.sessionPreset = self.sessionPreset;
        [self.session addInput:self.input];
    }
    
    [self.session commitConfiguration];
}

- (AVCaptureSession *)session {
    if (!_session) {
        _session = [[AVCaptureSession alloc] init];
        [self replaceInput];
        [self output];
    }
    
    return _session;
}

- (void)startStop {
    if ((!self.running && (self.delegate || self.onScreen)) ||
        (!self.output &&
         (self.delegate ||
          (self.onScreen && (self.luminanceLayer || self.binaryLayer))))) {
        [self start];
    }
    
    if (self.running && !self.delegate && !self.onScreen) {
        [self stop];
    }
}


- (NSString *)canSetSessionPreset {
    NSString *preset = AVCaptureSessionPresetLow;
    
    if ([self.device supportsAVCaptureSessionPreset:AVCaptureSessionPresetMedium]) {
        preset = AVCaptureSessionPresetMedium;
    }
    
    if ([self.device supportsAVCaptureSessionPreset:AVCaptureSessionPresetHigh]) {
        preset = AVCaptureSessionPresetHigh;
    }
    
    if ([self.device supportsAVCaptureSessionPreset:AVCaptureSessionPreset352x288]) {
        preset = AVCaptureSessionPreset352x288;
    }
    
    if ([self.device supportsAVCaptureSessionPreset:AVCaptureSessionPreset640x480]) {
        preset = AVCaptureSessionPreset640x480;
    }
    
    if ([self.device supportsAVCaptureSessionPreset:AVCaptureSessionPreset1280x720]) {
        preset = AVCaptureSessionPreset1280x720;
    }
    
    if ([self.device supportsAVCaptureSessionPreset:AVCaptureSessionPreset1920x1080]) {
        preset = AVCaptureSessionPreset1920x1080;
    }
    
    if ([self.device supportsAVCaptureSessionPreset:AVCaptureSessionPreset3840x2160]) {
        preset = AVCaptureSessionPreset3840x2160;
    }
    NSLog(@"===>>> preset: %@", preset);
    return preset;
}

@end
