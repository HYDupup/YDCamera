//
//  YDAssetOpreration.h
//  YDCamera
//
//  Created by 黄亚栋 on 2017/11/15.
//  Copyright © 2017年 黄亚栋. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "YDImageType.h"

@protocol YDAssetOprerationDelegate <NSObject>

-(void)sendVideoError:(NSError *)error;

@end


@interface YDAssetOpreration : NSObject

-(instancetype)initWithTransform:(shotDirection)shotDirection andPosition:(AVCaptureDevicePosition)position;
-(void)addAssetAudioInput:(CMFormatDescriptionRef)descriptionRef;
-(void)addAssetVideoInput:(CMFormatDescriptionRef)descriptionRef;
-(void)writerSanoleBuffer:(CMSampleBufferRef)sampleBufferRef andType:(NSString *)mediaType;
-(void)finishVideo:(void(^)(BOOL isSave))handle;



@property (nonatomic,strong)AVAssetWriter *assetWriter;
@property (nonatomic,strong)AVAssetWriterInput *assetVideoInput;
@property (nonatomic,strong)AVAssetWriterInput *assetAudioInput;
@property (nonatomic,copy)NSURL *urlPath;//存储沙盒地址
@property (nonatomic,weak)id<YDAssetOprerationDelegate> delegate;

@end
