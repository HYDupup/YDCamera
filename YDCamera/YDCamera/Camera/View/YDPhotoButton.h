//
//  YDPhotoButton.h
//  YDCamera
//
//  Created by 黄亚栋 on 2017/11/17.
//  Copyright © 2017年 黄亚栋. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YDPhotoButton : UIView

@property (nonatomic,strong)CAShapeLayer *shaperLayer;
@property (nonatomic,strong)UILabel *timeLabel;

-(void)progressRing:(CGFloat)ratio andTime:(NSString *)time;
-(void)restore;

@end
