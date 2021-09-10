//
//  LHQZXWrapper.m
//  LHQQRCodeDemo
//
//  Created by Xhorse_iOS3 on 2021/9/6.
//

#import "LHQZXWrapper.h"
#import "LHQZXCaptureDelegate.h"
#import "LHQZXCapture.h"

@interface LHQZXWrapper() <LHQZXCaptureDelegate>

@property (nonatomic, strong) LHQZXCapture *capture;
@property (nonatomic, copy) void (^success)(ZXBarcodeFormat barcodeFormat,NSString *str,UIImage *scanImg);
@property (nonatomic, copy) void (^onSuccess)(ZXBarcodeFormat barcodeFormat,NSString *str,UIImage *scanImg,NSArray* resultPoints);
@property (nonatomic, assign) BOOL bNeedScanResult;

@property (nonatomic, strong) UIView *preView;
@property (nonatomic, strong) UIView *focusView;

@end

@implementation LHQZXWrapper

- (id)init {
    if ( self = [super init]) {
        self.capture = [[LHQZXCapture alloc] init];
        self.capture.camera = self.capture.back;
        self.capture.focusMode = AVCaptureFocusModeContinuousAutoFocus;
        self.capture.rotation = 90.0f;
        self.capture.delegate = self;
        self.continuous = NO;
        self.orientation = AVCaptureVideoOrientationPortrait;
    }
    return self;
}

- (void)setOnStarted:(void (^)(void))onStarted {
    self.capture.onStarted = onStarted;
}

- (id)initWithPreView:(UIView*)preView success:(void(^)(ZXBarcodeFormat barcodeFormat,NSString *str,UIImage *scanImg,NSArray* resultPoints))success {
    if (self = [super init]) {
        
        self.capture = [[LHQZXCapture alloc] init];
        self.capture.camera = self.capture.back;
        self.capture.focusMode = AVCaptureFocusModeContinuousAutoFocus;
        self.capture.rotation = 90.0f;
        self.capture.delegate = self;
        self.capture.defaultFPS = 20;
        self.continuous = NO;
        self.orientation = AVCaptureVideoOrientationPortrait;
        
        self.onSuccess = success;
        
        CGRect rect = preView.frame;
        rect.origin = CGPointZero;
        
        self.capture.layer.frame = rect;
        //[preView.layer addSublayer:self.capture.layer];
        
        [preView.layer insertSublayer:self.capture.layer atIndex:0];
        self.preView = preView;
        
        self.focusView = [UIView new];
        self.focusView.bounds = CGRectMake(0, 0, 40, 40);
        self.focusView.layer.borderWidth = 0.5;
        self.focusView.layer.borderColor = [UIColor yellowColor].CGColor;
        
        [self.preView addSubview:self.focusView];
        
    }
    return self;
}

- (void)setScanRect:(CGRect)scanRect {
    self.capture.scanRect = scanRect;
}

- (void)start {
    self.bNeedScanResult = YES;
    
    AVCaptureVideoPreviewLayer *preview = (AVCaptureVideoPreviewLayer*)self.capture.layer;
    preview.connection.videoOrientation = self.orientation;
    
    [self.capture start];
}


- (void)stop {
    self.bNeedScanResult = NO;
    [self.capture stop];
}

- (void)setOrientation:(NSInteger)orientation {
    _orientation = orientation;
    
    AVCaptureVideoPreviewLayer * preview = (AVCaptureVideoPreviewLayer*)self.capture.layer;
       preview.connection.videoOrientation = self.orientation;
}

- (void)setVideoLayerframe:(CGRect)videoLayerframe {
    _videoLayerframe = videoLayerframe;
    
    AVCaptureVideoPreviewLayer * preview = (AVCaptureVideoPreviewLayer*)self.capture.layer;
    preview.frame = videoLayerframe;
}

- (void)openTorch:(BOOL)on_off {
    [self.capture setTorch:on_off];
}

- (void)openOrCloseTorch {
    [self.capture changeTorch];
}

#pragma mark - Zoom

- (void)changeFactor:(CGFloat)currentZoomFactor {
    if (currentZoomFactor < self.maxZoomFactor + 1 &&
        currentZoomFactor > self.minZoomFactor){
        
        NSError *error = nil;
        if ([self.capture.captureDevice lockForConfiguration:&error] ) {
            [self.capture.captureDevice rampToVideoZoomFactor:currentZoomFactor withRate:5];
            [self.capture.captureDevice unlockForConfiguration];
 
        } else {

        }
    }
}

- (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections
{
    for ( AVCaptureConnection *connection in connections ) {
        for ( AVCaptureInputPort *port in [connection inputPorts] ) {
            if ( [[port mediaType] isEqual:mediaType] ) {
                return connection;
            }
        }
    }
    return nil;
}

//最小缩放值
- (CGFloat)minZoomFactor {
    return [self.capture minZoomFactor];
}
//最大缩放值
- (CGFloat)maxZoomFactor {
    return [self.capture maxZoomFactor];
}

#pragma mark - Focus

- (void)focusAtPoint:(CGPoint)point {
    CGSize size = self.preView.bounds.size;
    CGPoint focusPoint = CGPointMake(point.x/size.width, point.y/size.height);
    NSError *error;
    if ([self.capture.captureDevice lockForConfiguration:&error]) {
        if ([self.self.capture.captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            [self.self.capture.captureDevice setFocusPointOfInterest:focusPoint];
            [self.self.capture.captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        [self.self.capture.captureDevice unlockForConfiguration];
    }
    [self setFocusCursorWithPoint:point];
}

- (void)setFocusCursorWithPoint:(CGPoint)point{
    self.focusView.center = point;
    self.focusView.hidden = NO;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.focusView.transform = CGAffineTransformMakeScale(1.25, 1.25);
    }completion:^(BOOL finished) {
        [UIView animateWithDuration:0.5 animations:^{
            self.focusView.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            self.focusView.hidden = YES;
        }];
    }];
    
}

#pragma mark - <ZXCaptureDelegate>

- (void)captureResult:(ZXCapture *)capture result:(ZXResult *)result scanImage:(UIImage *)img {
    if (!result) return;
    
    if (self.bNeedScanResult == NO) {
        
        return;
    }
    
    if (!_continuous) {
        
         [self stop];
    }
    
    
    if (_onSuccess) {
        _onSuccess(result.barcodeFormat,result.text,img,result.resultPoints);
    }
    else if ( _success )
    {
        _success(result.barcodeFormat,result.text,img);
    }
}


+ (UIImage*)createCodeWithString:(NSString*)str size:(CGSize)size CodeFomart:(ZXBarcodeFormat)format {
    ZXMultiFormatWriter *writer = [[ZXMultiFormatWriter alloc] init];
    ZXBitMatrix *result = [writer encode:str
                                  format:format
                                   width:size.width
                                  height:size.width
                                   error:nil];
    
    if (result) {
        ZXImage *image = [ZXImage imageWithMatrix:result];
        return [UIImage imageWithCGImage:image.cgimage];
    } else {
        return nil;
    }
}


+ (void)recognizeImage:(UIImage*)image block:(void(^)(ZXBarcodeFormat barcodeFormat,NSString *str))block; {
    ZXCGImageLuminanceSource *source = [[ZXCGImageLuminanceSource alloc] initWithCGImage:image.CGImage];
    
    ZXHybridBinarizer *binarizer = [[ZXHybridBinarizer alloc] initWithSource: source];
    
    ZXBinaryBitmap *bitmap = [[ZXBinaryBitmap alloc] initWithBinarizer:binarizer];
    
    NSError *error;
    
    id<ZXReader> reader;
    
    if (NSClassFromString(@"ZXMultiFormatReader")) {
        reader = [NSClassFromString(@"ZXMultiFormatReader") performSelector:@selector(reader)];
    }
    
    ZXDecodeHints *_hints = [ZXDecodeHints hints];
    ZXResult *result = [reader decode:bitmap hints:_hints error:&error];
    
    if (result == nil) {
        
        block(kBarcodeFormatQRCode,nil);
        return;
    }
    
    block(result.barcodeFormat,result.text);
}

@end
