//
//  LHQScanResult.m
//  LHQQRCodeDemo
//
//  Created by Xhorse_iOS3 on 2021/9/6.
//

#import "LHQScanResult.h"

@implementation LHQScanResult

- (instancetype)initWithScanString:(NSString*)str imgScan:(UIImage*)img barCodeType:(NSString*)type
{
    if (self = [super init]) {
        
        self.strScanned = str;
        self.imgScanned = img;
        self.strBarCodeType = type;
        self.bounds = CGRectZero;
    }
    
    return self;
}

@end
