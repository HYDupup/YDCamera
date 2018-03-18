//
//  YDCameraToolBar.m
//  YDCamera
//
//  Created by 黄亚栋 on 2017/11/10.
//  Copyright © 2017年 黄亚栋. All rights reserved.
//

#import "YDCameraToolBar.h"

@interface YDCameraToolBar()

@property (nonatomic,strong)UIButton *flashBtn;
@property (nonatomic,strong)UIButton *shotScaleBtn;
@property (nonatomic,strong)UIButton *shotTypeBtn;
@property (nonatomic,strong)UIButton *exchangeBtn;
@property (nonatomic,strong)UIButton *backBtn;

@end

static int flashIndex = 0;
static int shotScaleIndex = 0;
static int shotTypeIndex = 0;

@implementation YDCameraToolBar

-(instancetype)initWithFrame:(CGRect)frame{
    
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor clearColor]];
        [self creatUI];
        
    }
    return self;
}

#pragma mark CreatUI
-(void)creatUI{
    
    //闪光灯
    self.flashBtn = [[UIButton alloc]initWithFrame:CGRectMake(10, 0, 30, 30)];
    [self.flashBtn setBackgroundImage:[UIImage imageNamed:@"FlashOff"] forState:UIControlStateNormal];
    [self.flashBtn addTarget:self action:@selector(clickFlashBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.flashBtn];
    
    
    //镜头比例
    self.shotScaleBtn = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(self.flashBtn.frame)+10, self.flashBtn.frame.origin.y, 30, 30)];
    [self.shotScaleBtn setTitle:@"9:16" forState:UIControlStateNormal];
    [self.shotScaleBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.shotScaleBtn.titleLabel setFont:[UIFont systemFontOfSize:14.0f]];
    [self.shotScaleBtn addTarget:self action:@selector(shotScaleBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.shotScaleBtn];

    //拍照类型
    self.shotTypeBtn = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(self.shotScaleBtn.frame)+10, self.shotScaleBtn.frame.origin.y, 30, 30)];
    [self.shotTypeBtn setBackgroundImage:[UIImage imageNamed:@"photo"] forState:UIControlStateNormal];
    [self.shotTypeBtn addTarget:self action:@selector(clickshotTypeBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.shotTypeBtn];
    
    //切换镜头
    self.exchangeBtn = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(self.shotTypeBtn.frame)+10, self.shotTypeBtn.frame.origin.y, 30, 30)];
    [self.exchangeBtn setBackgroundImage:[UIImage imageNamed:@"swapButton"] forState:UIControlStateNormal];
    [self.exchangeBtn addTarget:self action:@selector(clickExchangeBtn) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.exchangeBtn];
    
    //返回按钮
    self.backBtn = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(self.exchangeBtn.frame)+10, self.exchangeBtn.frame.origin.y, 30, 30)];
    [self.backBtn setBackgroundImage:[UIImage imageNamed:@"closeButton"] forState:UIControlStateNormal];
    [self.backBtn addTarget:self action:@selector(clickBackBtn) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.backBtn];
}

#pragma mark 闪光灯
-(void)clickFlashBtn:(UIButton *)sender{
    flashIndex ++;
    flashIndex = flashIndex>3 ? 0 : flashIndex;
    switch (flashIndex) {
        case 0:
            [sender setBackgroundImage:[UIImage imageNamed:@"FlashOff"] forState:UIControlStateNormal];
            break;
        case 1:
            [sender setBackgroundImage:[UIImage imageNamed:@"FlashOn"] forState:UIControlStateNormal];
            break;
        case 2:
            [sender setBackgroundImage:[UIImage imageNamed:@"FlashAuto"] forState:UIControlStateNormal];
            break;
        case 3:
            [sender setBackgroundImage:[UIImage imageNamed:@"TorchOn"] forState:UIControlStateNormal];
            break;
        default:
            break;
    }
    if ([self.delegate respondsToSelector:@selector(toolBarFlashBtn:)]) {
        [self.delegate toolBarFlashBtn:flashIndex];
    }
}

#pragma mark 切换镜头
-(void)clickExchangeBtn{
    if ([self.delegate respondsToSelector:@selector(toolBarExchangeBtn)]) {
        [self.delegate toolBarExchangeBtn];
    }
}

#pragma mark 拍摄模式
-(void)clickshotTypeBtn:(UIButton *)sender{
    shotTypeIndex ++;
    shotTypeIndex = shotTypeIndex > 1 ? 0 : shotTypeIndex;
    shotType shot = (shotType)shotTypeIndex;
    switch (shot) {
        case shotPhoto:
            [sender setBackgroundImage:[UIImage imageNamed:@"photo"] forState:UIControlStateNormal];
            break;
        case shotVideo:
            [sender setBackgroundImage:[UIImage imageNamed:@"video"] forState:UIControlStateNormal];
            break;
        default:
            break;
    }
    if ([self.delegate respondsToSelector:@selector(toolBarShotTypeBtn:)]) {
        [self.delegate toolBarShotTypeBtn:shot];
    }
    
}

#pragma mark 切换镜头比例
-(void)shotScaleBtn:(UIButton *)sender{
    shotScaleIndex ++;
    shotScaleIndex = shotScaleIndex>2 ? 0 : shotScaleIndex;
    shotScale shotScleType = (shotScale)shotScaleIndex;
    switch (shotScleType) {
        case Scale9To16:
            [sender setTitle:@"9:16" forState:UIControlStateNormal];
            break;
        case Scale3To4:
            [sender setTitle:@"3:4" forState:UIControlStateNormal];
            break;
        case Scale1To1:
            [sender setTitle:@"1:1" forState:UIControlStateNormal];
            break;
        default:
            break;
    }
    if ([self.delegate respondsToSelector:@selector(toolBarShotScaleBtn:)]) {
        [self.delegate toolBarShotScaleBtn:shotScleType];
    }
}

//#pragma mark 保存视频
//-(void)clickSaveBtn{
//    if ([self.delegate respondsToSelector:@selector(toolBarSaveBtn)]) {
//        [self.delegate toolBarSaveBtn];
//    }
//}

#pragma mark 点击返回按钮
-(void)clickBackBtn{
    if ([self.delegate respondsToSelector:@selector(toolBarkBackBtn)]) {
        [self.delegate toolBarkBackBtn];
    }
}

#pragma mark 旋转控件
-(void)rotateSubviews:(shotDirection)shotDirection{
    if (shotDirection == shotOriginal || shotDirection == shotDown) {
        [UIView animateWithDuration:0.1 animations:^{
            for (UIButton *btn in self.subviews) {
                btn.transform = CGAffineTransformIdentity;
            }
        }];
        return;
    }
    
    if (shotDirection == shotLeft) {
        [UIView animateWithDuration:0.1 animations:^{
            for (UIButton *btn in self.subviews) {
                btn.transform = CGAffineTransformRotate(CGAffineTransformIdentity, -M_PI_2);
            }
        }];
        return;
    }
    
    if (shotDirection == shotRight) {
        [UIView animateWithDuration:0.1 animations:^{
            for (UIButton *btn in self.subviews) {
                btn.transform = CGAffineTransformRotate(CGAffineTransformIdentity, M_PI_2);
            }
        }];
        return;
    }
}

@end
