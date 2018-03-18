//
//  YDCamera.m
//  YDCamera
//
//  Created by 黄亚栋 on 2017/11/10.
//  Copyright © 2017年 黄亚栋. All rights reserved.
//

#import "YDCamera.h"
#import "YDCameraToolBar.h"
#import "YDPhotoButton.h"
#import "YDAssetOpreration.h"
#import "UIView+HYDUIView.h"
#import "UIImage+fixOrientation.h"

#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import <CoreMotion/CoreMotion.h>

#define ScreenBounds   [UIScreen mainScreen].bounds
#define UIScreenWidth  ScreenBounds.size.width
#define UIScreenHeight ScreenBounds.size.height
#define maxTime 60.0f

@interface YDCamera()<YDCameraToolBarDelegate,AVCaptureAudioDataOutputSampleBufferDelegate,AVCaptureVideoDataOutputSampleBufferDelegate,YDAssetOprerationDelegate>
//捕获设备：前置摄像头，后置摄像头，麦克风
@property (nonatomic,strong)AVCaptureDevice *device;//视频
@property (nonatomic,strong)AVCaptureDevice *audioDevice;//音频

@property (nonatomic,strong)AVCaptureDeviceInput *input;//捕获图像输入设备
@property (nonatomic,strong)AVCaptureDeviceInput *audioInput;//捕获音频输入设备

@property (nonatomic,strong)AVCaptureVideoDataOutput *videoOutput;//捕获视频输出元数据
@property (nonatomic,strong)AVCaptureConnection *videoConnection;//视频链接
@property (nonatomic,strong)AVCaptureAudioDataOutput *audioOutpt;//捕获音频输出元数据
@property (nonatomic,strong)AVCaptureConnection *audioConnection;//音频链接
@property (nonatomic,strong)AVCaptureStillImageOutput *imageOutput;//持续捕获图片输出元数据

@property (nonatomic,strong)YDAssetOpreration *assetOpreration;

//seesion:由他把输入输出数据结合在一起，并开启捕获设备（摄像头）
@property (nonatomic,strong)AVCaptureSession *session;
@property (nonatomic,strong)AVCaptureVideoPreviewLayer *preView;//图片预览层,实时捕获的图片

//镜头比例的mask
@property (nonatomic,strong)UIView *topView;
@property (nonatomic,strong)UIView *bottomView;

@property (nonatomic,strong)YDCameraToolBar *toolBar;//工具Bar
@property (nonatomic,assign)shotScale shotScaleType;//镜头比例类型
@property (nonatomic,assign)shotDirection shotDirection;//镜头方向
@property (nonatomic,assign)shotType shotType;//拍摄类型

@property (nonnull,strong)CMMotionManager *motionManager;//陀螺仪
@property (nonatomic,strong)UIButton *photoBtn;//拍照按钮
@property (nonatomic,strong)YDPhotoButton *YDPhotoButton;
@property (nonatomic,strong)UIButton *saveBtn;//保存视频
@property (nonatomic,strong)UIView *focusView;//聚焦的视图
@property (nonatomic,assign)int flashIndex;//闪光灯模式
@property (nonatomic,assign)CGFloat space;//焦距大小
@property (nonatomic,assign)BOOL isVideo;//是否录像
//@property (nonatomic,assign)BOOL isPause;//是否暂停
@property (nonatomic,assign)BOOL discont;//是否中断过

@end

@implementation YDCamera{
    dispatch_queue_t _captureQueue;
    dispatch_queue_t _movieWritingQueue;
    BOOL					   _readyToRecordVideo;
    BOOL					   _readyToRecordAudio;
    
    CMSampleBufferRef _videoSampleBuffer; //开始录制时,Video记录的sampleBuffer
    CMSampleBufferRef _audioSampleBuffer; //开始录制时,audio记录的sampleBuffer
    
    CMTime _firstTime;
    CMTime _pauseTime;
    CMTime _timeOffset;//录制的偏移CMTime
    CMTime _lastVideo;//记录上一次视频数据文件的CMTime
    CMTime _lastAudio;//记录上一次音频数据文件的CMTime
}

-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.flashIndex = 0;
        self.space = 1;
        self.shotScaleType = Scale9To16;
        self.shotDirection = shotOriginal;
        self.shotType = shotPhoto;
        self.isVideo = NO;
//        self.isPause = NO;
        self.discont = NO;
        
        _firstTime = kCMTimeInvalid;
        _pauseTime = CMTimeMake(0, 0);
        _timeOffset = CMTimeMake(0, 0);
        _lastVideo = CMTimeMake(0, 0);
        _lastAudio = CMTimeMake(0, 0);
        _movieWritingQueue = dispatch_queue_create("Movie Writing Queue", DISPATCH_QUEUE_SERIAL);
        _captureQueue = dispatch_queue_create("com.YDCameraCaptureOutpu", DISPATCH_QUEUE_SERIAL);
        [self startMotion];
        
        [self setBackgroundColor:[UIColor whiteColor]];
        
        if ([self canUserCamera]) {
            [self creatCamera];
            [self creatUI];
        }else{
            if ([self.delegate respondsToSelector:@selector(unableUserCamera)]) {
                [self.delegate unableUserCamera];
            }
        }
    }
    return self;
}

#pragma mark 创建相机
-(void)creatCamera{
    
    //生成会话，结合输入输出数据
    self.session = [[AVCaptureSession alloc]init];
    if ([self.session canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
        self.session.sessionPreset = AVCaptureSessionPreset1280x720;
    }else{
        self.session.sessionPreset = AVCaptureSessionPresetHigh;
    }
    
    //元数据输入
    [self addSessionInput];
    //元数据输出
    [self addSessionOutput];
    
    //使用self.session,初始化预览层，self.session负责驱动input进行信息的采集，layer负责吧图片渲染显示
    self.preView = [[AVCaptureVideoPreviewLayer alloc]initWithSession:self.session];
    self.preView.frame = CGRectMake(0, 0, self.width, self.height);
    self.preView.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.layer addSublayer:self.preView];
    
    //开始启动
    [self.session startRunning];
}

#pragma mark 元数据输入
-(void)addSessionInput{
    //视频
    //使用AVMediaTypeVideo 指明self.device代表视频，默认使用后置摄像头进行初始化
    self.device = [self cameraWithPosition:AVCaptureDevicePositionBack];
    if ([self.device lockForConfiguration:nil]) {
        //设置闪光灯
        if ([self.device isFlashModeSupported:AVCaptureFlashModeOff]) {
            [self.device setFlashMode:AVCaptureFlashModeOff];
        }
        [self.device unlockForConfiguration];
    }

    //使用设备初始化输入
    self.input = [[AVCaptureDeviceInput alloc]initWithDevice:self.device error:nil];
    if ([self.session canAddInput:self.input]) {
        [self.session addInput:self.input];
    }
    
    //音频
    self.audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    self.audioInput = [[AVCaptureDeviceInput alloc]initWithDevice:self.audioDevice error:nil];
    if ([self.session canAddInput:self.audioInput]) {
        [self.session addInput:self.audioInput];
    }
}
#pragma mark 元数据输出 
-(void)addSessionOutput{
    
    //生成图片输出对象
    self.imageOutput = [[AVCaptureStillImageOutput alloc] init];
    self.imageOutput.outputSettings = @{AVVideoCodecKey:AVVideoCodecJPEG};
    if ([self.session canAddOutput:self.imageOutput]) {
        [self.session addOutput:self.imageOutput];
    }
    
    //视频输出对象
    self.videoOutput = [[AVCaptureVideoDataOutput alloc]init];
    [self.videoOutput setAlwaysDiscardsLateVideoFrames:YES];
    [self.videoOutput setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA]}];
    [self.videoOutput setSampleBufferDelegate:self queue:_captureQueue];
    if ([self.session canAddOutput:self.videoOutput]) {
        // 判断是否支持光学防抖
        if ([self.device.activeFormat isVideoStabilizationModeSupported:AVCaptureVideoStabilizationModeCinematic]) {
            // 如果支持防抖就打开防抖
            self.videoConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeCinematic;
        }
        [self.session addOutput:self.videoOutput];
    }
    // 根据设备输出获得连接
    self.videoConnection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
    
    //音频输出对象
    self.audioOutpt = [[AVCaptureAudioDataOutput alloc]init];
    [self.audioOutpt setSampleBufferDelegate:self queue:_captureQueue];
    if ([self.session canAddOutput:self.audioOutpt]) {
        [self.session addOutput:self.audioOutpt];
    }
    self.audioConnection = [self.audioOutpt connectionWithMediaType:AVMediaTypeAudio];

}

#pragma mark 设置UI
-(void)creatUI{
    
    //聚焦视图
    self.focusView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 80, 80)];
    [self.focusView setBackgroundColor:[UIColor clearColor]];
    self.focusView.layer.borderWidth = 1.0f;
    self.focusView.layer.borderColor = [[UIColor greenColor] colorWithAlphaComponent:0.8f].CGColor;
    self.focusView.hidden = YES;
    [self addSubview:self.focusView];
    self.userInteractionEnabled = YES;
    UITapGestureRecognizer *fouseTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(fouseTap:)];
    [self addGestureRecognizer:fouseTap];
    
    //镜头比例的mask
    self.topView = [[UIView alloc]init];
    self.topView.frame = CGRectMake(0, 0, self.frame.size.width, 0);
    [self.topView setBackgroundColor:[UIColor blackColor]];
    [self addSubview:self.topView];
    self.bottomView  = [[UIView alloc]init];
    self.bottomView.frame = CGRectMake(0, self.frame.size.height, self.frame.size.width, 0);
    [self.bottomView setBackgroundColor:[UIColor blackColor]];
    [self addSubview:self.bottomView];
    
    //ToolBar
    self.toolBar = [[YDCameraToolBar alloc]initWithFrame:CGRectMake(0, 15, UIScreenWidth, 30)];
    self.toolBar.delegate = self;
    [self addSubview:self.toolBar];
    
    //拍摄
    self.photoBtn = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 70, 70)];
    self.photoBtn.center = CGPointMake(UIScreenWidth/2, UIScreenHeight-self.photoBtn.frame.size.height/2-20);
    [self.photoBtn setBackgroundImage:[UIImage imageNamed:@"cameraButton"] forState:UIControlStateNormal];
    [self.photoBtn addTarget:self action:@selector(clickPhotoBtn) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.photoBtn];
    //开始录像
    self.YDPhotoButton = [[YDPhotoButton alloc]initWithFrame:self.photoBtn.frame];
    self.YDPhotoButton.userInteractionEnabled = YES;
    UITapGestureRecognizer *videoTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(pauseVAideoTap:)];
    [self.YDPhotoButton addGestureRecognizer:videoTap];
    self.YDPhotoButton.hidden = YES;
    [self addSubview:self.YDPhotoButton];
    
    //保存按钮
    self.saveBtn = [[UIButton alloc]initWithFrame:CGRectMake(0,0, 40, 40)];
    self.saveBtn.center = CGPointMake(self.YDPhotoButton.frame.origin.x-40, self.YDPhotoButton.center.y);
    [self.saveBtn setBackgroundImage:[UIImage imageNamed:@"saveButton"] forState:UIControlStateNormal];
    [self.saveBtn addTarget:self action:@selector(clickSaveBtn) forControlEvents:UIControlEventTouchUpInside];
    self.saveBtn.hidden = YES;
    [self addSubview:self.saveBtn];
    
    //距焦
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc]initWithTarget:self action:@selector(pinch:)];
    self.userInteractionEnabled = YES;
    [self addGestureRecognizer:pinch];
    
}

#pragma mark 拍摄点击事件
-(void)clickPhotoBtn{
   
    switch (self.shotType) {
        case shotPhoto:
            self.isVideo = NO;
            [self photograph];
            break;
        case shotVideo:
            [self videograph];
            break;
        default:
            break;
    }
}

#pragma mark 拍照
-(void)photograph{
    AVCaptureConnection *connection = [self.imageOutput connectionWithMediaType:AVMediaTypeVideo];
    if (connection) {
        [self.imageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
            if (!imageDataSampleBuffer) {
                return;
            }
            
            NSData *data = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            UIImage *image = [UIImage imageWithData:data];
            if ([self.delegate respondsToSelector:@selector(clickToolPhotoBtn:)]) {
                [self.session stopRunning];
                self.session = nil;
                [self.motionManager stopDeviceMotionUpdates];
                [self.delegate clickToolPhotoBtn:[image fixOrientationWithPosition:self.device.position andShotScale:self.shotScaleType andShotDirection:self.shotDirection]];
            }
            
            //            // 保存相片到相机胶卷
            //            NSError *error1 = nil;
            //            __block PHObjectPlaceholder *createdAsset = nil;
            //            [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
            //                createdAsset = [PHAssetCreationRequest creationRequestForAssetFromImage:image].placeholderForCreatedAsset;
            //            } error:&error1];
            //            [self.session stopRunning];
        }];
    }
}


#pragma mark 切换闪光灯模式的方法
-(void)exchangeFlashModel:(NSInteger)index{
    switch (index) {
        case 0:
            if ([self.device lockForConfiguration:nil]) {
                self.device.torchMode = AVCaptureTorchModeOff;
                if ([self.device isFlashModeSupported:AVCaptureFlashModeOff]) {
                    [self.device setFlashMode:AVCaptureFlashModeOff];
                }
                [self.device unlockForConfiguration];
            }
            break;
        case 1:
            if ([self.device lockForConfiguration:nil]) {
                self.device.torchMode = AVCaptureTorchModeOff;
                if ([self.device isFlashModeSupported:AVCaptureFlashModeOn]) {
                    [self.device setFlashMode:AVCaptureFlashModeOn];
                }
                [self.device unlockForConfiguration];
            }
            break;
        case 2:
            if ([self.device lockForConfiguration:nil]) {
                self.device.torchMode = AVCaptureTorchModeOff;
                if ([self.device isFlashModeSupported:AVCaptureFlashModeAuto]) {
                    [self.device setFlashMode:AVCaptureFlashModeAuto];
                }
                [self.device unlockForConfiguration];
            }
            break;
        case 3:
            if ([self.device lockForConfiguration:nil]) {
                self.device.torchMode = AVCaptureTorchModeOn;
                [self.device unlockForConfiguration];
            }
            break;
        default:
            break;
    }
}

#pragma mark 聚焦
-(void)fouseTap:(UITapGestureRecognizer *)recognizer{
    CGPoint point = [recognizer locationInView:self];
    if (CGRectContainsPoint([self panRect], point)) {
        CGPoint focusPoint = CGPointMake( point.y /self.height ,1-point.x/self.width );
        
        self.focusView.xscale = 1.5f;
        self.focusView.yscale = 1.5f;
        self.focusView.centerX = point.x;
        self.focusView.centerY = point.y;
        self.focusView.hidden = NO;
        
        if ([self.device lockForConfiguration:nil]) {
            
            if ([self.device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
                [self.device setFocusPointOfInterest:focusPoint];
                [self.device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
            }
            
            if ([self.device isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
                [self.device setExposurePointOfInterest:focusPoint];
                [self.device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
            }
            
            [self.device unlockForConfiguration];
            
            [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.focusView.transform = CGAffineTransformIdentity;
            } completion:^(BOOL finished) {
                self.focusView.hidden = YES;
            }];
        }
    }
}

#pragma mark 焦距
-(void)pinch:(UIPinchGestureRecognizer *)recognizer{
    
    CGFloat exchangScale = 0.0f;
    if (recognizer.scale > 1) {
        exchangScale = recognizer.scale - 1;
    }else{
        exchangScale = 2 * (recognizer.scale - 1);
    }
    
    CGFloat scale = self.space + exchangScale;
    
    if (scale < 1) {
        scale = 1;
    }
    if (scale > 4) {
        scale = 4;
    }
    
    if ([self.device lockForConfiguration:nil]) {
        [self.device rampToVideoZoomFactor:scale withRate:50];
        [self.device unlockForConfiguration];
    }
    
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        self.space = scale;
    }
}

#pragma mark 镜头方向
-(void)startMotion{
    
    self.motionManager = [[CMMotionManager alloc]init];
    
    if ([self.motionManager isDeviceMotionAvailable]) {
        self.motionManager.deviceMotionUpdateInterval = 0.1;
        [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {
            double gravityX = motion.gravity.x;
            double gravityY = motion.gravity.y;
//            double gravityZ = motion.gravity.z;
//            double zTheta = atan2(gravityZ, sqrt(gravityX*gravityX+gravityY*gravityY));
            
            //手机绕自身旋转的角度
            double xyTheta = atan2(gravityX, gravityY)/M_PI * 180.0;
                        
            if ((xyTheta > 135 && xyTheta <= 180) || (xyTheta >= -180 && xyTheta < -135)) {
                //屏幕原始
                self.shotDirection = shotOriginal;
            }else if (xyTheta >= 45 && xyTheta <= 135){
                //摄像头右边
                self.shotDirection = shotLeft;
            }else if ((xyTheta >= 0 && xyTheta < 45) || (xyTheta <= 0 && xyTheta > -45)){
                //屏幕颠倒
                self.shotDirection = shotDown;
            }else if (xyTheta >= -135 && xyTheta <= -45){
                //摄像头左边
                self.shotDirection = shotRight;
            }
            [self.toolBar rotateSubviews:self.shotDirection];
        }];
    }
}


#pragma mark 录像
-(void)videograph{
        self.photoBtn.hidden = YES;
        self.YDPhotoButton.hidden = NO;
        self.saveBtn.hidden = NO;
        [UIView animateWithDuration:0.2f animations:^{
            self.toolBar.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0, -self.toolBar.frame.size.height-self.toolBar.frame.origin.y);
        } completion:^(BOOL finished) {
            //开始录像
//            dispatch_async(_movieWritingQueue, ^{
                if (!self.assetOpreration) {
                    self.isVideo = YES;
                    self.assetOpreration = [[YDAssetOpreration alloc]initWithTransform:self.shotDirection andPosition:self.device.position];
                    self.assetOpreration.delegate = self;
                }
//            });
        }];
}

#pragma mark 保存视频 继续录制
-(void)clickSaveBtn{
    if (self.isVideo) {
        //结束录像
        self.isVideo = NO;
//        dispatch_async(_movieWritingQueue, ^{
        CMTime videoSampleTime = CMSampleBufferGetPresentationTimeStamp(_videoSampleBuffer);
        CMTime audioSampleTime = CMSampleBufferGetPresentationTimeStamp(_audioSampleBuffer);
        while (CMTimeCompare(videoSampleTime, audioSampleTime) < 0) {
            videoSampleTime = CMTimeAdd(videoSampleTime, CMTimeMake(1, 30));
            [self.assetOpreration writerSanoleBuffer:_videoSampleBuffer andType:AVMediaTypeVideo];
        }
            [self.assetOpreration finishVideo:^(BOOL isSave) {
                if (isSave) {
//                    dispatch_sync(dispatch_get_main_queue(), ^{
//                            [self cleanTemp];
//                            [UIView animateWithDuration:0.2f animations:^{
//                                self.assetOpreration = nil;
//                                self.toolBar.transform = CGAffineTransformIdentity;
//                                [self.YDPhotoButton restore];
//                                self.YDPhotoButton.hidden = YES;
//                                self.saveBtn.hidden = YES;
//                                self.photoBtn.hidden = NO;
//                                self.isPause = NO;
//                                _firstTime = CMTimeMake(0, 0);
//                            }];
//                        });
                    [PHPhotoLibrary requestAuthorization:^( PHAuthorizationStatus status ) {
                        if (status != PHAuthorizationStatusAuthorized) return ;
                        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                            PHAssetCreationRequest *videoRequest = [PHAssetCreationRequest creationRequestForAsset];
                            [videoRequest addResourceWithType:PHAssetResourceTypeVideo fileURL:self.assetOpreration.urlPath  options:nil];
                        } completionHandler:^( BOOL success, NSError * _Nullable error ) {
                            dispatch_sync(dispatch_get_main_queue(), ^{
                                [self cleanTemp];
                                [UIView animateWithDuration:0.2f animations:^{
                                    self.assetOpreration = nil;
                                    self.toolBar.transform = CGAffineTransformIdentity;
                                    [self.YDPhotoButton restore];
                                    self.YDPhotoButton.hidden = YES;
                                    self.saveBtn.hidden = YES;
                                    self.photoBtn.hidden = NO;
//                                    self.isPause = NO;
                                    _firstTime = CMTimeMake(0, 0);
                                }];
                            });
                        }];
                    }];
                }
            }];
//        });
    }
}

//清除指定沙盒文件夹里的所有文件
-(void)cleanTemp{
    NSString *extension = @"mov";
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentsDirectory = NSTemporaryDirectory();
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:NULL];
    NSEnumerator *enumerator = [contents objectEnumerator];
    NSString *filename;
    while ((filename = [enumerator nextObject])) {
        if ([[filename pathExtension] isEqualToString:extension]) {
            [fileManager removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:filename] error:NULL];
        }
    }
}

#pragma mark 暂停录像
-(void)pauseVAideoTap:(UITapGestureRecognizer *)recognizer{
    
    [self clickSaveBtn];
    
//    self.isPause = !self.isPause;

}

#pragma mark AVCaptureAudioDataOutputSampleBufferDelegate
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    
    if (self.isVideo) {
//        if (!self.isPause) {
            CMFormatDescriptionRef bufferDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
            CGFloat time = 0.0f;
            @synchronized(self){
                if (self.assetOpreration) {
                    //初始化 资源输入
                    if (captureOutput == self.videoOutput) {
                        if (!self.assetOpreration.assetVideoInput) {
                            [self.assetOpreration addAssetVideoInput:bufferDescription];
                        }else{
                            [self.assetOpreration writerSanoleBuffer:sampleBuffer andType:AVMediaTypeVideo];
                            _videoSampleBuffer = sampleBuffer;
                            if (CMTIME_IS_INVALID(_firstTime)) {
                                _firstTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                            }
                        }
                    }
                    
                    if (captureOutput == self.audioOutpt) {
                        if (!self.assetOpreration.assetAudioInput) {
                            if (CMTIME_IS_VALID(_firstTime)) {
                                [self.assetOpreration addAssetAudioInput:bufferDescription];
                            }
                        }else{
                            if (CMTIME_IS_VALID(_firstTime)) {
                                [self.assetOpreration writerSanoleBuffer:sampleBuffer andType:AVMediaTypeAudio];
                                _audioSampleBuffer = sampleBuffer;
                            }
                        }
                    }
                    
                    CMTime currentTime = kCMTimeInvalid;
                    if (CMTimeCompare(CMSampleBufferGetPresentationTimeStamp(_videoSampleBuffer), CMSampleBufferGetPresentationTimeStamp(_audioSampleBuffer)) > 0) {
                        currentTime = CMSampleBufferGetPresentationTimeStamp(_audioSampleBuffer);
                    }else{
                        currentTime = CMSampleBufferGetPresentationTimeStamp(_videoSampleBuffer);
                    }
                    time = CMTimeGetSeconds(CMTimeSubtract(currentTime, _firstTime));
                    
                    if (time >= 0.0) {
                        NSLog(@"time = %f",time);
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.YDPhotoButton progressRing:time/maxTime andTime:[NSString stringWithFormat:@"%.1f",time]];
                        });
                    }
                }
           }
    }
}

//调整媒体数据的时间
- (CMSampleBufferRef)adjustTime:(CMSampleBufferRef)sample by:(CMTime)offset {
    CMItemCount count;
    CMSampleBufferGetSampleTimingInfoArray(sample, 0, nil, &count);
    CMSampleTimingInfo* pInfo = malloc(sizeof(CMSampleTimingInfo) * count);
    CMSampleBufferGetSampleTimingInfoArray(sample, count, pInfo, &count);
    for (CMItemCount i = 0; i < count; i++) {
        pInfo[i].decodeTimeStamp = CMTimeSubtract(pInfo[i].decodeTimeStamp, offset);
        pInfo[i].presentationTimeStamp = CMTimeSubtract(pInfo[i].presentationTimeStamp, offset);
    }
    CMSampleBufferRef sout;
    CMSampleBufferCreateCopyWithNewTiming(nil, sample, count, pInfo, &sout);
    free(pInfo);
    return sout;
}

#pragma mark YDAssetOprerationDelegate
-(void)sendVideoError:(NSError *)error{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"%@",error.localizedDescription);
    });
}



#pragma mark YDCameraToolBarDelegate
//切换镜头
-(void)toolBarExchangeBtn{
    
    AVCaptureDevicePosition position = self.device.position;
    if (position == AVCaptureDevicePositionBack) {
        self.device = [self cameraWithPosition:AVCaptureDevicePositionFront];
    }else if (position == AVCaptureDevicePositionFront){
        self.device = [self cameraWithPosition:AVCaptureDevicePositionBack];
    }
    [self.session beginConfiguration];
    [self.session removeInput:self.input];
    self.input = [[AVCaptureDeviceInput alloc]initWithDevice:self.device error:nil];
    if ([self.session canAddInput:self.input]) {
        [self.session addInput:self.input];
    }
    [self.session commitConfiguration];
    if (position == AVCaptureDevicePositionFront){
        [self exchangeFlashModel:self.flashIndex];
    }
}

//闪光灯
-(void)toolBarFlashBtn:(int)flashIndex{
    self.flashIndex = flashIndex;
    if (self.device.position == AVCaptureDevicePositionBack) {
        [self exchangeFlashModel:self.flashIndex];
    }
}

//拍摄类型
-(void)toolBarShotTypeBtn:(shotType)shotType{
    self.shotType = shotType;
    switch (self.shotType) {
        case shotPhoto:
            [self.photoBtn setBackgroundImage:[UIImage imageNamed:@"cameraButton"] forState:UIControlStateNormal];
            break;
        case shotVideo:
            [self.photoBtn setBackgroundImage:[UIImage imageNamed:@"playButton"] forState:UIControlStateNormal];
            break;
        default:
            break;
    }
}

//镜头比例
-(void)toolBarShotScaleBtn:(shotScale)shotScale{
    CGRect topRect = CGRectMake(0, 0, self.frame.size.width, 0);
    CGRect bottomRect = CGRectMake(0, self.frame.size.height, self.frame.size.width, 0);
    switch (shotScale) {
        case Scale9To16:
            topRect = CGRectMake(0, 0, self.frame.size.width, 0);
            bottomRect = CGRectMake(0, self.frame.size.height, self.frame.size.width, 0);
            break;
        case Scale3To4:{
            CGFloat height = (self.frame.size.height - (self.frame.size.width*4/3))/2;
            topRect = CGRectMake(0, 0, self.frame.size.width, height);
            bottomRect = CGRectMake(0, self.frame.size.height-height, self.frame.size.width, height);
            break;
        }
        case Scale1To1:{
            CGFloat height = (self.frame.size.height - self.frame.size.width)/2;
            topRect = CGRectMake(0, 0, self.frame.size.width, height);
            bottomRect = CGRectMake(0, self.frame.size.height-height, self.frame.size.width, height);
            break;
        }
        default:
            break;
    }
    
    [UIView animateWithDuration:0.3f animations:^{
        self.topView.frame = topRect;
        self.bottomView.frame = bottomRect;
    }];
    
    self.shotScaleType = shotScale;
}

//返回按钮点击事件
-(void)toolBarkBackBtn{
    if ([self.delegate respondsToSelector:@selector(clickToolBackBtn)]) {
        [self.session stopRunning];
        self.session = nil;
        [self.motionManager stopDeviceMotionUpdates];
        [self.delegate clickToolBackBtn];
    }
}


#pragma mark 捕捉当前设备镜头的类型
-(AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if (device.position == position) {
            return device;
        }
    }
    return nil;
}

#pragma mark 访问权限
-(BOOL)canUserCamera{
    
    BOOL video = YES;
    AVAuthorizationStatus VideoAuthorization = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (VideoAuthorization == AVAuthorizationStatusRestricted || VideoAuthorization == AVAuthorizationStatusDenied) {
        video = NO;
    }
    
    BOOL audio = YES;
    AVAuthorizationStatus AudioAuthorization = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (AudioAuthorization == AVAuthorizationStatusRestricted || AudioAuthorization == AVAuthorizationStatusDenied) {
        audio = NO;
    }
    
    BOOL photo = YES;
    PHAuthorizationStatus PhotoAuthorization = [PHPhotoLibrary authorizationStatus];
    if (PhotoAuthorization == PHAuthorizationStatusRestricted || PhotoAuthorization == PHAuthorizationStatusDenied) {
        photo = NO;
    }
    return (video && audio && photo);
}

#pragma mark 可触碰的范围
-(CGRect)panRect{
    CGRect panRect = CGRectMake(0, 0, 0, 0);
    switch (self.shotScaleType) {
        case Scale9To16:{
            CGFloat height = self.frame.size.width*16/9;
            panRect = CGRectMake(0, (self.frame.size.height-height)/2, self.frame.size.width, height);
            break;
        }
        case Scale3To4:{
            CGFloat height = self.frame.size.width*4/3;
            panRect = CGRectMake(0, (self.frame.size.height-height)/2, self.frame.size.width, height);
            break;
        }
        case Scale1To1:{
            CGFloat height = self.frame.size.width;
            panRect = CGRectMake(0, (self.frame.size.height-height)/2, self.frame.size.width, height);
            break;
        }
        default:
            break;
    }
    
    return panRect;
}

//-(UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event{
//    UIView *view = [super hitTest:point withEvent:event];
//    if (view == self.YDPhotoButton) {
//        return nil;
//    }
//    return view;
//}

@end
