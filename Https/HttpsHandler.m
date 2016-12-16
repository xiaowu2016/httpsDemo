//
//  HttpsHandler.m
//  Https
//
//  Created by zhangchao on 16/12/16.
//  Copyright © 2016年 zhangchao. All rights reserved.
//

#import "HttpsHandler.h"
#import <AFNetworking.h>

@implementation HttpsHandler
static HttpsHandler *managers;
+ (HttpsHandler *)shared {
    if(managers == nil) {
        managers = [[HttpsHandler alloc] init];
    }
    return managers;
}

- (void)POST:(NSString *)urlString
  parameters:(id)parameters
    progress:(nullable void (^)(NSProgress *uploadProgress))uploadProgress
     success:(nullable void (^)(NSURLSessionDataTask *task, id _Nullable responseObject))success
     failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError *error))failure {
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    //    设置超时时间
    [manager.requestSerializer willChangeValueForKey:@"timeoutInterval"];
    manager.requestSerializer.timeoutInterval = 30.f;
    [manager.requestSerializer didChangeValueForKey:@"timeoutInterval"];
    [manager.requestSerializer setValue:@"Content-Type" forHTTPHeaderField:@"application/json; charset=utf-8"];
    [manager setSecurityPolicy:[self customSecurityPolicy]];
    [self checkCredential:manager];
    [manager POST:urlString parameters:parameters progress:uploadProgress success:success failure:failure];
}


- (AFSecurityPolicy*)customSecurityPolicy {
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    //获取证书路径
    NSString * cerPath = [[NSBundle mainBundle] pathForResource:@"server" ofType:@"cer"];
    NSData *certData = [NSData dataWithContentsOfFile:cerPath];
    NSSet   *dataSet = [NSSet setWithArray:@[certData]];
    [securityPolicy setAllowInvalidCertificates:YES];//是否允许使用自签名证书
    [securityPolicy setPinnedCertificates:dataSet];//设置去匹配服务端证书验证的证书
    [securityPolicy setValidatesDomainName:NO];//是否需要验证域名，默认YES
    
    return securityPolicy;
}

//校验证书
- (void)checkCredential:(AFURLSessionManager *)manager
{
    [manager setSessionDidBecomeInvalidBlock:^(NSURLSession * _Nonnull session, NSError * _Nonnull error) {
    }];
    __weak typeof(manager)weakManager = manager;
    [manager setSessionDidReceiveAuthenticationChallengeBlock:^NSURLSessionAuthChallengeDisposition(NSURLSession*session, NSURLAuthenticationChallenge *challenge, NSURLCredential *__autoreleasing*_credential) {
        NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
        __autoreleasing NSURLCredential *credential =nil;
        NSLog(@"authenticationMethod=%@",challenge.protectionSpace.authenticationMethod);
        //判断服务器要求客户端的接收认证挑战方式，如果是NSURLAuthenticationMethodServerTrust则表示去检验服务端证书是否合法，NSURLAuthenticationMethodClientCertificate则表示需要将客户端证书发送到服务端进行检验
        if([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
            // 基于客户端的安全策略来决定是否信任该服务器，不信任的话，也就没必要响应挑战
            if([weakManager.securityPolicy evaluateServerTrust:challenge.protectionSpace.serverTrust forDomain:challenge.protectionSpace.host]) {
                // 创建挑战证书（注：挑战方式为UseCredential和PerformDefaultHandling都需要新建挑战证书）
                credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
                // 确定挑战的方式
                if (credential) {
                    //证书挑战  设计policy,none，则跑到这里
                    disposition = NSURLSessionAuthChallengeUseCredential;
                } else {
                    disposition = NSURLSessionAuthChallengePerformDefaultHandling;
                }
            } else {
                disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
            }
        } else { //只有双向认证才会走这里
            // client authentication
            SecIdentityRef identity = NULL;
            SecTrustRef trust = NULL;
            NSString *p12 = [[NSBundle mainBundle] pathForResource:@"client"ofType:@"p12"];
            NSFileManager *fileManager =[NSFileManager defaultManager];
            
            if(![fileManager fileExistsAtPath:p12])
            {
                NSLog(@"client.p12:not exist");
            }
            else
            {
                NSData *PKCS12Data = [NSData dataWithContentsOfFile:p12];
                
                if ([self extractIdentity:&identity andTrust:&trust fromPKCS12Data:PKCS12Data])
                {
                    SecCertificateRef certificate = NULL;
                    SecIdentityCopyCertificate(identity, &certificate);
                    const void*certs[] = {certificate};
                    CFArrayRef certArray =CFArrayCreate(kCFAllocatorDefault, certs,1,NULL);
                    credential =[NSURLCredential credentialWithIdentity:identity certificates:(__bridge  NSArray*)certArray persistence:NSURLCredentialPersistencePermanent];
                    disposition =NSURLSessionAuthChallengeUseCredential;
                }
            }
        }
        *_credential = credential;
        return disposition;
    }];
}

//读取p12文件中的密码
- (BOOL)extractIdentity:(SecIdentityRef*)outIdentity andTrust:(SecTrustRef *)outTrust fromPKCS12Data:(NSData *)inPKCS12Data {
    OSStatus securityError = errSecSuccess;
    //client certificate password
    NSDictionary*optionsDictionary = [NSDictionary dictionaryWithObject:@"csykum812"
                                                                 forKey:(__bridge id)kSecImportExportPassphrase];
    
    CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
    securityError = SecPKCS12Import((__bridge CFDataRef)inPKCS12Data,(__bridge CFDictionaryRef)optionsDictionary,&items);
    
    if(securityError == 0) {
        CFDictionaryRef myIdentityAndTrust =CFArrayGetValueAtIndex(items,0);
        const void*tempIdentity =NULL;
        tempIdentity= CFDictionaryGetValue (myIdentityAndTrust,kSecImportItemIdentity);
        *outIdentity = (SecIdentityRef)tempIdentity;
        const void*tempTrust =NULL;
        tempTrust = CFDictionaryGetValue(myIdentityAndTrust,kSecImportItemTrust);
        *outTrust = (SecTrustRef)tempTrust;
    } else {
        NSLog(@"Failedwith error code %d",(int)securityError);
        return NO;
    }
    return YES;
}
@end
