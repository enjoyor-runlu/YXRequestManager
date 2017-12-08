//
//  YXBaseRequestApi.m
//  Pods
//
//  Created by jiaguoshang on 2016/10/31.
//
//

#import "YXBaseRequestApi.h"

@implementation YXBaseRequestApi

- (YXRequestSerializerType)requestSerializerType {
    return YXRequestSerializerTypeHTTP;
}
    
- (YXResponseSerializerType)responseSerializerType {
    return YXResponseSerializerTypeJSON;
}

@end
