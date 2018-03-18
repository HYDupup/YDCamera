//
//  YDCameraToolBar.h
//  YDCamera
//
//  Created by 黄亚栋 on 2017/11/10.
//  Copyright © 2017年 黄亚栋. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YDImageType.h"

@protocol YDCameraToolBarDelegate <NSObject>

-(void)toolBarFlashBtn:(int)flashIndex;
-(void)toolBarExchangeBtn;
-(void)toolBarShotScaleBtn:(shotScale)shotScale;
-(void)toolBarShotTypeBtn:(shotType)shotType;
//-(void)toolBarSaveBtn;
-(void)toolBarkBackBtn;

@end

@interface YDCameraToolBar : UIView
@property (nonatomic,weak)id<YDCameraToolBarDelegate> delegate;
-(void)rotateSubviews:(shotDirection)shotDirection;


@end
