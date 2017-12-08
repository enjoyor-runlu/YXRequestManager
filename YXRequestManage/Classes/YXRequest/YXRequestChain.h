//
//  YXRequestChain.h
//  Pods
//
//  Created by jiaguoshang on 2017/5/3.
//
//

#import <Foundation/Foundation.h>
#import "YXRequestApi.h"

typedef void(^Callback)(NSDictionary *result, NSError *error);

@interface YXRequestChain : NSObject
/**
 链式请求成功结束之后的回调
 */
@property (nonatomic, copy) void(^chainFinishedCallback)(YXRequestApi *requestApi, NSDictionary *result);
/**
 链式请求失败之后的回调
 */
@property (nonatomic, copy) void(^chainFailureCallback)(YXRequestApi *requestApi, NSError *error);

/**
 添加请求

 @param requestApi 请求类
 */
- (void)addChainRequest:(YXRequestApi *)requestApi;

/**
 添加请求,支持回调

 @param requestApi 请求类
 @param callback requestApi回调函数
 */
- (void)addChainRequest:(YXRequestApi *)requestApi callback:(Callback)callback;

/**
 开始链式请求
 */
- (void)start;
/**
 停止链式请求,取消正在进行或者还未开始的请求
 */
- (void)stop;

@end
