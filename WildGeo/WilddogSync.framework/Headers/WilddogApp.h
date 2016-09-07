//
//  WilddogApp.h
//  Wilddog
//
//  Created by zhanShen3 on 15/7/8.
//  Copyright (c) 2015年 Wilddog. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *
 */
@interface WilddogApp : NSObject

/**
 *  断开与Wilddog服务器的连接
 */
- (void)goOffline;

/**
 *  恢复与Wilddog服务器的连接
 */
- (void)goOnline;

@end

NS_ASSUME_NONNULL_END

