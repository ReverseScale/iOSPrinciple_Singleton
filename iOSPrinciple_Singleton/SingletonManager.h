//
//  Singleton.h
//  iOSPrinciple_Singleton
//
//  Created by WhatsXie on 2018/5/16.
//  Copyright © 2018年 WhatsXie. All rights reserved.
//

#import <Foundation/Foundation.h>

/// 单例宏
#define SManager [SingletonManager shareManager]

@interface SingletonManager : NSObject

@property(nonatomic,strong) NSString *name;

+ (SingletonManager*)shareManager;

- (void)TestPrint;

@end
