//
//  HttpsHandler.h
//  Https
//
//  Created by zhangchao on 16/12/16.
//  Copyright © 2016年 zhangchao. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HttpsHandler : NSObject
+ (HttpsHandler *)shared;

- (void)POST:(NSString *)urlString
  parameters:(nullable id)parameters
    progress:(nullable void (^)(NSProgress *uploadProgress))uploadProgress
     success:(nullable void (^)(NSURLSessionDataTask *task, id _Nullable responseObject))success
     failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError *error))failure;
@end

NS_ASSUME_NONNULL_END
