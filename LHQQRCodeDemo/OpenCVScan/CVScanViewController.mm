//
//  CVScanViewController.m
//  LHQQRCodeDemo
//
//  Created by Xhorse_iOS3 on 2021/9/3.
//

#import "CVScanViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "UIImage+OpenCV.h"

using namespace std;
using namespace cv;

@interface CVScanViewController () <AVCaptureVideoDataOutputSampleBufferDelegate, CvVideoCameraDelegate>

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureDevice *device;
@property (nonatomic, strong) AVCaptureDeviceInput *deviceInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) CvVideoCamera* videoCamera;

@end

@implementation CVScanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.imageView = [[UIImageView alloc] init];
    self.imageView.frame = self.view.bounds;
    [self.view addSubview:self.imageView];

    self.videoCamera = [[CvVideoCamera alloc] initWithParentView:self.imageView];
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPresetHigh;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultFPS = 60;
    self.videoCamera.delegate = self;
//    self.videoCamera.grayscale = NO;
//
//    string detect_prototxt = [[[NSBundle mainBundle] pathForResource:@"detect" ofType:@"prototxt"] UTF8String];
//    string detect_caffe_model = [[[NSBundle mainBundle] pathForResource:@"detect" ofType:@"caffemodel"] UTF8String];
//    string sr_prototxt = [[[NSBundle mainBundle] pathForResource:@"sr" ofType:@"prototxt"] UTF8String];
//    string sr_caffe_model = [[[NSBundle mainBundle] pathForResource:@"sr" ofType:@"caffemodel"] UTF8String];
//
//    shared_ptr<wechat_qrcode::WeChatQRCode> detector;
//    detector = makePtr<wechat_qrcode::WeChatQRCode>(detect_prototxt, detect_caffe_model, sr_prototxt, sr_caffe_model);
//
////    string imgPath = [[[NSBundle mainBundle] pathForResource:@"qrcode" ofType:@"png"] UTF8String];
////    Mat imgMat = imread(imgPath);
//    Mat imgMat;
////    UIImageToMat([UIImage imageNamed:@"dataMatrix_rgb"], imgMat);
//
//    UIImage *image = [UIImage imageNamed:@"dataMatrix_rgb_1"];
//    imgMat = [image CVGrayscaleMat];
//
//    vector<Mat> vPoints;
//    vector<String> strDecoded = detector->detectAndDecode(imgMat, vPoints);
//    for (int i = 0; i < strDecoded.size(); i ++) {
//        string str = strDecoded[i];
//        cout << str;
//        cout << "\n";
//    }
    
    
    /// device
//    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
//
//    /// input
//    self.deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
//
//    /// output
//    self.videoOutput = [[AVCaptureVideoDataOutput alloc] init];
//    self.videoOutput.alwaysDiscardsLateVideoFrames = YES;
//
//    [self.videoOutput setSampleBufferDelegate:self queue:dispatch_queue_create("queue", DISPATCH_QUEUE_SERIAL)];
//
//    /// session
//    self.session = [[AVCaptureSession alloc]init];
//    [self.session setSessionPreset:[self _canSetSessionPreset]];
//
//    if ([self.session canAddInput:self.deviceInput]) {
//        [self.session addInput:self.deviceInput];
//    }
//
//    if ([self.session canAddOutput:self.videoOutput]) {
//        [self.session addOutput:self.videoOutput];
//    }
//
//    self.videoOutput.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
//                                                                     forKey:(id)kCVPixelBufferPixelFormatTypeKey];
//
//    /// prreview
//    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
//    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
//    self.previewLayer.frame = self.view.bounds;
//    [self.view.layer insertSublayer:self.previewLayer atIndex:0];
//
//    [self.deviceInput.device lockForConfiguration:nil];
//
//    //自动白平衡
//    if ([self.device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance])
//    {
//        [self.deviceInput.device setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
//    }
//    //先进行判断是否支持控制对焦,不开启自动对焦功能，很难识别二维码。
//    if (self.device.isFocusPointOfInterestSupported &&[self.device isFocusModeSupported:AVCaptureFocusModeAutoFocus])
//    {
//        [self.deviceInput.device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
//    }
//    //自动曝光
//    if ([self.device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
//    {
//        [self.deviceInput.device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
//    }
//     [self.deviceInput.device unlockForConfiguration];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
//    [self.session startRunning];
    [self.videoCamera start];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
//    [self.session stopRunning];
    [self.videoCamera stop];
}

#pragma mark - <CvVideoCameraDelegate>

#ifdef __cplusplus
// delegate method for processing image frames
- (void)processImage:(cv::Mat&)image {
    UIImage *frameImage = MatToUIImage(image);
//    NSLog(@"image = %@", frameImage);

    [self extractWithImage:frameImage];
}
#endif

#pragma mark - <AVCaptureVideoDataOutputSampleBufferDelegate>

//- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
//
//    UIImage *image = [self convertSampleBufferToImage:sampleBuffer];
////    Mat image_copy;
////    Mat image_origin;
////    UIImageToMat(image, image_origin);
////    cvtColor(image_origin, image_copy, COLOR_BGR2GRAY);
////    NSLog(@"%@",image);
//    [self extractWithImage:image];
////    @autoreleasepool {
////        if (connection == [self.videoOutput connectionWithMediaType:AVMediaTypeVideo]) { // 视频
////            @synchronized (self) {
////                dispatch_async(dispatch_get_main_queue(), ^{
//////                    UIImage *image = [self bufferToImage:sampleBuffer rect:self.previewLayer.bounds];
////                    NSLog(@"%@",sampleBuffer);
////    //                self.uploadImg = image;
//////                    [self extractWithImage:image];
////                });
////
////            }
////        }
////    }
//}

-(UIImage *)convertSampleBufferToImage:(CMSampleBufferRef)sampleBuffer
{
    // CMSampleBufferRef --->CVImageBufferRef--->CGImageRef--->UIImage
    //制作 CVImageBufferRef
    CVImageBufferRef buffer;
    buffer = CMSampleBufferGetImageBuffer(sampleBuffer);

    CVPixelBufferLockBaseAddress(buffer, 0);

    //从 CVImageBufferRef 取得影像的细部信息
    void *base;
    size_t width, height, bytesPerRow;
    base = CVPixelBufferGetBaseAddress(buffer);
    width = CVPixelBufferGetWidth(buffer);
    height = CVPixelBufferGetHeight(buffer);
    bytesPerRow = CVPixelBufferGetBytesPerRow(buffer);

    //利用取得影像细部信息格式化 CGContextRef
    CGColorSpaceRef colorSpace;
    CGContextRef cgContext;
    colorSpace = CGColorSpaceCreateDeviceRGB();
    cgContext = CGBitmapContextCreate(base, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);

    //透过 CGImageRef 将 CGContextRef 转换成 UIImage
    CGImageRef cgImage;
    UIImage *image;
    cgImage = CGBitmapContextCreateImage(cgContext);
    image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    CGContextRelease(cgContext);

    CVPixelBufferUnlockBaseAddress(buffer, 0);

    return image;
}


#pragma mark - Extract QR code

- (void)extractWithImage:(UIImage *)frameImg {
    
    string detect_prototxt = [[[NSBundle mainBundle] pathForResource:@"detect" ofType:@"prototxt"] UTF8String];
    string detect_caffe_model = [[[NSBundle mainBundle] pathForResource:@"detect" ofType:@"caffemodel"] UTF8String];
    string sr_prototxt = [[[NSBundle mainBundle] pathForResource:@"sr" ofType:@"prototxt"] UTF8String];
    string sr_caffe_model = [[[NSBundle mainBundle] pathForResource:@"sr" ofType:@"caffemodel"] UTF8String];

    shared_ptr<wechat_qrcode::WeChatQRCode> detector;
    detector = makePtr<wechat_qrcode::WeChatQRCode>(detect_prototxt, detect_caffe_model, sr_prototxt, sr_caffe_model);

//    string imgPath = [[[NSBundle mainBundle] pathForResource:@"qrcode" ofType:@"png"] UTF8String];
//    Mat imgMat = imread(imgPath);
    Mat imgMat;
    UIImageToMat(frameImg, imgMat); /// [UIImage imageNamed:@"qrcode"]

    vector<Mat> vPoints;
    vector<String> strDecoded = detector->detectAndDecode(imgMat, vPoints);
    if (!strDecoded.size()) {
//        cout << "无码";
        return;
    }
    NSString *result = @"";
    for (int i = 0; i < strDecoded.size(); i ++) {
        string str = strDecoded[i];
        NSString *cStr = [NSString stringWithCString:str.c_str() encoding:[NSString defaultCStringEncoding]];;
        result = [NSString stringWithFormat:@"%@\n%@",result, cStr];
        cout << str;
        cout << "\n";
    }
    
//    [self.session stopRunning];
    [self.videoCamera stop];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showError:result withReset:NO];
    });
    
}

- (void)showError:(NSString*)str withReset:(BOOL)isRest
{
    if (str==nil || [str isEqualToString:@""]) {
        str =@"扫码失败，请重新扫一扫";
    }
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:str preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [self.videoCamera start];
        
    }];
    [alertController addAction:confirmAction];
    [self presentViewController:alertController animated:YES completion:nil];

}


#pragma mark -

- (NSString *)_canSetSessionPreset {
    if ([self.device supportsAVCaptureSessionPreset:AVCaptureSessionPreset3840x2160]) {
        return AVCaptureSessionPreset3840x2160;
    }
    if ([self.device supportsAVCaptureSessionPreset:AVCaptureSessionPreset1920x1080]) {
        return AVCaptureSessionPreset1920x1080;
    }
    if ([self.device supportsAVCaptureSessionPreset:AVCaptureSessionPreset1280x720]) {
        return AVCaptureSessionPreset1280x720;
    }
    if ([self.device supportsAVCaptureSessionPreset:AVCaptureSessionPreset640x480]) {
        return AVCaptureSessionPreset640x480;
    }
    if ([self.device supportsAVCaptureSessionPreset:AVCaptureSessionPreset352x288]) {
        return AVCaptureSessionPreset352x288;
    }
    if ([self.device supportsAVCaptureSessionPreset:AVCaptureSessionPresetHigh]) {
        return AVCaptureSessionPresetHigh;
    }
    if ([self.device supportsAVCaptureSessionPreset:AVCaptureSessionPresetMedium]) {
        return AVCaptureSessionPresetMedium;
    }
    
    return AVCaptureSessionPresetLow;
}



@end
