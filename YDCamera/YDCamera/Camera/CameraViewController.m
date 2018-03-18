//
//  CameraViewController.m
//  YDCamera
//
//  Created by 黄亚栋 on 2017/11/7.
//  Copyright © 2017年 黄亚栋. All rights reserved.
//

#import "CameraViewController.h"
#import "YDCamera.h"

#define ScreenBounds   [UIScreen mainScreen].bounds
#define UIScreenWidth  ScreenBounds.size.width
#define UIScreenHeight ScreenBounds.size.height

@interface CameraViewController ()<YDCameraDelegate>

@property (nonatomic,strong)YDCamera *camera;

@end

@implementation CameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
   
    self.camera = [[YDCamera alloc]initWithFrame:self.view.bounds];
    self.camera.delegate = self;
    [self.view addSubview:self.camera];
    
   
    
}

#pragma mark YDCameraDelegate
-(void)unableUserCamera{
    [self addAlert];
}

-(void)clickToolPhotoBtn:(UIImage *)image{
    if ([self.delegate respondsToSelector:@selector(overCamera:)]) {
        [self.delegate overCamera:image];
        [self dismissViewControllerAnimated:YES completion:^{
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        }];
    }
}

-(void)clickToolBackBtn{
    [self dismissViewControllerAnimated:YES completion:^{
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    }];
}

#pragma 提示
-(void)addAlert{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"前往设置中心，打开权限" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *ensure = [UIAlertAction actionWithTitle:@"前往" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
                [alert dismissViewControllerAnimated:YES completion:nil];
            }];
        }
    }];
    
    [alert addAction:cancel];
    [alert addAction:ensure];
    
    [self presentViewController:alert animated:YES completion:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
