//
//  YDCamera.h
//  YDCamera
//
//  Created by 黄亚栋 on 2017/11/10.
//  Copyright © 2017年 黄亚栋. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YDImageType.h"

@protocol YDCameraDelegate <NSObject>

-(void)unableUserCamera;
-(void)clickToolBackBtn;
-(void)clickToolPhotoBtn:(UIImage *)image;

@end

@interface YDCamera : UIView
@property (nonatomic,weak)id<YDCameraDelegate> delegate;


@end
