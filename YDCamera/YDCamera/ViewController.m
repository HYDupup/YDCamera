//
//  ViewController.m
//  YDCamera
//
//  Created by 黄亚栋 on 2017/11/6.
//  Copyright © 2017年 黄亚栋. All rights reserved.
//

#import "ViewController.h"
#import "CameraViewController.h"

@interface ViewController ()<CameraViewControllerDelegate>

@property (nonatomic,strong)UIImageView *imageview;
@property (nonatomic,strong)UILabel *label;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.view setBackgroundColor:[UIColor whiteColor]];

    self.imageview = [[UIImageView alloc]initWithFrame:self.view.bounds];
    self.imageview.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.imageview];
    
    self.label = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 200, 200)];
    self.label.center = CGPointMake([UIScreen mainScreen].bounds.size.width/2, [UIScreen mainScreen].bounds.size.height/2);
    self.label.text = @"点击进入相机";
    self.label.font = [UIFont systemFontOfSize:16.0f];
    self.label.textColor = [UIColor blackColor];
    self.label.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.label];
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    CameraViewController *cameraVC = [[CameraViewController alloc]init];
    cameraVC.delegate = self;
    [self presentViewController:cameraVC animated:YES completion:nil];
    
}

-(void)overCamera:(UIImage *)image{
    
    self.label.hidden = YES;
    self.imageview.image = image;
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
