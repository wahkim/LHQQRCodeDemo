//
//  LHQZXCaptureDelegate.h
//  LHQQRCodeDemo
//
//  Created by Xhorse_iOS3 on 2021/9/6.
//

#import <Foundation/Foundation.h>
#import <ZXingObjC/ZXingObjC.h>

@class LHQZXCapture;

@protocol LHQZXCaptureDelegate <NSObject>

- (void)captureResult:(LHQZXCapture *)capture result:(ZXResult *)result scanImage:(UIImage*)img;


@optional
- (void)LHQCaptureSize:(LHQZXCapture *)capture
              width:(NSNumber *)width
             height:(NSNumber *)height;

- (void)LHQCaptureCameraIsReady:(LHQZXCapture *)capture;

@end
