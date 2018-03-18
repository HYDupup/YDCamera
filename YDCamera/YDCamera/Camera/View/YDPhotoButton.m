//
//  YDPhotoButton.m
//  YDCamera
//
//  Created by 黄亚栋 on 2017/11/17.
//  Copyright © 2017年 黄亚栋. All rights reserved.
//

#import "YDPhotoButton.h"

@implementation YDPhotoButton

-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self creatView];
    }
    return self;
}

-(void)creatView{
    UIBezierPath *ring = [UIBezierPath bezierPathWithArcCenter:CGPointMake(self.frame.size.width/2, self.frame.size.height/2) radius:self.frame.size.width/2-5 startAngle:-M_PI_2 endAngle:M_PI*2-M_PI_2 clockwise:YES];
    CAShapeLayer *baseShaper = [CAShapeLayer new];
    baseShaper.fillColor = [UIColor clearColor].CGColor;
    baseShaper.strokeColor = [[UIColor grayColor] colorWithAlphaComponent:0.5f].CGColor;
    baseShaper.lineWidth = 5.0f;
    baseShaper.path = ring.CGPath;
    [self.layer addSublayer:baseShaper];
    
    self.shaperLayer = [CAShapeLayer new];
    self.shaperLayer.fillColor = [UIColor clearColor].CGColor;
    self.shaperLayer.strokeColor = [UIColor redColor].CGColor;
    self.shaperLayer.lineWidth = 5.0f;
    self.shaperLayer.lineCap = kCALineCapRound;
    self.shaperLayer.strokeStart = 0;
    self.shaperLayer.strokeEnd = 0;
    self.shaperLayer.path = ring.CGPath;
    [self.layer addSublayer:self.shaperLayer];
    
    self.timeLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, self.frame.size.width-10, self.frame.size.height-10)];
    self.timeLabel.center = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
    [self.timeLabel setFont:[UIFont systemFontOfSize:16.0f]];
    self.timeLabel.textAlignment = NSTextAlignmentCenter;
    [self.timeLabel setTextColor:[UIColor whiteColor]];
    self.timeLabel.text = @"0.0";
    [self addSubview:self.timeLabel];
}

-(void)progressRing:(CGFloat)ratio andTime:(NSString *)time{
//    NSLog(@"ratio=%f time=%@",ratio,time);
    
    self.shaperLayer.strokeEnd = ratio;
    self.timeLabel.text = time;
}

-(void)restore{
    self.shaperLayer.strokeEnd = 0;
    self.timeLabel.text = @"0.0";

}

@end
