//
//  YDAssetOpreration.m
//  YDCamera
//
//  Created by 黄亚栋 on 2017/11/15.
//  Copyright © 2017年 黄亚栋. All rights reserved.
//

#import "YDAssetOpreration.h"

@interface YDAssetOpreration()

@property (nonatomic,assign)shotDirection shotDirection;
@property (nonatomic,assign)AVCaptureDevicePosition devicePosition;

@end

@implementation YDAssetOpreration

-(instancetype)initWithTransform:(shotDirection)shotDirection andPosition:(AVCaptureDevicePosition)position{
    self = [super init];
    if (self) {
        self.shotDirection = shotDirection;
        self.devicePosition = position;
        NSError *error = nil;
        //先把路径下的文件给删除掉，保证录制的文件是最新的
        self.urlPath = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@",NSTemporaryDirectory(),[self getUploadFile_type:@"YDvideo" fileType:@"mov"]]];
        self.assetWriter = [AVAssetWriter assetWriterWithURL:self.urlPath fileType:AVFileTypeQuickTimeMovie error:&error];
        //使其更适合在网络上播放
        self.assetWriter.shouldOptimizeForNetworkUse = YES;
        if (error) {
            [self sendError:error];
        }
    }
    return self;
}

- (NSString *)getUploadFile_type:(NSString *)type fileType:(NSString *)fileType {
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HHmmss"];
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSDate * NowDate = [NSDate dateWithTimeIntervalSince1970:now];
    ;
    NSString * timeStr = [formatter stringFromDate:NowDate];
    NSString *fileName = [NSString stringWithFormat:@"%@_%@.%@",timeStr,type,fileType];
    return fileName;
}

#pragma mark 初始化视频输入
-(void)addAssetVideoInput:(CMFormatDescriptionRef)descriptionRef{
    if (descriptionRef) {
        CGFloat bitsPerPixel;
        CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(descriptionRef);
        NSUInteger numPixel = dimensions.width*dimensions.height;
        NSUInteger bitsPerSecord;
        if (numPixel < 640*480) {
            bitsPerPixel = 4.05;
        }else{
            bitsPerPixel = 11.4;
        }
        bitsPerSecord = bitsPerPixel*numPixel;
        
        //录制视频的一些配置
        NSDictionary *videoCompressionSettings = @{
                                                   AVVideoCodecKey : AVVideoCodecH264,//编码格式
                                                   AVVideoWidthKey : [NSNumber numberWithInteger:dimensions.width],
                                                   AVVideoHeightKey : [NSNumber numberWithInteger:dimensions.height],
                                                   AVVideoCompressionPropertiesKey : @{
                                                           AVVideoAverageBitRateKey : [NSNumber numberWithInteger:bitsPerSecord],
                                                           AVVideoMaxKeyFrameIntervalKey : [NSNumber numberWithInteger:30]
                                                           }//压缩性能
                                                   };
        if ([self.assetWriter canApplyOutputSettings:videoCompressionSettings forMediaType:AVMediaTypeVideo]) {
            AVAssetWriterInput *videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoCompressionSettings];
            //表明输入是否应该调整其处理为实时数据源的数据
            videoInput.expectsMediaDataInRealTime = YES;
            videoInput.transform = [self correctTransform];
            self.assetVideoInput = videoInput;
            if ([self.assetWriter canAddInput:self.assetVideoInput]) {
                [self.assetWriter addInput:self.assetVideoInput];
            }else{
                [self sendError:self.assetWriter.error];
            }
        }else{
            [self sendError:self.assetWriter.error];
        }
    }
}

#pragma mark 调整视频方向
-(CGAffineTransform)correctTransform{
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    if (self.devicePosition == AVCaptureDevicePositionFront) {
        transform = CGAffineTransformRotate(transform, -M_PI_2);
        switch (self.shotDirection) {
            case shotOriginal:
                break;
            case shotRight:
                transform = CGAffineTransformRotate(transform, -M_PI_2);
                break;
            case shotDown:
                transform = CGAffineTransformRotate(transform, M_PI);
                break;
            case shotLeft:
                transform = CGAffineTransformRotate(transform, M_PI_2);
                break;
            default:
                break;
        }
         transform = CGAffineTransformScale(transform, -1, 1);
    }
    if (self.devicePosition == AVCaptureDevicePositionBack) {
        transform = CGAffineTransformRotate(transform, M_PI_2);
        switch (self.shotDirection) {
            case shotOriginal:
                break;
            case shotRight:
                transform = CGAffineTransformRotate(transform, -M_PI_2);
                break;
            case shotDown:
                transform = CGAffineTransformRotate(transform, M_PI);
                break;
            case shotLeft:
                transform = CGAffineTransformRotate(transform, M_PI_2);
                break;
            default:
                break;
        }
    }
    return transform;
}


#pragma mark 初始化音频输入
-(void)addAssetAudioInput:(CMFormatDescriptionRef)descriptionRef{
    if (descriptionRef) {
        size_t size = 0;
        const AudioStreamBasicDescription *currentASBD = CMAudioFormatDescriptionGetStreamBasicDescription(descriptionRef);
        const AudioChannelLayout *currenACL = CMAudioFormatDescriptionGetChannelLayout(descriptionRef, &size);
        NSData *audioChannelLayoutData = nil;
        if (audioChannelLayoutData && size > 0) {
            audioChannelLayoutData = [NSData dataWithBytes:currenACL length:size];
        }else{
            audioChannelLayoutData = [NSData data];
        }
        if (currentASBD->mSampleRate && currentASBD->mChannelsPerFrame && audioChannelLayoutData) {
            //音频的一些配置
            NSDictionary *audioCompressionSettings = @{
                                                       AVFormatIDKey : [NSNumber numberWithInteger:kAudioFormatMPEG4AAC],//ACC
                                                       AVSampleRateKey : [NSNumber numberWithInteger:currentASBD->mSampleRate],//采样率
                                                       AVEncoderBitRateKey : [NSNumber numberWithInteger:64000],//音频的比特率
                                                       AVNumberOfChannelsKey : [NSNumber numberWithInteger:currentASBD->mChannelsPerFrame],//音频通道
                                                       AVChannelLayoutKey : audioChannelLayoutData
                                                       };
            if ([self.assetWriter canApplyOutputSettings:audioCompressionSettings forMediaType:AVMediaTypeAudio]) {
                AVAssetWriterInput *audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioCompressionSettings];
                //表明输入是否应该调整其处理为实时数据源的数据
                audioInput.expectsMediaDataInRealTime = YES;
                self.assetAudioInput = audioInput;
                if ([self.assetWriter canAddInput:self.assetAudioInput]) {
                    [self.assetWriter addInput:self.assetAudioInput];
                }else{
                    [self sendError:self.assetWriter.error];
                }
            }else{
                [self sendError:self.assetWriter.error];
            }
        }
    }
}

#pragma mark 写入文件 
-(void)writerSanoleBuffer:(CMSampleBufferRef)sampleBufferRef andType:(NSString *)mediaType{
    if (self.assetWriter.status == AVAssetWriterStatusUnknown) {
        if ([self.assetWriter startWriting]) {
            [self.assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBufferRef)];
        }
    }
    
    if (self.assetWriter.status == AVAssetWriterStatusWriting) {
        if (mediaType == AVMediaTypeVideo) {
            if (!self.assetVideoInput.readyForMoreMediaData) {
                return;
            }
            if (![self.assetVideoInput appendSampleBuffer:sampleBufferRef]) {
                [self sendError:self.assetWriter.error];
            }
        }else if(mediaType == AVMediaTypeAudio){
            if (!self.assetAudioInput.readyForMoreMediaData) {
                return;
            }
            if (![self.assetAudioInput appendSampleBuffer:sampleBufferRef]) {
                [self sendError:self.assetWriter.error];
            }
        }
    }
}

#pragma mark 完成录制
-(void)finishVideo:(void(^)(BOOL isSave))handle{
  [self.assetWriter finishWritingWithCompletionHandler:^{
      BOOL isSave = NO;
      switch (self.assetWriter.status) {
          case AVAssetWriterStatusCompleted:
              isSave = YES;
              break;
          case AVAssetWriterStatusFailed:
              isSave = NO;
              break;
          default:
              break;
      }
      handle(isSave);
  }];
}


-(void)setAssetVideoInput:(AVAssetWriterInput *)assetVideoInput{
    if (!_assetVideoInput) {
        _assetVideoInput = assetVideoInput;
    }
}

-(void)setAssetAudioInput:(AVAssetWriterInput *)assetAudioInput{
    if (!_assetAudioInput) {
        _assetAudioInput = assetAudioInput;
    }
}


-(void)sendError:(NSError *)error{
    NSLog(@"dddd %@",error.localizedDescription);
    if ([self.delegate respondsToSelector:@selector(sendVideoError:)]) {
        [self.delegate sendVideoError:error];
    }
}

-(void)dealloc{
    self.assetWriter = nil;
    self.assetAudioInput = nil;
    self.assetVideoInput = nil;
}


@end
