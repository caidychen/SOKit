//
//  SOHTTPRequestModel.m
//  SOKit
//
//  Created by soso on 15/6/16.
//  Copyright (c) 2015年 com.. All rights reserved.
//

#import "SOHTTPRequestModel.h"
#import "AppDelegate.h"

NSString * const SOHTTPRequestMethodGET         = @"GET";
NSString * const SOHTTPRequestMethodPOST        = @"POST";


@implementation SOHTTPRequestModel
@synthesize baseURLString = _baseURLString;
@synthesize parameters = _parameters;
@synthesize requestOperationManager = _requestOperationManager;

- (void)dealloc {
    SORELEASE(_baseURLString);
    SORELEASE(_parameters);
    SORELEASE(_requestOperationManager);
    SOSUPERDEALLOC();
}

- (instancetype)init {
    self = [super init];
    if(self) {
        _baseURLString = @"";
        self.method = SOHTTPRequestMethodPOST;
        _parameters = [[NSMutableDictionary alloc] init];
        [self requestOperationManager];
    }
    return (self);
}

#pragma mark - getter
- (AFHTTPRequestOperationManager *)requestOperationManager {
    if(!_requestOperationManager) {
        _requestOperationManager = [[AFHTTPRequestOperationManager alloc] init];
        _requestOperationManager.requestSerializer = [AFHTTPRequestSerializer serializer];
        [_requestOperationManager.requestSerializer willChangeValueForKey:@"timeoutInterval"];
        _requestOperationManager.requestSerializer.timeoutInterval = 10.f;
        [_requestOperationManager.requestSerializer didChangeValueForKey:@"timeoutInterval"];
        _requestOperationManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    }
    return (_requestOperationManager);
}
#pragma mark -

#pragma mark - actions
- (void)appendOtherParameters {
    
}

- (NSString *)showFullRequestURL {
    NSMutableString *urlString = [NSMutableString stringWithString:self.baseURLString];
    if(urlString && urlString.length > 0 && self.parameters && self.parameters.count > 0) {
        [urlString appendString:@"?"];
        [self.parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [urlString appendFormat:@"%@=%@&", key, obj];
        }];
        NSString *ps = [urlString substringWithRange:NSMakeRange(0, MAX(0, urlString.length - 1))];
        //NSLog(@">>>>>>param:%@", self.parameters);
        NSLog(@">>>>>>URL:%@", ps);
        return (ps);
    }
    return (nil);
}
#pragma mark -

#pragma mark - <SOBaseModelCacheProtocol>
- (NSString *)cacheKey {
    return ([NSString stringWithFormat:@"%@-%@", self.baseURLString, self.parameters]);
}
#pragma mark -

#pragma mark - <SOBaseModelProtocol>
- (void)cancelAllRequest {
    [self.requestOperationManager.operationQueue cancelAllOperations];
    [super cancelAllRequest];
}

- (AFHTTPRequestOperation *)startLoad {
    [self appendOtherParameters];
    __SOWEAK typeof(self) weak_self = self;
    if(self.method && [self.method isEqualToString:SOHTTPRequestMethodGET]) {
        AFHTTPRequestOperation *operation = [self.requestOperationManager GET:self.baseURLString parameters:self.parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            [weak_self request:operation didReceived:responseObject];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [weak_self request:operation didFailed:error];
        }];
        return (operation);
    }
    AFHTTPRequestOperation *operation = [self.requestOperationManager POST:self.baseURLString parameters:self.parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [weak_self request:operation didReceived:responseObject];
        
//        //判断是登录失效,授权失败，重新登录
//        if (responseObject && [[responseObject objectForKey:@"status"] integerValue] == -2) {
//            AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
//            if (delegate && [delegate respondsToSelector:@selector(showLogin)]) {
//                [delegate showLogin];
//            }
//        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [weak_self request:operation didFailed:error];
    }];
    return (operation);
}

- (void)request:(AFHTTPRequestOperation *)request didReceived:(id)responseObject {
    if(self.delegate && [self.delegate respondsToSelector:@selector(model:didReceivedData:userInfo:)]) {
        [self.delegate model:self didReceivedData:responseObject userInfo:nil];
    }
}

- (void)request:(AFHTTPRequestOperation *)request didFailed:(NSError *)error {
    if(self.delegate && [self.delegate respondsToSelector:@selector(model:didFailedInfo:error:)]) {
        [self.delegate model:self didFailedInfo:nil error:error];
    }
}
#pragma mark -

@end
