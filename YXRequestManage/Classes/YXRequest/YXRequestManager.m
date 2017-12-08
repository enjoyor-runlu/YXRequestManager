//
//  YXRequestManager.m
//  Pods
//
//  Created by jiaguoshang on 2017/10/31.
//
//

#import "YXRequestManager.h"
#import "YXRequestConfig.h"
#import "YXRequestApi.h"
#import <YXFDCategories/YXFDCategory.h>
#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#else
#import "AFNetworking.h"
#endif


#define Lock()   dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
#define Unlock() dispatch_semaphore_signal(_semaphore)

#if YXRequestLoggingEnabled
#define LogDebug(s, ...) NSLog( @"%@:%d %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )//分别是文件名，在文件的第几行，自定义输出内容

#else
#define LogDebug(frmt, ...)     {}
#endif

#define ResponseDataFormatErrorCode   -1111111111
#define SpecialKeyValue @"1234567890"

@interface NSDictionary (CheckSafty)

- (BOOL)containKey:(NSString *)key;

- (id)safeObjectForKey:(NSString *)aKey;

@end

@implementation NSDictionary (CheckSafty)

- (id)safeObjectForKey:(NSString *)aKey
{
    if (![self containKey:aKey]) {
        return nil;
    }
    return [self objectForKey:aKey];
}

- (BOOL)containKey:(NSString *)key
{
    return [[self allKeys] containsObject:key];
}

@end



@interface YXRequestManager ()

@property (nonatomic, strong) AFHTTPSessionManager     *sessionManager;

@property (nonatomic, strong) AFJSONResponseSerializer *jsonResponseSerializer;

@property (nonatomic, strong) dispatch_semaphore_t     semaphore;

@property (nonatomic, strong) NSMutableDictionary      *requestCostTimeDic;

@property (nonatomic, strong) NSMapTable               *requestMap;//存放请求的Map

@property (nonatomic, assign) NSUInteger               requestCount;//请求的总次数

@end

@implementation YXRequestManager

+ (YXRequestManager *)sharedManager
{
    static YXRequestManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.sessionManager = [AFHTTPSessionManager manager];
        self.sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", @"text/json", @"text/javascript",@"text/plain", nil];
        [self configurationHttpsRequest];
        _semaphore = dispatch_semaphore_create(1);
        _requestCostTimeDic = [NSMutableDictionary dictionary];
        _requestCount = 0;
    }
    return self;
}

- (NSMapTable *)requestMap
{
    if (!_requestMap) {
        _requestMap = [NSMapTable strongToWeakObjectsMapTable];
    }
    return _requestMap;
}

- (AFJSONResponseSerializer *)jsonResponseSerializer
{
    if (!_jsonResponseSerializer) {
        _jsonResponseSerializer = [AFJSONResponseSerializer serializer];
    }
    return _jsonResponseSerializer;
        
}
    
    
- (AFHTTPRequestSerializer *)requestSerializerForRequest:(YXRequestApi *)requestApi {
    AFHTTPRequestSerializer *requestSerializer = nil;
    if (requestApi.requestSerializerType == YXRequestSerializerTypeHTTP) {
        requestSerializer = [AFHTTPRequestSerializer serializer];
    } else if (requestApi.requestSerializerType == YXRequestSerializerTypeJSON) {
        requestSerializer = [AFJSONRequestSerializer serializer];
    }
    requestSerializer.timeoutInterval = requestApi.timeoutInterval;
    
    return requestSerializer;
}

#pragma mark - 配置HTTPS请求

- (void)configurationHttpsRequest
{
    if ([YXRequestConfig sharedConfig].needHTTPS) {

#ifdef DEBUG
        //设置非校验证书模式,方便抓包
        AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
#else
        //AFSSLPinningModeCertificate 使用证书验证模式
        AFSecurityPolicy * securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey];
#endif
        [self.sessionManager setSecurityPolicy:securityPolicy];
    }
}


#pragma mark - 开始请求

- (void)startRequestApi:(YXRequestApi *)requestApi
               filePath:(NSString *)filePath
               progress:(void (^)(NSProgress *))loadProgressBlock
constructingBodyWithBlock:(void (^)(id<AFMultipartFormData>))constructingBlock
        completeHandler:(void (^)(NSDictionary *, NSError *))completeHandler
{
    NSError * __autoreleasing requestSerializationError = nil;
    requestApi.requestTask = [self sessionTaskForRequestApi:requestApi
                                                      error:&requestSerializationError
                                                   filePath:filePath
                                                   progress:loadProgressBlock
                                  constructingBodyWithBlock:constructingBlock
                                            completeHandler:completeHandler];
    [requestApi.requestTask resume];
}


//请求
- (NSURLSessionTask *)sessionTaskForRequestApi:(YXRequestApi *)requestApi
                                         error:(NSError * _Nullable __autoreleasing *)error
                                      filePath:(NSString *)filePath
                                      progress:(void (^)(NSProgress *))loadProgressBlock
                     constructingBodyWithBlock:(void (^)(id<AFMultipartFormData>))constructingBlock
                               completeHandler:(void (^)(NSDictionary *, NSError *))completeHandler
{
    self.requestCount++;
    NSString *urlString = [requestApi.baseURL stringByAppendingString:requestApi.apiPath];
    //计算请求URL和参数拼接字符串的MD5值
    NSString *apiMD5 = [[NSString combineURLWithBaseURL:urlString parameters:requestApi.params] yixiang_md5hashString];
    YXRequestApi *savedApi = [self.requestMap objectForKey:apiMD5];
    if (savedApi) {
        if (requestApi.allowConcurrentExecution) {
            apiMD5 = [NSString stringWithFormat:@"%@%lu", apiMD5, self.requestCount];
            [self.requestMap setObject:requestApi forKey:apiMD5];
        } else {
            return nil;
        }
    } else {
        [self.requestMap setObject:requestApi forKey:apiMD5];
    }
    requestApi.uniqueIdentify = apiMD5;
    //重新设置requestApi的请求参数
    NSDictionary *requestParams = [self generateRequestParams:requestApi];
    RequestMethodType requestType = requestApi.requestMethodType;
    NSString *url = [self buildRequestUrl:requestApi];
    AFHTTPRequestSerializer *requestSerializer = [self requestSerializerForRequest:requestApi];
    switch (requestType) {
        case YX_Request_GET:
        {
            //filePath为空,不是下载
            if (!filePath || [filePath isEqual:[NSNull null]] || [filePath isEqualToString : @""]) {
                return [self dataTaskWithRequestApi:requestApi httpMethod:@"GET" requestSerializer:requestSerializer URLString:url parameters:requestParams error:error completeHandler:completeHandler];
            } else {
                return [self downloadTaskWithRequestApi:requestApi downloadPath:filePath requestSerializer:requestSerializer URLString:url parameters:requestParams progress:loadProgressBlock error:error completeHandler:completeHandler];
            }
        }
            break;
        case YX_Request_POST:
            return [self dataTaskWithRequestApi:requestApi httpMethod:@"POST" requestSerializer:requestSerializer URLString:url parameters:requestParams constructingBodyWithBlock:constructingBlock progress:loadProgressBlock error:error completeHandler:completeHandler];
            break;
        case YX_Request_PUT:
            return [self dataTaskWithRequestApi:requestApi httpMethod:@"PUT" requestSerializer:requestSerializer URLString:url parameters:requestParams error:error completeHandler:completeHandler];
            break;
        case YX_Request_DELETE:
            return [self dataTaskWithRequestApi:requestApi httpMethod:@"DELETE" requestSerializer:requestSerializer URLString:url parameters:requestParams error:error completeHandler:completeHandler];
            break;
        case YX_Request_HEAD:
            return [self dataTaskWithRequestApi:requestApi httpMethod:@"HEAD" requestSerializer:requestSerializer URLString:url parameters:requestParams error:error completeHandler:completeHandler];
            break;
        case YX_Request_PATCH:
            return [self dataTaskWithRequestApi:requestApi httpMethod:@"PATCH" requestSerializer:requestSerializer URLString:url parameters:requestParams error:error completeHandler:completeHandler];
            break;
        
        default:
            break;
    }
}
    
#pragma mark - 拼接请求参数

//拼接请求URL,可以在这里面做URL的拼接检查,避免因为URL的问题导致请求失败
    
- (NSString *)buildRequestUrl:(YXRequestApi *)requestApi
{
    NSString *apiPath = requestApi.apiPath;
    NSString *baseURL = requestApi.baseURL;
    NSString *urlString = [baseURL stringByAppendingString:apiPath];
#warning 这里可以校验格式
    NSURL *URL = [NSURL URLWithString:urlString];
    if (URL && URL.host && URL.scheme) {
        return urlString;
    }
    return @"";
}

//拼装请求参数
- (NSDictionary *)generateRequestParams:(YXRequestApi *)requestApi
{
    //获取到外界设置进来的参数字典
    NSMutableDictionary *paramsDic = [NSMutableDictionary dictionaryWithDictionary:requestApi.params];
    [[YXRequestConfig sharedConfig].extraBuiltinParameterHandlers enumerateObjectsUsingBlock:^(ExtraBuiltinParametersHandler obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *result = obj();
        if (result && [result isKindOfClass:[NSDictionary class]]) {
            [paramsDic addEntriesFromDictionary:result];
        }
    }];
    if ([YXRequestConfig sharedConfig].builtinParameters) {
        [paramsDic addEntriesFromDictionary:[YXRequestConfig sharedConfig].builtinParameters];
    }
    if ([paramsDic containKey:@"timestamp"]) {
        NSTimeInterval timestamp = [[paramsDic safeObjectForKey:@"timestamp"] doubleValue];
        if ([YXRequestConfig sharedConfig].timeOffset != 0) {
            [paramsDic setSafeObject:@([YXRequestConfig sharedConfig].timeOffset + timestamp) forKey:@"timestamp"];
        }
    }
    NSString *sign = [self generateProtectValueSign:paramsDic];
    [paramsDic setSafeObject:sign forKey:@"sign"];
    return [paramsDic copy];
}


#pragma mark -

- (NSURLSessionDataTask *)dataTaskWithRequestApi:(YXRequestApi *)requestApi
                                      httpMethod:(NSString *)method
                               requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                       URLString:(NSString *)URLString
                                      parameters:(id)parameters
                                           error:(NSError * _Nullable __autoreleasing *)error
                                 completeHandler:(void (^)(NSDictionary *, NSError *))completeHandler
{
    return [self dataTaskWithRequestApi:requestApi
                             httpMethod:method
                      requestSerializer:requestSerializer
                              URLString:URLString
                             parameters:parameters
              constructingBodyWithBlock:nil
                                  error:error
                        completeHandler:completeHandler];
}

- (NSURLSessionDataTask *)dataTaskWithRequestApi:(YXRequestApi *)requestApi
                                      httpMethod:(NSString *)method
                               requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                       URLString:(NSString *)URLString
                                      parameters:(id)parameters
                       constructingBodyWithBlock:(nullable void (^)(id <AFMultipartFormData> formData))block
                                           error:(NSError * _Nullable __autoreleasing *)error
                                 completeHandler:(void (^)(NSDictionary *, NSError *))completeHandler
{
    
    return [self dataTaskWithRequestApi:requestApi
                             httpMethod:method
                      requestSerializer:requestSerializer
                              URLString:URLString
                             parameters:parameters
              constructingBodyWithBlock:block
                               progress:nil
                                  error:error
                        completeHandler:completeHandler];
}


- (NSURLSessionDataTask *)dataTaskWithRequestApi:(YXRequestApi *)requestApi
                                      httpMethod:(NSString *)method
                               requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                       URLString:(NSString *)URLString
                                      parameters:(id)parameters
                       constructingBodyWithBlock:(nullable void (^)(id <AFMultipartFormData> formData))block
                                        progress:(void (^)(NSProgress *))loadProgressBlock
                                           error:(NSError * _Nullable __autoreleasing *)error
                                 completeHandler:(void (^)(NSDictionary *, NSError *))completeHandler
{
    NSMutableURLRequest *request = nil;
    
    if (block) {
        request = [requestSerializer multipartFormRequestWithMethod:method URLString:URLString parameters:parameters constructingBodyWithBlock:block error:error];
    } else {
        request = [requestSerializer requestWithMethod:method URLString:URLString parameters:parameters error:error];
    }
    
    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [self.sessionManager dataTaskWithRequest:request
                                         uploadProgress:^(NSProgress * _Nonnull uploadProgress) {
                                             if (loadProgressBlock) {
                                                 loadProgressBlock(uploadProgress);
                                             }
                                         } downloadProgress:nil
                                      completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *_error) {
        
                                          [self handleRequestApi:requestApi
                                                     sessionTask:dataTask
                                                  responseObject:responseObject
                                                           error:_error
                                                 completeHandler:completeHandler
                                                      isDownload:NO];
                                      }];
    CFAbsoluteTime nowTime = CFAbsoluteTimeGetCurrent();
    Lock();
    [self.requestCostTimeDic setSafeObject:@(nowTime) forKey:@(dataTask.taskIdentifier)];
    Unlock();
    
    return dataTask;
}

#pragma mark - 处理请求结果,这个地方可以做返回数据的校验
- (void)handleRequestApi:(YXRequestApi *)requestApi
             sessionTask:(NSURLSessionTask *)task
          responseObject:(id)responseObject
                   error:(NSError *)error
         completeHandler:(void (^)(NSDictionary *, NSError *))completeHandler
              isDownload:(BOOL)isDownload

{
    Lock();
    [self.requestMap removeObjectForKey:requestApi.uniqueIdentify];
    NSString *requestStartTime = self.requestCostTimeDic[@(task.taskIdentifier)];
    [self.requestCostTimeDic removeObjectForKey:@(task.taskIdentifier)];
    Unlock();
    double costTime = (CFAbsoluteTimeGetCurrent() - requestStartTime.doubleValue) * 1000;
    LogDebug(@"task.url : %@ [%@ms]", [NSString stringWithFormat:@"%@", task.currentRequest.URL], @(costTime));
    if (isDownload) {
        if (error) {
            if (completeHandler) {
                completeHandler(nil, error);
            }
        } else {
            completeHandler(@{@"data":@{@"filePath":responseObject?responseObject:@""}}, nil);
        }
        return;
    }
    NSDictionary *jsonDic = [NSDictionary dictionary];
    NSError * __autoreleasing serializationError = nil;
    NSError *__autoreleasing defaultError = nil;
    if ([responseObject isKindOfClass:[NSData class]]) {
       id jsonData = [self.jsonResponseSerializer responseObjectForResponse:task.response data:responseObject error:&serializationError];
        if ([jsonData isKindOfClass:[NSDictionary class]]) {
            jsonDic = jsonData;
        }
    } else if ([responseObject isKindOfClass:[NSDictionary class]]) {
        jsonDic = responseObject;
    } else {
        
    }
    if (error) {
        defaultError = error;
    } else if (serializationError) {
        defaultError = serializationError;
    } else {
        id jsonCode = [jsonDic safeObjectForKey:@"code"];
        if ([jsonDic containKey:@"code"] && (([jsonCode isKindOfClass:[NSString class]] && [jsonCode isEqualToString:@"0"]) || ([jsonCode isKindOfClass:[NSNumber class]] && [[jsonCode stringValue] isEqualToString:@"0"]))) {//表示成功
            if ([jsonDic containKey:@"data"] && [[jsonDic safeObjectForKey:@"data"] isKindOfClass:[NSDictionary class]]) {
                jsonDic = [jsonDic safeObjectForKey:@"data"];
            } else {
                defaultError = [NSError errorWithDomain:@"返回data格式错误" code:ResponseDataFormatErrorCode userInfo:nil];
            }
        } else {
            NSString *domain = @"";
            NSString *code = @"";
            NSDictionary *userInfo = [NSDictionary dictionary];
            if ([jsonDic containKey:@"message"]) {
                domain = [jsonDic safeObjectForKey:@"message"];
            }
            if ([jsonDic containKey:@"code"]) {
                code = [jsonDic safeObjectForKey:@"code"];
                if ([code isKindOfClass:[NSNumber class]]) {
                    code = [[jsonDic safeObjectForKey:@"code"] stringValue];
                }
            }
            if ([jsonDic containKey:@"data"] && [[jsonDic safeObjectForKey:@"data"] isKindOfClass:[NSDictionary class]]) {
                userInfo = [jsonDic safeObjectForKey:@"data"];
            }
            defaultError = [NSError errorWithDomain:domain code:[code longLongValue] userInfo:userInfo];
        }
    }
    defaultError = [self handleErrorCode:defaultError];
    if (completeHandler) {
        completeHandler(jsonDic, defaultError);
    }
}
#pragma mark -download

- (NSURLSessionDownloadTask *)downloadTaskWithRequestApi:(YXRequestApi *)requestApi
                                            downloadPath:(NSString *)downloadPath
                                       requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                               URLString:(NSString *)URLString
                                              parameters:(id)parameters
                                                progress:(nullable void (^)(NSProgress *downloadProgress))downloadProgressBlock
                                                   error:(NSError * _Nullable __autoreleasing *)error
                                         completeHandler:(void (^)(NSDictionary *, NSError *))completeHandler
{
    NSMutableURLRequest *urlRequest = [requestSerializer requestWithMethod:@"GET" URLString:URLString parameters:parameters error:error];
    
    NSString *downloadTargetPath;
    BOOL isDirectory;
    if(![[NSFileManager defaultManager] fileExistsAtPath:downloadPath isDirectory:&isDirectory]) {
        isDirectory = NO;
    }
    if (isDirectory) {
        NSString *fileName = [urlRequest.URL lastPathComponent];
        downloadTargetPath = [NSString pathWithComponents:@[downloadPath, fileName]];
    } else {
        downloadTargetPath = downloadPath;
    }

    if ([[NSFileManager defaultManager] fileExistsAtPath:downloadTargetPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:downloadTargetPath error:nil];
    }
    
    BOOL resumeDataFileExists = [[NSFileManager defaultManager] fileExistsAtPath:[self incompleteDownloadTempPathForDownloadPath:downloadPath].path];
    NSData *data = [NSData dataWithContentsOfURL:[self incompleteDownloadTempPathForDownloadPath:downloadPath]];
    BOOL resumeDataIsValid = [[self class] validateResumeData:data];
    
    BOOL canBeResumed = resumeDataFileExists && resumeDataIsValid;
    BOOL resumeSucceeded = NO;
    __block NSURLSessionDownloadTask *downloadTask = nil;
    if (canBeResumed) {
        @try {
            downloadTask = [self.sessionManager downloadTaskWithResumeData:data progress:^(NSProgress * _Nonnull downloadProgress) {
                if (downloadProgressBlock) {
                    downloadProgressBlock(downloadProgress);
                }
            } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                return [NSURL fileURLWithPath:downloadTargetPath isDirectory:NO];
            } completionHandler:
                            ^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                                [self handleRequestApi:requestApi
                                           sessionTask:downloadTask
                                        responseObject:filePath
                                                 error:error
                                       completeHandler:completeHandler
                                            isDownload:YES];
                            }];
            resumeSucceeded = YES;
        } @catch (NSException *exception) {
            NSLog(@"Resume download failed, reason = %@", exception.reason);
            resumeSucceeded = NO;
        }
    }
    if (!resumeSucceeded) {
        downloadTask = [self.sessionManager downloadTaskWithRequest:urlRequest progress:^(NSProgress * _Nonnull downloadProgress) {
            if (downloadProgressBlock) {
                downloadProgressBlock(downloadProgress);
            }
        } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            return [NSURL fileURLWithPath:downloadTargetPath isDirectory:NO];
        } completionHandler:
                        ^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                            [self handleRequestApi:requestApi
                                       sessionTask:downloadTask
                                    responseObject:filePath
                                             error:error
                                   completeHandler:completeHandler
                                        isDownload:YES];
                        }];
    }
    return downloadTask;

}

- (NSURL *)incompleteDownloadTempPathForDownloadPath:(NSString *)downloadPath {
    NSString *tempPath = nil;
    NSString *md5URLString = [downloadPath yixiang_md5hashString];
    tempPath = [[self incompleteDownloadTempCacheFolder] stringByAppendingPathComponent:md5URLString];
    return [NSURL fileURLWithPath:tempPath];
}

- (NSString *)incompleteDownloadTempCacheFolder {
    NSFileManager *fileManager = [NSFileManager new];
    static NSString *cacheFolder;
    
    if (!cacheFolder) {
        NSString *cacheDir = NSTemporaryDirectory();
        cacheFolder = [cacheDir stringByAppendingPathComponent:@"Incomplete"];
    }
    
    NSError *error = nil;
    if(![fileManager createDirectoryAtPath:cacheFolder withIntermediateDirectories:YES attributes:nil error:&error]) {
        NSLog(@"在%@创建目录失败", cacheFolder);
        cacheFolder = nil;
    }
    return cacheFolder;
}

+ (BOOL)validateResumeData:(NSData *)data {
    if (!data || [data length] < 1) return NO;
    
    NSError *error;
    NSDictionary *resumeDictionary = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:NULL error:&error];
    if (!resumeDictionary || error) return NO;
    
    // Before iOS 9 & Mac OS X 10.11
#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED < 90000)\
|| (defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED < 101100)
    NSString *localFilePath = [resumeDictionary objectForKey:@"NSURLSessionResumeInfoLocalPath"];
    if ([localFilePath length] < 1) return NO;
    return [[NSFileManager defaultManager] fileExistsAtPath:localFilePath];
#endif
    return YES;
}

#pragma mark - 生成对应的sign值

- (NSString *)generateProtectValueSign:(NSDictionary *)params
{
    //第一步,将key和value生成对应的字符串,存入数组中
    NSMutableArray *stringArray = [NSMutableArray array];
    [params enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [stringArray addSafeObject:[NSString stringWithFormat:@"%@=%@", key, obj]];
    }];
    //第二步,将stringArray按照ASCII码从小到大排序
    NSStringCompareOptions comparisonOptions = NSNumericSearch|NSWidthInsensitiveSearch|NSForcedOrderingSearch;
    
    NSComparator sort = ^(NSString *obj1,NSString *obj2){
        NSRange range =NSMakeRange(0,obj1.length);
        return [obj1 compare:obj2 options:comparisonOptions range:range];
    };
    NSArray *ASCIIStringArray = [stringArray sortedArrayUsingComparator:sort];
    //第三步,拼接字符串
    NSMutableString *sortedString = [[NSMutableString alloc] initWithString:@""];
    [ASCIIStringArray enumerateObjectsUsingBlock:^(NSString *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx == ASCIIStringArray.count - 1) {
            [sortedString appendString:obj];
        } else {
            [sortedString appendString:[NSString stringWithFormat:@"%@&", obj]];
        }
    }];
    //第四步,拼接上特殊的key,key=1234567890
    [sortedString appendString:[NSString stringWithFormat:@"&key=%@", SpecialKeyValue]];
    //第五步,MD5加密
    NSString *md5String = [sortedString yixiang_md5hashString];
    //第六步,全部转大写
    return [md5String uppercaseString];
}

#pragma mark - 处理请求错误码

- (NSError *)handleErrorCode:(NSError *)defaultError
{
    NSError *underlyingError = defaultError.userInfo[NSUnderlyingErrorKey];
    
    NSInteger errorCode = defaultError.code;
    if (underlyingError) {
        errorCode = underlyingError.code;
    }
    NSError *error = nil;
    switch (errorCode) {
        case NSURLErrorTimedOut://超时
            error = [NSError errorWithDomain:@"请求超时,请稍后重试"
                                        code:NSURLErrorTimedOut
                                    userInfo:defaultError.userInfo];
            break;
        case 3840://解析失败
            error = [NSError errorWithDomain:@"json格式解析出错" code:3840 userInfo:defaultError.userInfo];
            break;
        case NSURLErrorNotConnectedToInternet://无网络连接
            error = [NSError errorWithDomain:@"暂无网络链接，请检查网络后再重试"
                                        code:NSURLErrorNotConnectedToInternet
                                    userInfo:defaultError.userInfo];
            break;
        case NSURLErrorHTTPTooManyRedirects://重定向
            error = [NSError errorWithDomain:@"请求被重定向"
                                        code:NSURLErrorHTTPTooManyRedirects
                                    userInfo:defaultError.userInfo];
            break;
        case NSURLErrorBadServerResponse:
            error = [NSError errorWithDomain:@"服务器无响应"
                                        code:NSURLErrorBadServerResponse
                                    userInfo:defaultError.userInfo];
            break;
        case NSURLErrorCancelled:
            error = [NSError errorWithDomain:@"请求被取消"
                                        code:NSURLErrorCancelled
                                    userInfo:defaultError.userInfo];
            break;
        default:
            error = defaultError;
            break;
    }
    return error;
}


#pragma mark -取消某一个请求

- (void)cancelRequestApi:(YXRequestApi *)requestApi
{
    NSEnumerator *keyEnumerator = [self.requestMap keyEnumerator];
    NSString *key;
    while (key = [keyEnumerator nextObject]) {
        if ([key hasPrefix:requestApi.uniqueIdentify]) {
            [requestApi.requestTask cancel];
            break;
        }
    }
    Lock();
    [self.requestMap removeObjectForKey:key];
    Unlock();
}


- (void)cancelRequestApis:(NSArray<YXRequestApi *> *)apis
{
    for (YXRequestApi *api in apis) {
        NSEnumerator *keyEnumerator = [self.requestMap keyEnumerator];
        NSString *key;
        while (key = [keyEnumerator nextObject]) {
            if ([key hasPrefix:api.uniqueIdentify]) {
                [api.requestTask cancel];
                break;
            }
        }
        Lock();
        [self.requestMap removeObjectForKey:key];
        Unlock();
    }
}

- (void)cancelAllRequests
{
    NSEnumerator *objectEnumerator = [self.requestMap objectEnumerator];
    YXRequestApi *api;
    while (api = [objectEnumerator nextObject]) {
        [api.requestTask cancel];
    }
    Lock();
    self.requestCount = 0;
    [self.requestMap removeAllObjects];
    Unlock();
}



@end
