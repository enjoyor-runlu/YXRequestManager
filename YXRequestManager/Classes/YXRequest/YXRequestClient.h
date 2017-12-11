//
//  YXRequestClient.h
//  Pods
//
//  Created by jiaguoshang on 2017/10/31.
//
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

@class YXRequestApi;

typedef void(^SuccessBlock)(NSDictionary * _Nullable result);

typedef void(^FailureBlock)(NSError * _Nullable error);

@interface YXRequestClient : NSObject

    
/**
 *  网络状态
 */
@property (nonatomic, assign) AFNetworkReachabilityStatus networkStatus;

+ (YXRequestClient *_Nonnull)sharedClient;
    
/**
 *  YXRequestApi 请求信息类
 *  SuccessBlock 成功回调
 *  FailureBlock 失败回调
 *
**/
- (void)loadDataWithApi:(YXRequestApi *_Nonnull)requestApi
           successBlock:(SuccessBlock _Nullable)successBlock
           failureBlock:(FailureBlock _Nullable)failureBlock;
/**
 *  下载接口,没有下载进度
 *  YXRequestApi 请求信息类
 *  filePath     存储文件路径
 *  SuccessBlock 成功回调
 *  FailureBlock 失败回调
 *
 **/
- (void)downloadTaskWithApi:(YXRequestApi *_Nonnull)requestApi
                   filePath:(NSString *_Nullable)filePath
               successBlock:(SuccessBlock _Nullable)successBlock
               failureBlock:(FailureBlock _Nullable)failureBlock;
/**
 *  下载接口,有下载进度
 *  YXRequestApi 请求信息类
 *  filePath     存储文件路径
 *  progress     下载进度
 *  SuccessBlock 成功回调
 *  FailureBlock 失败回调
 *
 **/
- (void)downloadTaskWithApi:(YXRequestApi *_Nonnull)requestApi
                   filePath:(NSString *_Nullable)filePath
                   progress:(nullable void (^)(NSProgress * _Nullable downloadProgress))downloadProgressBlock
               successBlock:(SuccessBlock _Nullable)successBlock
               failureBlock:(FailureBlock _Nullable)failureBlock;
/**
 *  上传接口,没有上传进度
 *  YXRequestApi 请求信息类
 *  constructingBlock     拼接http body的block
 *  SuccessBlock 成功回调
 *  FailureBlock 失败回调
 *
 **/
- (void)uploadTaskWithApi:(YXRequestApi *_Nonnull)requestApi
constructingBodyWithBlock:(nullable void(^)(id<AFMultipartFormData>_Nullable formData))constructingBlock
             successBlock:(SuccessBlock _Nullable)successBlock
             failureBlock:(FailureBlock _Nullable)failureBlock;

/**
 *  上传接口,有上传进度
 *  YXRequestApi 请求信息类
 *  constructingBlock     拼接http body的block
 *  progress     上传进度
 *  SuccessBlock 成功回调
 *  FailureBlock 失败回调
 *
 **/
- (void)uploadTaskWithApi:(YXRequestApi *_Nonnull)requestApi
constructingBodyWithBlock:(nullable void(^)(id<AFMultipartFormData>_Nullable formData))constructingBlock
                 progress:(nullable void (^)(NSProgress *_Nullable uploadProgress))uploadProgressBlock
             successBlock:(SuccessBlock _Nullable)successBlock
             failureBlock:(FailureBlock _Nullable)failureBlock;


/**
 *  取消某一个请求
 **/
- (void)cancelRequestApi:(YXRequestApi *_Nonnull)requestApi;

/**
 取消某几个请求

 @param apis 请求对应的api
 */
- (void)cancelRequestApis:(NSArray <YXRequestApi *>*_Nonnull)apis;

/**
 取消当前进行的所有请求
 */
- (void)cancelAllRequests;
/**
 *  同步服务器时间
 **/
- (void)syncServeTime;

/**
 同步服务器时间

 @param successBlock 成功回调
 @param failureBlock 失败回调
 */
- (void)syncServeTimeWithSuccessBlock:(SuccessBlock _Nullable)successBlock
                         failureBlock:(FailureBlock _Nullable)failureBlock;

@end
