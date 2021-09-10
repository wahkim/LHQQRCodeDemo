//
//  RHScanViewController.m
//  RHScan
//
//  Created by river on 2018/2/1.
//  Copyright © 2018年 richinfo. All rights reserved.
//

#import "RHScanViewController.h"
#import "RHScanPermissions.h"
#import "RHScanNative.h"
#import "RHScanView.h"

@interface RHScanViewController ()<UIGestureRecognizerDelegate, RHScanNativeDelegate>

@property (nonatomic, strong) RHScanNative *scanObj;
/// 扫码区域视图,二维码一般都是框
@property (nonatomic, strong) RHScanView *qRScanView;
/// 视频图层
@property (nonatomic, strong) UIView *videoView;

/// 最后的缩放比例
@property (nonatomic, assign) CGFloat effectiveZoomFactor;
/// 当前的缩放比例
@property (nonatomic, assign) CGFloat currentZoomFactor;

@end

@implementation RHScanViewController

#pragma mark - life

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initDataSource];
    [self setupViews];
    [self setupGesture];

}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [RHScanPermissions requestCameraPemissionWithResult:^(BOOL granted) {
        if (granted) {
            [self startScan];
            
        }else{
            [self showError:@"   请到设置隐私中开启本程序相机权限   " withReset:NO];
        }
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self stopScan];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Setup Views

- (void)setupViews {

    self.view.backgroundColor = [UIColor clearColor];
    
    self.style = [RHScanViewStyle new];
    self.style.xScanRetangleOffset = 0;
    self.style.whRatio = 0.75;
    
    self.qRScanView = [[RHScanView alloc]initWithFrame:self.view.bounds style:self.style];
    [self.view addSubview:self.qRScanView];
    
    self.videoView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.videoView.backgroundColor = [UIColor clearColor];
    [self.view insertSubview:self.videoView atIndex:0];
    
    //设置只识别框内区域
    CGRect cropRect = [RHScanView getScanRectWithPreView:self.view style:_style];
    
    self.scanObj = [[RHScanNative alloc] initWithPreView:self.videoView ObjectType:nil cropRect:cropRect delegate:self];
    [self.scanObj setDefaultFPS:30];
    [self.scanObj setSmoothAutoFocus:YES];
    [self.scanObj setNeedCaptureImage:NO];
}

#pragma mark - Init DataSource

- (void)initDataSource {
    _currentZoomFactor = 1;
    _effectiveZoomFactor = 1;
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

/// 捏合手势
- (void)onPinch:(UIPinchGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan ||
        sender.state == UIGestureRecognizerStateChanged)
    {
        CGFloat currentZoomFactor = self.currentZoomFactor * sender.scale;
        self.effectiveZoomFactor = currentZoomFactor;

        NSLog(@"zonm: %lf, scale: %lf", currentZoomFactor, sender.scale);
        [self.scanObj changeFactor:currentZoomFactor];
    }
}

- (void)onSingleTap:(UITapGestureRecognizer *)sender {
    CGPoint point = [sender locationInView:sender.view];
    [self.scanObj focusAtPoint:point];
}

/// 双击手势
- (void)onDoubleTap:(UIGestureRecognizer *)sender {
    self.effectiveZoomFactor = self.scanObj.maxZoomFactor;
    [self.scanObj changeFactor:self.effectiveZoomFactor];

    CGPoint point = [sender locationInView:sender.view];
    [self.scanObj focusAtPoint:point];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]]){
        self.currentZoomFactor = _effectiveZoomFactor;
    }
    return YES;
}


#pragma mark - Scan

//启动设备
- (void)startScan
{
    if (![RHScanPermissions cameraPemission] )
    {
        [self showError:@"   请到设置隐私中开启本程序相机权限   " withReset:NO];
        return;
    }
    
    if (_isOpenInterestRect) {
        CGRect cropRect = [RHScanView getScanRectWithPreView:self.view style:_style];
        [_scanObj setRectOfInterest:cropRect];
    }
    
    [_scanObj startScan];
    [_qRScanView startScanAnimation];
}

- (void)stopScan {
    [_scanObj stopScan];
    [_qRScanView stopScanAnimation];
}

#pragma mark - <RHScanNativeDelegate>

- (void)scanNative:(RHScanNative *)scanNative result:(NSArray<NSString *> *)resultArray {
    //经测试，可以同时识别2个二维码，不能同时识别二维码和条形码
    if (resultArray.count < 1)
    {
        [self showError:@"识别失败了" withReset:YES];
        return;
    }
    if (!resultArray[0] || [resultArray[0] isEqualToString:@""] ) {
        
        [self showError:@"识别失败了" withReset:YES];
        return;
    }
    NSString *scanResult = resultArray[0];
    NSLog(@"%@",scanResult);
    [self stopScan];
    [self showError:scanResult withReset:YES];
    //TODO: 这里可以根据需要自行添加震动或播放声音提示相关代码
    //加载菊花
    //停止扫描
}


#pragma mark - Alert Methods

- (void)showError:(NSString*)str withReset:(BOOL)isRest
{
    if (str==nil || [str isEqualToString:@""]) {
        str =@"扫码失败，请重新扫一扫";
    }
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:str preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [self startScan];
        NSLog(@"重新扫一扫");
        
        [self.qRScanView stopDeviceReadying];
        
    }];
    [alertController addAction:confirmAction];
    [self presentViewController:alertController animated:YES completion:nil];

}

@end

