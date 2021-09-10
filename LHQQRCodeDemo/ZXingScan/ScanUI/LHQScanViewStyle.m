//
//  LHQScanViewStyle.m
//  LHQQRCodeDemo
//
//  Created by Xhorse_iOS3 on 2021/9/6.
//

#import "LHQScanViewStyle.h"

@implementation LHQScanViewStyle

- (id)init {
    if (self =  [super init]) {
        _isNeedShowRetangle = YES;
        
        _whRatio = 1.0;
       
        _colorRetangleLine = [UIColor whiteColor];
        
        _centerUpOffset = 44;
        _xScanRetangleOffset = 60;
        
        _anmiationStyle = LHQScanViewAnimationStyle_LineMove;
        _photoframeAngleStyle = LHQScanViewPhotoframeAngleStyle_Outer;
        _colorAngle = [UIColor colorWithRed:0. green:167./255. blue:231./255. alpha:1.0];
        
        _notRecoginitonArea = [UIColor colorWithRed:0. green:.0 blue:.0 alpha:.5];
        
        
        _photoframeAngleW = 24;
        _photoframeAngleH = 24;
        _photoframeLineW = 7;
        
    }
    
    return self;
}

+ (NSString*)imagePathWithName:(NSString*)name
{
    NSString *bundlePath = [[NSBundle bundleForClass:self.class] pathForResource:@"CodeScan" ofType:@"bundle"];
    
    NSString* path = [NSString stringWithFormat:@"%@/%@",bundlePath, name];

    return path;
}


@end
