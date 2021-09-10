//
//  ZXingScan_2ViewController.m
//  LHQQRCodeDemo
//
//  Created by Xhorse_iOS3 on 2021/9/8.
//

#import "ZXingScan_2ViewController.h"
#import "LHQZXWrapper.h"
#import "LHQScanView.h"
#import "LHQScanResult.h"

@interface ZXingScan_2ViewController () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) LHQZXWrapper *zxWrapper;
@property (nonatomic, strong) LHQScanView *scanView;
@property (nonatomic, strong) LHQScanViewStyle *style;

/// 相机预览
@property (nonatomic, strong) UIView *cameraPreView;


/// 最后的缩放比例
@property (nonatomic, assign) CGFloat effectiveZoomFactor;
/// 当前的缩放比例
@property (nonatomic, assign) CGFloat currentZoomFactor;


@end

@implementation ZXingScan_2ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self initDataSource];
    [self setupViews];
    [self setupGesture];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self startScan];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self stopScan];
}

#pragma mark - Init DataSource

- (void)initDataSource {
    
//    _effectiveScale = 1;
    _currentZoomFactor = 1;
    _effectiveZoomFactor = 1;
}

#pragma mark - Setup Views

- (void)setupViews {
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.style = [LHQScanViewStyle new];
    self.style.animationImage = [UIImage imageNamed:@"img_scan"];
    self.style.anmiationStyle = LHQScanViewAnimationStyle_LineMove;
    self.style.xScanRetangleOffset = 0;
    self.style.whRatio = 0.75;

    self.scanView = [[LHQScanView alloc] initWithFrame:self.view.bounds style:self.style];
    [self.view addSubview:self.scanView];
    
    self.cameraPreView = [[UIView alloc]initWithFrame:self.view.bounds];
    self.cameraPreView.backgroundColor = [UIColor clearColor];
    [self.view insertSubview:self.cameraPreView atIndex:0];
    
    __weak __typeof(self) weakSelf = self;
    self.zxWrapper = [[LHQZXWrapper alloc]initWithPreView:self.cameraPreView success:^(ZXBarcodeFormat barcodeFormat, NSString *str, UIImage *scanImg, NSArray *resultPoints) {
        [weakSelf handZXingResult:barcodeFormat barStr:str scanImg:scanImg resultPoints:resultPoints];
    }];
    
    CGRect cropRect = [LHQScanView getZXingScanRectWithPreView:self.cameraPreView style:self.style];
    [self.zxWrapper setScanRect:cropRect];
    self.zxWrapper.continuous = NO;
    self.zxWrapper.orientation = AVCaptureVideoOrientationPortrait;
}

#pragma mark - Gesture

- (void)setupGesture {
    
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(onPinch:)];
    pinch.delegate = self;
    [self.view addGestureRecognizer:pinch];

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(onSingleTap:)];
    tapGesture.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:tapGesture];
    
    UITapGestureRecognizer *doubleGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(onDoubleTap:)];
    doubleGesture.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:doubleGesture];
    
    [tapGesture requireGestureRecognizerToFail:doubleGesture];
}

#pragma mark - Scan

- (void)startScan {
    
    [self.zxWrapper start];
    [self.zxWrapper changeFactor:1];
    
    __weak __typeof(self) weakSelf = self;
    self.zxWrapper.onStarted = ^{
        [weakSelf.scanView startScanAnimation];
    };
}

- (void)stopScan {
    [self.scanView stopScanAnimation];
    [self.zxWrapper stop];
}

#pragma mark - Gesture Event

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]]){
        self.currentZoomFactor = _effectiveZoomFactor;
    }
    return YES;
}

/// 捏合手势
- (void)onPinch:(UIPinchGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan ||
        sender.state == UIGestureRecognizerStateChanged)
    {
        CGFloat currentZoomFactor = self.currentZoomFactor * sender.scale;
        self.effectiveZoomFactor = currentZoomFactor;

        NSLog(@"zonm: %lf, scale: %lf", currentZoomFactor, sender.scale);
        [self.zxWrapper changeFactor:currentZoomFactor];
    }
   
}

/// 单击手势
- (void)onSingleTap:(UIGestureRecognizer *)sender {
    NSLog(@"单击");
    CGPoint point = [sender locationInView:sender.view];
    [self.zxWrapper focusAtPoint:point];
}

/// 双击手势
- (void)onDoubleTap:(UIGestureRecognizer *)sender {
    NSLog(@"双击");
    self.effectiveZoomFactor = self.zxWrapper.maxZoomFactor;
    [self.zxWrapper changeFactor:self.effectiveZoomFactor];

    CGPoint point = [sender locationInView:sender.view];
    [self.zxWrapper focusAtPoint:point];
}

#pragma mark - Scan Result

- (void)handZXingResult:(ZXBarcodeFormat)barcodeFormat barStr:(NSString*)str scanImg:(UIImage*)scanImg resultPoints:(NSArray*)resultPoints
{
    LHQScanResult *result = [[LHQScanResult alloc]init];
    result.strScanned = str;
    result.imgScanned = scanImg;
    result.strBarCodeType = [self convertZXBarcodeFormat:barcodeFormat];
    
//    NSLog(@"ZXing pts:%@",resultPoints);
    
    if (self.cameraPreView && resultPoints && scanImg) {
        
        CGFloat minx = 100000;
        CGFloat miny= 100000;
        CGFloat maxx = 0;
        CGFloat maxy= 0;
        
        for (ZXResultPoint *pt in resultPoints) {
            
            if (pt.x < minx) {
                minx = pt.x;
            }
            if (pt.x > maxx) {
                maxx = pt.x;
            }
            
            if (pt.y < miny) {
                miny = pt.y;
            }
            if (pt.y > maxy) {
                maxy = pt.y;
            }
        }
        
//        CGFloat width = maxx - minx;
//        CGFloat height = maxy - miny;
        
        CGSize imgSize = scanImg.size;
        CGSize preViewSize = self.cameraPreView.frame.size;
        minx = minx / imgSize.width * preViewSize.width;
        maxx = maxx / imgSize.width * preViewSize.width;
        miny = miny / imgSize.height * preViewSize.height;
        maxy = maxy / imgSize.height * preViewSize.height;
        
        result.bounds = CGRectMake(minx, miny,  maxx - minx,maxy - miny);
        
        NSLog(@"bounds:%@",NSStringFromCGRect(result.bounds));
        
        [self scanResultWithArray:@[result]];
    }
    else
    {
        [self scanResultWithArray:@[result]];
    }
}

- (void)scanResultWithArray:(NSArray<LHQScanResult*>*)array {
    
    if (!array ||  array.count < 1)
    {
        NSLog(@"失败失败了。。。。");
    }
    
    //经测试，可以ZXing同时识别2个二维码，不能同时识别二维码和条形码
    //    for (LBXScanResult *result in array) {
    //
    //        NSLog(@"scanResult:%@",result.strScanned);
    //    }
    
    LHQScanResult *scanResult = array[0];
    
    NSString *strResult = scanResult.strScanned;
    
    
    if (!strResult) {
        return;
    }
    
    [self showResult:scanResult.strScanned];
    
    [self stopScan];
    
}

- (void)showResult:(NSString*)str
{
    if (str==nil || [str isEqualToString:@""]) {
        str =@"扫码失败，请重新扫一扫";
    }
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:str preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [self startScan];
        NSLog(@"重新扫一扫");
        
    }];
    [alertController addAction:confirmAction];
    [self presentViewController:alertController animated:YES completion:nil];

}

#pragma mark - Private Methods

- (NSString*)convertZXBarcodeFormat:(ZXBarcodeFormat)barCodeFormat
{
    NSString *strAVMetadataObjectType = nil;
    
    switch (barCodeFormat) {
        case kBarcodeFormatQRCode:
            strAVMetadataObjectType = AVMetadataObjectTypeQRCode;
            break;
        case kBarcodeFormatEan13:
            strAVMetadataObjectType = AVMetadataObjectTypeEAN13Code;
            break;
        case kBarcodeFormatEan8:
            strAVMetadataObjectType = AVMetadataObjectTypeEAN8Code;
            break;
        case kBarcodeFormatPDF417:
            strAVMetadataObjectType = AVMetadataObjectTypePDF417Code;
            break;
        case kBarcodeFormatAztec:
            strAVMetadataObjectType = AVMetadataObjectTypeAztecCode;
            break;
        case kBarcodeFormatCode39:
            strAVMetadataObjectType = AVMetadataObjectTypeCode39Code;
            break;
        case kBarcodeFormatCode93:
            strAVMetadataObjectType = AVMetadataObjectTypeCode93Code;
            break;
        case kBarcodeFormatCode128:
            strAVMetadataObjectType = AVMetadataObjectTypeCode128Code;
            break;
        case kBarcodeFormatDataMatrix:
            strAVMetadataObjectType = AVMetadataObjectTypeDataMatrixCode;
            break;
        case kBarcodeFormatITF:
            strAVMetadataObjectType = AVMetadataObjectTypeITF14Code;
            break;
        case kBarcodeFormatRSS14:
            break;
        case kBarcodeFormatRSSExpanded:
            break;
        case kBarcodeFormatUPCA:
            break;
        case kBarcodeFormatUPCE:
            strAVMetadataObjectType = AVMetadataObjectTypeUPCECode;
            break;
        default:
            break;
    }
    
    return strAVMetadataObjectType;
}

@end
