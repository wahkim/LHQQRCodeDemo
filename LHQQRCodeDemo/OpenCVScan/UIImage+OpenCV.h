//
//  UIImage+OpenCV.h
//  OpenCVDemo
//
//  Created by Xhorse_iOS3 on 2021/3/10.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (OpenCV)

- (id)WaterMarkDelete:(CGRect)rect;

- (UIImage *)cutImageWithRect:(CGRect)rect;

- (cv::Mat)CVGrayscaleMat;

@end

NS_ASSUME_NONNULL_END
