//
//  CameraViewController.h
//  YDCamera
//
//  Created by 黄亚栋 on 2017/11/7.
//  Copyright © 2017年 黄亚栋. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CameraViewControllerDelegate <NSObject>

-(void)overCamera:(UIImage *)image;

@end

@interface CameraViewController : UIViewController

@property (nonatomic,weak)id<CameraViewControllerDelegate> delegate;

@end
