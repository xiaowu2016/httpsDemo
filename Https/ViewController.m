//
//  ViewController.m
//  Https
//
//  Created by zhangchao on 16/12/16.
//  Copyright © 2016年 zhangchao. All rights reserved.
//

#import "ViewController.h"
#import "HttpsHandler.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   [[HttpsHandler shared] POST:@"https://www.miracleqiji.com:443/miracle/changelogin.action" parameters:nil progress:^(NSProgress * _Nonnull uploadProgress) {
       NSLog(@"123");
   } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
       //走到这里就说明https双向认证成功了，返回结果不对说明向服务器请求的参数不是它想要的，不必纠结
       NSLog(@"成功:%@",responseObject);
   } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
       NSLog(@"失败:%@",error);
   }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
