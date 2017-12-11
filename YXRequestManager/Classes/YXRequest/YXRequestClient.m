//
//  YXRequestClient.m
//  Pods
//
//  Created by jiaguoshang on 2017/10/31.
//
//

#import "YXRequestClient.h"
#import "YXRequestApi.h"
#import "YXRequestConfig.h"
#import "YXRequestManager.h"
#import "YXCacheCenter.h"
#import <AFNetworking/AFNetworkActivityIndicatorManager.h>
#import <objc/message.h>
#define IsEmptyString(str)      (!str || [str isEqual:[NSNull null]] || [str isEqualToString : @""])

@interface YXRequestClient ()
    
    
@end


@implementation YXRequestClient

+ (YXRequestClient *)sharedClient
{
    static YXRequestClient *client = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        client = [[self alloc] init];
    });
    return client;
}
    
- (instancetype)init
{
    self = [super init];
    if (self) {
        [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
        [[YXRequestConfig sharedConfig] addExtraBuiltinParameters:^NSDictionary *{
            return [YXRequestConfig sharedConfig].debugEnabled ? @{@"_json": @"1", @"_debug": @"1"} : nil;
        }];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(netStatusChanged:) name:AFNetworkingReachabilityDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(systemClockDidChange:) name:NSSystemClockDidChangeNotification object:nil];

    }
    return self;
}

- (void)netStatusChanged:(NSNotification *)notification
{
    self.networkStatus = [notification.userInfo[AFNetworkingReachabilityNotificationStatusItem] integerValue];
}

- (void)systemClockDidChange:(NSNotification *)notification
{
    [self syncServeTime];
}


- (void)loadDataWithApi:(YXRequestApi *)requestApi
           successBlock:(SuccessBlock)successBlock
           failureBlock:(FailureBlock)failureBlock
{
    [self loadDataWithApi:requestApi
                 filePath:nil
                 progress:nil
constructingBodyWithBlock:nil
             successBlock:successBlock
             failureBlock:failureBlock];

}


#pragma mark - download request

- (void)downloadTaskWithApi:(YXRequestApi *)requestApi
                   filePath:(NSString *)filePath
               successBlock:(SuccessBlock)successBlock
               failureBlock:(FailureBlock)failureBlock
{
    [self downloadTaskWithApi:requestApi
                     filePath:filePath
                     progress:nil
                 successBlock:successBlock
                 failureBlock:failureBlock];
}

- (void)downloadTaskWithApi:(YXRequestApi *)requestApi
                   filePath:(NSString *)filePath
                   progress:(nullable void (^)(NSProgress *downloadProgress))downloadProgressBlock
               successBlock:(SuccessBlock)successBlock
               failureBlock:(FailureBlock)failureBlock
{
    [self loadDataWithApi:requestApi
                 filePath:filePath
                 progress:downloadProgressBlock
constructingBodyWithBlock:nil
             successBlock:successBlock
             failureBlock:failureBlock];
}

#pragma mark - upload request

- (void)uploadTaskWithApi:(YXRequestApi *)requestApi
constructingBodyWithBlock:(void (^)(id<AFMultipartFormData>))constructingBlock
             successBlock:(SuccessBlock)successBlock
             failureBlock:(FailureBlock)failureBlock
{
    [self uploadTaskWithApi:requestApi
  constructingBodyWithBlock:constructingBlock
                   progress:nil
               successBlock:successBlock
               failureBlock:failureBlock];
}

- (void)uploadTaskWithApi:(YXRequestApi *)requestApi
constructingBodyWithBlock:(void (^)(id<AFMultipartFormData>))constructingBlock
                 progress:(void (^)(NSProgress *uploadPrgress))uploadProgressBlock
             successBlock:(SuccessBlock)successBlock
             failureBlock:(FailureBlock)failureBlock
{
    [self loadDataWithApi:requestApi
                 filePath:nil
                 progress:uploadProgressBlock
constructingBodyWithBlock:constructingBlock
             successBlock:successBlock
             failureBlock:failureBlock];
}

- (void)validateProperty:(YXRequestApi *)requestApi
{
    if (IsEmptyString(requestApi.apiPath)) {
        NSCAssert(NO, @"请求URL的path不应为空,请检查");
        return;
    }
    if (IsEmptyString(requestApi.baseURL)) {
        if (IsEmptyString([YXRequestConfig sharedConfig].baseURL)) {
            NSCAssert(NO, @"请求URL的path不应为空,请检查");
            return;
        } else {
            requestApi.setBaseURL([YXRequestConfig sharedConfig].baseURL);
        }
    }
}

- (void)loadDataWithApi:(YXRequestApi *)requestApi
               filePath:(NSString *)filePath
               progress:(nullable void (^)(NSProgress *loadProgress))loadProgressBlock
constructingBodyWithBlock:(void (^)(id<AFMultipartFormData>))constructingBlock
           successBlock:(SuccessBlock)successBlock
           failureBlock:(FailureBlock)failureBlock
{
    //校验api的各个属性值得正确性
    [self validateProperty:requestApi];
        
    //判断是否需要展示提示框
    if (requestApi.showHUD) {
        if (!IsEmptyString([YXRequestConfig sharedConfig].hudClassName)) {
            ((void (*)(id, SEL))objc_msgSend)([NSClassFromString([YXRequestConfig sharedConfig].hudClassName) class], @selector(show));
        } else {
            NSCAssert(NO, @"请配置HUD类名");
        }
    }
    
    //开始请求
    [[YXRequestManager sharedManager] startRequestApi:requestApi
                                             filePath:filePath
                                             progress:loadProgressBlock
                            constructingBodyWithBlock:constructingBlock
                                      completeHandler:^(NSDictionary *result, NSError *error) {
        
        //处理几个全局的blockHandler
        if ([YXRequestConfig sharedConfig].errorMsgHandler) {
            [YXRequestConfig sharedConfig].errorMsgHandler(result, error);
        }
        
        if ([YXRequestConfig sharedConfig].logoutAccountHandler) {
            [YXRequestConfig sharedConfig].logoutAccountHandler(result, error);
        }
        
        if ([YXRequestConfig sharedConfig].changeTokenHandler) {
            [YXRequestConfig sharedConfig].changeTokenHandler(result, error);
        }
        
        if (!error) {//请求成功的回调
            if ([YXRequestConfig sharedConfig].hudClassName) {
                ((void (*)(id, SEL))objc_msgSend)([NSClassFromString([YXRequestConfig sharedConfig].hudClassName) class], @selector(hide));
            }
            if (successBlock) {
                successBlock(result);
            }
            if (requestApi.needCache) {
                [[YXCacheCenter sharedInstance] setObject:result
                                                   forKey:requestApi.apiPath
                                               withParams:requestApi.params
                                             withCallback:nil];
            }
        } else {//请求失败的回调
            if (failureBlock) {
                if (requestApi.needCache) {//需要缓存,从缓存中读取数据
                    [[YXCacheCenter sharedInstance] objectForKey:requestApi.apiPath
                                                      withParams:requestApi.params
                                                    withCallback:^(NSString *key, id object) {
                                                        if ([YXRequestConfig sharedConfig].hudClassName) {
                                                            ((void (*)(id, SEL))objc_msgSend)([NSClassFromString([YXRequestConfig sharedConfig].hudClassName) class], @selector(hide));
                                                        }
                                                        if (object && successBlock && [object isKindOfClass:[NSDictionary class]]) {
                                                            successBlock(object);
                                                        } else {
                                                            failureBlock(error);
                                                        }
                                                    }];
                } else {
                    if ([YXRequestConfig sharedConfig].hudClassName) {
                        ((void (*)(id, SEL))objc_msgSend)([NSClassFromString([YXRequestConfig sharedConfig].hudClassName) class], @selector(hide));
                    }
                    failureBlock(error);
                }
            } else {
                if ([YXRequestConfig sharedConfig].hudClassName) {
                    ((void (*)(id, SEL))objc_msgSend)([NSClassFromString([YXRequestConfig sharedConfig].hudClassName) class], @selector(hide));
                }
            }
        }
    }];

}

#pragma mark - 取消请求

- (void)cancelRequestApi:(YXRequestApi *)requestApi
{
    [[YXRequestManager sharedManager] cancelRequestApi:requestApi];
}

- (void)cancelRequestApis:(NSArray<YXRequestApi *> *)apis
{
    if (!apis || apis.count == 0) {
        return;
    }
    [[YXRequestManager sharedManager] cancelRequestApis:apis];
}

- (void)cancelAllRequests
{
    [[YXRequestManager sharedManager] cancelAllRequests];
}

#pragma mark - 同步服务器时间

- (void)syncServeTime
{
    [self syncServeTimeWithSuccessBlock:nil failureBlock:nil];
}

- (void)syncServeTimeWithSuccessBlock:(SuccessBlock)successBlock
                         failureBlock:(FailureBlock)failureBlock
{
    YXRequestApi *syncTimeApi = [[YXRequestApi alloc] init];
    syncTimeApi.setBaseURL([YXRequestConfig sharedConfig].baseURL)
    .setApiPath(@"cap/syncTime/1.0")
    .setRequestMethodType(YX_Request_GET)
    .setShowHUD(NO)
    .setParams(@{});
    [[YXRequestClient sharedClient] loadDataWithApi:syncTimeApi successBlock:^(NSDictionary *result) {
        NSTimeInterval serverTime = [[result objectForKey:@"time"] doubleValue];
        NSTimeInterval localTime = ceil([[NSDate date] timeIntervalSince1970] * 1000);
        if (fabs(serverTime - localTime) > 300 * 1000) {
            [YXRequestConfig sharedConfig].timeOffset = serverTime - localTime;
        } else {
            [YXRequestConfig sharedConfig].timeOffset = 0;
        }
        if (successBlock) {
            successBlock(result);
        }
    } failureBlock:^(NSError *error) {
        if (failureBlock) {
            failureBlock(error);
        }
    }];
}



@end
