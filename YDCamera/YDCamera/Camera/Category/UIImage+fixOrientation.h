//
//  UIImage+fixOrientation.h
//  YDCamera
//
//  Created by 黄亚栋 on 2017/11/8.
//  Copyright © 2017年 黄亚栋. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import "YDImageType.h"

@interface UIImage (fixOrientation)

//调整照片
-(UIImage *)fixOrientation;

//矫正自拍图片
-(UIImage *)fixOrientationWithPosition:(AVCaptureDevicePosition)position andShotScale:(shotScale)shotScale andShotDirection:(shotDirection)shotDirection;

@end
