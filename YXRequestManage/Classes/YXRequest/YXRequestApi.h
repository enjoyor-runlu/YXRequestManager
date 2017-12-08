//
//  YXRequestApi.h
//  Pods
//
//  Created by jiaguoshang on 2017/10/31.
//
//

#import "YXBaseRequestApi.h"

@interface YXRequestApi : YXBaseRequestApi

/**
 请求接口的path
 */
@property (nonatomic, copy, readonly)   NSString          *apiPath;
/**
 请求的http类型,默认GET类型
 */
@property (nonatomic, assign, readonly) RequestMethodType requestMethodType;
/**
 请求基于的URL
 */
@property (nonatomic, copy, readonly)   NSString          *baseURL;
/**
 请求的参数
 */
@property (nonatomic, strong, readonly) NSMutableDictionary      *params;
/**
 接口超时时间,默认是20秒
 */
@property (nonatomic, assign, readonly) NSInteger         timeoutInterval;
/**
 是否展示加载框,默认展示
 */
@property (nonatomic, assign, readonly) BOOL              showHUD;
/**
 是否需要缓存数据,默认不需要
 */
@property (nonatomic, assign, readonly) BOOL              needCache;
/**
 是否允许同时发送多个同一请求,默认NO
 */
@property (nonatomic, assign, readonly) BOOL              allowConcurrentExecution;
/**
 baseURL+apiPath组成的完整URL
 */
@property (nonatomic, copy, readonly)   NSString          *intactURL;

//链式调用方式

/**
 设置接口路径
 */
- (YXRequestApi *(^)(NSString *apiPath))setApiPath;
/**
 设置接口请求方式
 */
- (YXRequestApi *(^)(RequestMethodType requestMethodType))setRequestMethodType;
/**
 设置接口请求URL
 */
- (YXRequestApi *(^)(NSString *baseURL))setBaseURL;
/**
 设置接口请求参数
 */
- (YXRequestApi *(^)(NSDictionary *params))setParams;
/**
 重新设置接口请求参数
 */
- (YXRequestApi *(^)(NSDictionary *params))reSetParams;
/**
 设置接口超时时间
 */
- (YXRequestApi *(^)(NSInteger timeoutInterval))setTimeoutInterval;
/**
 设置接口是否展示菊花
 */
- (YXRequestApi *(^)(BOOL showHUD))setShowHUD;
/**
 设置接口是否需要缓存
 */
- (YXRequestApi *(^)(BOOL needCache))setNeedCache;
/**
 是否允许同时发送多个同一请求
 */
- (YXRequestApi *(^)(BOOL allowConcurrentExecution))setAllowConcurrentExecution;


@end
