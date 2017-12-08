//
//  YXRequestManager.h
//  Pods
//
//  Created by luminary on 2016/10/31.
//
//

#import <Foundation/Foundation.h>
#import "AFURLRequestSerialization.h"

// 内部调试日志开关 0 关闭、1 打开
#ifndef YXRequestLoggingEnabled
#define YXRequestLoggingEnabled 0
#endif

@class YXRequestApi;

@interface YXRequestManager : NSObject

+ (nonnull YXRequestManager *)sharedManager;

//发起请求
- (void)startRequestApi:(nonnull YXRequestApi *)requestApi
               filePath:(nullable NSString *)filePath
               progress:(nullable void (^)(NSProgress * _Nullable loadProgress))loadProgressBlock
constructingBodyWithBlock:(void (^_Nonnull)(_Nullable id <AFMultipartFormData>))constructingBlock
        completeHandler:(void (^_Nonnull)(NSDictionary *_Nullable, NSError *_Nullable))completeHandler;


//取消请求
- (void)cancelRequestApi:(nonnull YXRequestApi *)requestApi;

/**
 取消某几个请求
 
 @param apis 请求对应的api
 */
- (void)cancelRequestApis:(NSArray <YXRequestApi *>*_Nonnull)apis;

/**
 取消当前进行的所有请求
 */
- (void)cancelAllRequests;

@end
