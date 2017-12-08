//
//  YXBaseRequestApi.h
//  Pods
//
//  Created by luminary on 2016/10/31.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, RequestMethodType){
    YX_Request_GET,
    YX_Request_POST,
    YX_Request_PUT,
    YX_Request_DELETE,
    YX_Request_HEAD,
    YX_Request_PATCH
};

typedef NS_ENUM(NSInteger, YXRequestSerializerType) {
    YXRequestSerializerTypeHTTP,
    YXRequestSerializerTypeJSON
};

typedef NS_ENUM(NSInteger, YXResponseSerializerType) {
    YXResponseSerializerTypeHTTP,
    YXResponseSerializerTypeJSON
};

@interface YXBaseRequestApi : NSObject

/**
 唯一标识符
 */
@property (nonatomic, copy)              NSString *uniqueIdentify;

/**
 sessionTask
 */
@property (nonatomic, strong, readwrite) NSURLSessionTask *requestTask;

- (YXRequestSerializerType)requestSerializerType;
    
- (YXResponseSerializerType)responseSerializerType;
    
@end
