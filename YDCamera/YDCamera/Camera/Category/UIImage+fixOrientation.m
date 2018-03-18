//
//  UIImage+fixOrientation.m
//  YDCamera
//
//  Created by 黄亚栋 on 2017/11/8.
//  Copyright © 2017年 黄亚栋. All rights reserved.
//

#import "UIImage+fixOrientation.h"

@implementation UIImage (fixOrientation)

-(UIImage *)fixOrientation{
 
    CGImageRef imageRef = self.CGImage;
    CGRect rect = CGRectZero;
    rect.size.width = CGImageGetWidth(imageRef);
    rect.size.height = CGImageGetHeight(imageRef);
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    //Context上下文大小
    CGSize size = CGSizeMake(0, 0);
    
    if (self.imageOrientation == UIImageOrientationUp || self.imageOrientation == UIImageOrientationUpMirrored){
        return self;
    }
    
    if (self.imageOrientation == UIImageOrientationDown || self.imageOrientation == UIImageOrientationDownMirrored) {
        transform = CGAffineTransformRotate(transform, M_PI);
        transform = CGAffineTransformTranslate(transform, -rect.size.width, 0);
        transform = CGAffineTransformScale(transform, 1, -1);
        size = CGSizeMake(rect.size.width, rect.size.height);
    }
    
    if (self.imageOrientation == UIImageOrientationLeft || self.imageOrientation == UIImageOrientationLeftMirrored) {
        transform = CGAffineTransformRotate(transform, -M_PI_2);
        transform = CGAffineTransformTranslate(transform, -rect.size.width, 0);
        transform = CGAffineTransformScale(transform, 1, -1);
        transform = CGAffineTransformTranslate(transform, 0, -rect.size.height);
        size = CGSizeMake(rect.size.height, rect.size.width);
    }
    
    if (self.imageOrientation == UIImageOrientationRight || self.imageOrientation == UIImageOrientationRightMirrored) {
        transform = CGAffineTransformRotate(transform, M_PI_2);
        transform = CGAffineTransformScale(transform, 1, -1);
        size = CGSizeMake(rect.size.height, rect.size.width);
    }
    
    if (size.height == 0 || size.width == 0) {
        return nil;
    }
    
    UIGraphicsBeginImageContextWithOptions(size, YES, 1);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextConcatCTM(context, transform);
    CGContextDrawImage(context, rect, self.CGImage);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    CGContextRelease(context);
    
    return image;
}


-(UIImage *)fixOrientationWithPosition:(AVCaptureDevicePosition)position andShotScale:(shotScale)shotScale andShotDirection:(shotDirection)shotDirection{
    
    UIImage *image = [self fixOrientation];
    
    //自拍矫正
   if (position == AVCaptureDevicePositionFront){
        CGRect rect = CGRectZero;
        rect.size.width = image.size.width;
        rect.size.height = image.size.height;
        
        UIGraphicsBeginImageContextWithOptions(rect.size, YES, 1);
        CGContextRef ref = UIGraphicsGetCurrentContext();
        CGContextScaleCTM(ref, 1, -1);
        CGContextTranslateCTM(ref, 0, -rect.size.height);
        CGContextScaleCTM(ref, -1, 1);
        CGContextTranslateCTM(ref, -rect.size.width, 0);
        CGContextDrawImage(ref, rect, image.CGImage);
        image = UIGraphicsGetImageFromCurrentImageContext();
        CGContextRelease(ref);
    }
    
    //比例裁剪
    if (shotScale == Scale3To4) {
        CGRect rect = CGRectZero;
        rect.size.width = image.size.width;
        rect.size.height = image.size.height;
        CGFloat newHeight = rect.size.width*4/3;
        
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(rect.size.width, newHeight), YES, 1);
        CGContextRef ref = UIGraphicsGetCurrentContext();
        CGContextScaleCTM(ref, 1, -1);
        CGContextTranslateCTM(ref, 0, -rect.size.height+(rect.size.height-newHeight)/2);
        CGContextDrawImage(ref, rect, image.CGImage);
        image = UIGraphicsGetImageFromCurrentImageContext();
        CGContextRelease(ref);
    }
    if (shotScale == Scale1To1) {
        CGRect rect = CGRectZero;
        rect.size.width = image.size.width;
        rect.size.height = image.size.height;
        CGFloat newHeight = rect.size.width;
        
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(rect.size.width, newHeight), YES, 1);
        CGContextRef ref = UIGraphicsGetCurrentContext();
        CGContextScaleCTM(ref, 1, -1);
        CGContextTranslateCTM(ref, 0, -rect.size.height+(rect.size.height-newHeight)/2);
        CGContextDrawImage(ref, rect, image.CGImage);
        image = UIGraphicsGetImageFromCurrentImageContext();
        CGContextRelease(ref);
    }
    
    //镜头方向
    if (shotDirection == shotRight) {
        CGRect rect = CGRectZero;
        rect.size.width = image.size.width;
        rect.size.height = image.size.height;
        
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(rect.size.height, rect.size.width), YES, 1);
        CGContextRef ref = UIGraphicsGetCurrentContext();
        CGContextRotateCTM(ref, -M_PI_2);
        CGContextScaleCTM(ref, 1, -1);
        CGContextTranslateCTM(ref, -rect.size.width, -rect.size.height);
        CGContextDrawImage(ref, rect, image.CGImage);
        image = UIGraphicsGetImageFromCurrentImageContext();
        CGContextRelease(ref);
    }
    
    if (shotDirection == shotLeft) {
        CGRect rect = CGRectZero;
        rect.size.width = image.size.width;
        rect.size.height = image.size.height;
        
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(rect.size.height, rect.size.width), YES, 1);
        CGContextRef ref = UIGraphicsGetCurrentContext();
        CGContextRotateCTM(ref, M_PI_2);
        CGContextScaleCTM(ref, 1, -1);
        CGContextDrawImage(ref, rect, image.CGImage);
        image = UIGraphicsGetImageFromCurrentImageContext();
        CGContextRelease(ref);
    }
    
    if (shotDirection == shotDown) {
        CGRect rect = CGRectZero;
        rect.size.width = image.size.width;
        rect.size.height = image.size.height;
        
        UIGraphicsBeginImageContextWithOptions(rect.size, YES, 1);
        CGContextRef ref = UIGraphicsGetCurrentContext();
        CGContextRotateCTM(ref, M_PI);
        CGContextTranslateCTM(ref, -rect.size.width,0);
        CGContextScaleCTM(ref, 1, -1);
        CGContextDrawImage(ref, rect, image.CGImage);
        image = UIGraphicsGetImageFromCurrentImageContext();
        CGContextRelease(ref);
    }
    
    
    return image;
}

@end
