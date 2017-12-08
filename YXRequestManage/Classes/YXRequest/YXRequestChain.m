//
//  YXRequestChain.m
//  Pods
//
//  Created by luminary on 2017/5/3.
//
//

#import "YXRequestChain.h"
#import "YXRequestClient.h"
#import <UXFDCategories/UXFDCategory.h>

#define MaxRequestIndex 666666

@interface YXRequestChain ()

@property (nonatomic, strong) NSMutableArray     *requestArray;

@property (nonatomic, strong) NSMutableArray     *callbackArray;

@property (nonatomic, copy)   Callback           defaultCallback;

@property (nonatomic, assign) NSUInteger         requestIndex;

@end

@implementation YXRequestChain

- (instancetype)init
{
    self = [super init];
    if (self) {
        _requestIndex = 0;
        _defaultCallback = ^(NSDictionary *result, NSError *error){
            //empty
        };
    }
    return self;
}

- (NSMutableArray *)requestArray
{
    if (!_requestArray) {
        _requestArray = [NSMutableArray array];
    }
    return _requestArray;
}

- (NSMutableArray *)callbackArray
{
    if (!_callbackArray) {
        _callbackArray = [NSMutableArray array];
    }
    return _callbackArray;
}

- (void)addChainRequest:(YXRequestApi *)requestApi
{
    [self addChainRequest:requestApi callback:nil];
}

- (void)addChainRequest:(YXRequestApi *)requestApi callback:(Callback)callback
{
    if (!requestApi) {
        return;
    }
    [self.requestArray addSafeObject:requestApi];
    if (callback) {
        [self.callbackArray addSafeObject:callback];
    } else {
        [self.callbackArray addSafeObject:self.defaultCallback];
    }
}

- (void)start
{
    if (self.requestIndex >= self.requestArray.count) {
        [self clearSaveData];
        return;
    }
    YXRequestApi *requestApi = [self.requestArray objectAtSafeIndex:self.requestIndex];
    Callback callback = [self.callbackArray objectAtSafeIndex:self.requestIndex];
    [[YXRequestClient sharedClient] loadDataWithApi:requestApi successBlock:^(NSDictionary * _Nullable result) {
        callback(result, nil);
        self.requestIndex++;
        if (self.requestIndex >= self.requestArray.count) {
            if (self.chainFinishedCallback) {
                self.chainFinishedCallback(requestApi, result);
            }
            [self clearSaveData];
        } else {
            [self start];
        }
    } failureBlock:^(NSError * _Nullable error) {
        if (self.chainFailureCallback) {
            self.chainFailureCallback(requestApi, error);
        }
        [self clearSaveData];
    }];
}

- (void)stop
{
    //表示当前有正在请求的接口
    if (self.requestIndex >= self.requestArray.count) {
        return;
    }
    YXRequestApi *requestApi = [self.requestArray objectAtSafeIndex:self.requestIndex];
    self.requestIndex = MaxRequestIndex;
    [[YXRequestClient sharedClient] cancelRequestApi:requestApi];
    [self clearSaveData];
}

- (void)clearSaveData
{
    [self.requestArray removeAllObjects];
    [self.callbackArray removeAllObjects];
}

@end
