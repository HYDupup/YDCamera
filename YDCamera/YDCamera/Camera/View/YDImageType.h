//
//  YDImageType.h
//  YDCamera
//
//  Created by 黄亚栋 on 2017/11/13.
//  Copyright © 2017年 黄亚栋. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum{
    Scale9To16 = 0,
    Scale3To4,
    Scale1To1,
}shotScale;

//以摄像头为基准方向
typedef enum{
    shotOriginal = 0,
    shotLeft,
    shotRight,
    shotDown,
}shotDirection;

typedef enum{
    shotPhoto = 0,
    shotVideo,
}shotType;

@interface YDImageType : NSObject

@end
