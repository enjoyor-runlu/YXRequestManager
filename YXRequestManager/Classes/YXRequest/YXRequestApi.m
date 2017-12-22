//
//  YXRequestApi.m
//  Pods
//
//  Created by jiaguoshang on 2017/10/31.
//
//

#import "YXRequestApi.h"

@interface YXRequestApi ()

//请求接口的path
@property (nonatomic, copy, readwrite)   NSString          *apiPath;
    
//请求的http类型
@property (nonatomic, assign, readwrite) RequestMethodType requestMethodType;
    
//请求基于的URL
@property (nonatomic, copy, readwrite)   NSString          *baseURL;
    
//请求的参数
@property (nonatomic, strong, readwrite) NSMutableDictionary      *params;
    
//接口超时时间,默认是30秒
@property (nonatomic, assign, readwrite) NSInteger         timeoutInterval;
    
//是否展示加载框
@property (nonatomic, assign, readwrite) BOOL              showHUD;

/**
 是否展示透明加载框,默认不展示
 */
@property (nonatomic, assign, readwrite) BOOL              showClearHUD;

//是否需要缓存数据
@property (nonatomic, assign, readwrite) BOOL              needCache;

//是否允许同时发送多个同一请求
@property (nonatomic, assign, readwrite) BOOL              allowConcurrentExecution;
/**
 baseURL+apiPath组成的完整URL
 */
@property (nonatomic, copy, readwrite)   NSString          *intactURL;

@end

@implementation YXRequestApi

    
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.requestMethodType = YX_Request_POST;
        self.timeoutInterval = 20;
        self.showHUD = YES;
        self.showClearHUD = NO;
        self.needCache = NO;
        self.allowConcurrentExecution = NO;
    }
    return self;
}
    
- (NSMutableDictionary *)params
{
    if (!_params) {
        _params = [NSMutableDictionary dictionary];
    }
    return _params;
}
    
- (YXRequestApi *(^)(NSString *apiPath))setApiPath
{
    return ^(NSString *apiPath) {
        self.apiPath = apiPath;
        if (self.baseURL && self.apiPath) {
            self.intactURL = [NSString stringWithFormat:@"%@%@", self.baseURL, self.apiPath];
        }
        return self;
    };
}

- (YXRequestApi *(^)(RequestMethodType requestMethodType))setRequestMethodType
{
    return ^(RequestMethodType requestMethodType){
        self.requestMethodType = requestMethodType;
        return self;
    };
}
    
- (YXRequestApi *(^)(NSString *baseURL))setBaseURL
{
    return ^(NSString *baseURL){
        self.baseURL = baseURL;
        if (self.baseURL && self.apiPath) {
            self.intactURL = [NSString stringWithFormat:@"%@%@", self.baseURL, self.apiPath];
        }
        return self;
    };
}

- (YXRequestApi *(^)(NSDictionary *params))setParams
{
    return ^(NSDictionary *params){
        if (params && params.count > 0) {
            [self.params addEntriesFromDictionary:params];
        }
        return self;
    };
}

- (YXRequestApi *(^)(NSDictionary *))reSetParams
{
    return ^(NSDictionary *params){
        if (params && params.count > 0) {
            self.params = [NSMutableDictionary dictionaryWithDictionary:params];
        }
        return self;
    };
}

- (YXRequestApi *(^)(NSInteger timeoutInterval))setTimeoutInterval
{
    return ^(NSInteger timeoutInterval){
        self.timeoutInterval = timeoutInterval;
        return self;
    };
}
    
- (YXRequestApi *(^)(BOOL showHUD))setShowHUD
{
    return ^(BOOL showHUD){
        self.showHUD = showHUD;
        return self;
    };
}

- (YXRequestApi *(^)(BOOL showClearHUD))setShowClearHUD
{
    return ^(BOOL showClearHUD){
        self.showClearHUD = showClearHUD;
        return self;
    };
}

- (YXRequestApi *(^)(BOOL needCache))setNeedCache
{
    return ^(BOOL needCache){
        self.needCache = needCache;
        return self;
    };
}

- (YXRequestApi *(^)(BOOL allowConcurrentExecution))setAllowConcurrentExecution
{
    return ^(BOOL allowConcurrentExecution){
        self.allowConcurrentExecution = allowConcurrentExecution;
        return self;
    };
}

@end
