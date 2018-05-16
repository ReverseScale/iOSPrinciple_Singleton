//
//  ViewController.m
//  iOSPrinciple_Singleton
//
//  Created by WhatsXie on 2018/5/16.
//  Copyright © 2018年 WhatsXie. All rights reserved.
//

#import "ViewController.h"

#import "SingletonManager.h" //常规方法

@interface ViewController ()

@end

@implementation ViewController

SingletonM(ViewController)

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 测试创建指针地址
//    [self singletonTest];
    
    // 调用单例方法
//    [SManager TestPrint];
    
    // 调用宏定义单例
    NSLog(@"地址打印：\n%@\n%@\n%@\n%@", [ViewController sharedViewController], [ViewController sharedViewController], [[ViewController alloc] init], [[ViewController alloc] init]);
}

- (void)singletonTest {
    SingletonManager *defaultManagerSingleton = [SingletonManager shareManager];
    NSLog(@"defaultManagerSingleton:\n%@",defaultManagerSingleton);
    
    SingletonManager *allocSingleton = [[SingletonManager alloc] init];
    NSLog(@"allocSingleton:\n%@",allocSingleton);
    
    SingletonManager *copySingleton = [allocSingleton copy];
    NSLog(@"copySingleton:\n%@",copySingleton);
    
    SingletonManager *mutebleCopySingleton = [allocSingleton mutableCopy];
    NSLog(@"mutebleCopySingleton:\n%@",mutebleCopySingleton);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
