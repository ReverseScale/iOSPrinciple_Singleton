# iOSPrinciple_Singleton
Principle Singleton

### 引文

《Design Patterns: Elements of Reusable Object-Oriented Software》（即后述《设计模式》一书）是由 Erich Gamma、Richard Helm、Ralph Johnson 和 John Vlissides 合著（Addison-Wesley，1995）。这几位作者常被称为”四人组（Gang of Four）”。

开篇引用 GoF 的示例帮助理解创建型设计模式——单例

> SINGLETON—俺有6个漂亮的老婆，她们的老公都是我，我就是我们家里的老公Singleton，她们只要说道“老公”，都是指的同一个人，那就是我。(刚才做了个梦啦，哪有这么好的事)

单例模式：单例模式确保某一个类只有一个实例，而且自行实例化并向整个系统提供这个实例单例模式。单例模式只应在有真正的“单一实例”的需求时才可使用。

### 单例的创建

#### 1.单线程单例
我们知道对于单例类，我们必须留出一个接口来返回生成的单例，由于一个类中只能有一个实例，所以我们在第一次访问这个实例的时候创建，之后访问直接取已经创建好的实例

```objc
@implementationSingleton
+ (instancetype)shareInstance{
    staticSingleton* single;
    if(!single) {      
        single = [[Singleton alloc] init];   
    }
    return single;
}
@end
```

ps:严格意义上来说，我们还需要将alloc方法封住，因为严格的单例是不允许再创建其他实例的，而alloc方法可以在外部任意生成实例。但是考虑到alloc属于NSObject，iOS中无法将alloc变成私有方法，最多只能覆盖alloc让其返回空，不过这样做也可能会让使用接口的人误解，造成其他问题。所以我们一般情况下对alloc不做特殊处理。系统的单例也未对alloc做任何处理

#### 2.@synchronized单例

对于一个实例，我们一般并不能保证他一定会在单线程模式下使用，所以我们得适配多线程情况。在多线程情况下，上面的单例创建方式可能会出现问题。如果两个线程同时调用shareInstance,可能会创建出2个single来。所以对于多线程情况下，我们需要使用@synchronized来加锁。

```objc
@implementationSingleton
+ (instancetype)shareInstance{
    staticSingleton* single;
    @synchronized(self) {
        if(!single) {           
            single = [[Singleton alloc] init];       
        }    
    }
    return single;
}
@end
```

这样的话，当多个线程同时调用shareInstance时，由于@synchronized已经加锁，所以只能有一个线程进入创建single。这样就解决了多线程下调用单例的问题

#### 3.dispatch_once单例

使用@synchronized虽然解决了多线程的问题，但是并不完美。因为只有在single未创建时，我们加锁才是有必要的。如果single已经创建.这时候锁不仅没有好处，而且还会影响到程序执行的性能（多个线程执行@synchronized中的代码时，只有一个线程执行，其他线程需要等待）。那么有没有方法既可以解决问题，又不影响性能呢？
这个方法就是GCD中的dispatch_once

```objc
+ (SingletonManager*)shareManager {
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        if(defaultManager == nil) {
            NSLog(@"dispatch_once Token: %ld",token);
            defaultManager = [[self alloc] init];
        }
    });
    NSLog(@"Token: %ld",token);
    NSLog(@"DefaultManager: %@",defaultManager);
    return defaultManager;
}
```
打印结果
![](http://og1yl0w9z.bkt.clouddn.com/18-5-16/36369479.jpg)

#### dispatch_once 为什么能做到既解决同步多线程问题又不影响性能呢？

下面我们来看看dispatch_once的原理：

dispatch_once主要是根据onceToken的值来决定怎么去执行代码。

* 当onceToken= 0时，线程执行dispatch_once的block中代码
* 当onceToken= -1时，线程跳过dispatch_once的block中代码不执行
* 当onceToken为其他值时，线程被线程被阻塞，等待onceToken值改变

当线程首先调用shareInstance，某一线程要执行block中的代码时，首先需要改变onceToken的值，再去执行block中的代码。这里onceToken的值变为了768。

这样当其他线程再获取onceToken的值时，值已经变为768。其他线程被阻塞。

当block线程执行完block之后。onceToken变为-1。其他线程不再阻塞，跳过block。

下次再调用shareInstance时，block已经为-1。直接跳过block。

这样dispatch_once在首次调用时同步阻塞线程，生成单例之后，不再阻塞线程。

> 遇到问题：线程1和线程2，都在调用shareInstance方法来创建单例，那么线程1运行到if (_instance == nil)发现_instance = nil,那么就会初始化一个_instance，假设此时线程2也运行到if的判断处了，此时线程1还没有创建完成实例_instance，所以此时_instance = nil还是成立的，那么线程2又会创建一个_instace。

虽然使用互斥锁也可以解决多线程同时创建的问题，但是dispatch_once更为高效安全是解决这类问题的最优方案。

#### 宏方法创建单例

Singleton.h 中进行宏定义

```objc
// Singleton.h
#import <Foundation/Foundation.h>
#define SingletonH(name) + (instancetype)shared##name;
#define SingletonM(name) \
static id _instance; \
\
+ (instancetype)allocWithZone:(struct _NSZone *)zone \
{ \
static dispatch_once_t onceToken; \
dispatch_once(&onceToken, ^{ \
_instance = [super allocWithZone:zone]; \
}); \
return _instance; \
} \
\
+ (instancetype)shared##name \
{ \
static dispatch_once_t onceToken; \
dispatch_once(&onceToken, ^{ \
_instance = [[self alloc] init]; \
}); \
return _instance; \
} \
\
- (id)copyWithZone:(NSZone *)zone \
{ \
return _instance; \
}\
\
- (id)mutableCopyWithZone:(NSZone *)zone { \
return _instance; \
}
@interface Singleton : NSObject
@end
```

使用方法 ViewController.h 中

```objc
// ViewController.h
#import <UIKit/UIKit.h>
#import "Singleton.h" //宏方法
@interface ViewController : UIViewController
SingletonH(viewController)
@end
```

ViewController.m 中

```objc
SingletonM(ViewController)
- (void)viewDidLoad {
    [super viewDidLoad];
    // 调用宏定义单例
    NSLog(@"地址打印：\n%@\n%@\n%@\n%@", [ViewController sharedViewController], [ViewController sharedViewController], [[ViewController alloc] init], [[ViewController alloc] init]);
}
```

打印结果

![](http://og1yl0w9z.bkt.clouddn.com/18-5-16/76224480.jpg)

打印结果可见地址相同

### 单例的用途

1）单例模式用来限制一个类只能创建一个对象，那么此对象的属性可以存储全局共享的数据。所有类都可以访问、设置此单例对象中的属性数据；

2）如果一个类创建的时候非常的耗费资源或影响性能，那么此对象可以设置为单例以节约资源和提高性能。

单例类保证了应用程序的生命周期中有且仅有一个该类的实例对象，而且易于外界访问。

#### iOS 系统中使用的单例类

* UIApplication
* NSNotificationCenter
* NSFileManager
* NSUserDefaults
* NSURLCache
* NSHTTPCookieStorage

### dispatch_once 原理剖析

在IOS开发中，为保证单例在整个程序运行中只被初始化一次，单线程的时候，通过静态变量可以实现；但是多线程的出现，使得在如上面的极端条件下，单例也可能返回了不同的对象。如在单例初始化完成前，多个进程同时访问单例，那么这些进程可能都获得了不同的单例对象。

多线程保护下的单例初始化代码

```objc
+ (instancetype)defaultObject{
    static SharedObject *sharedObject = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedObject = [[SharedObject alloc] init];
    });
    return sharedObject;
}
```
![](http://og1yl0w9z.bkt.clouddn.com/18-5-16/61461840.jpg)

点击查看 dispatch_once_t 发现其是 typedef long 类型

> 静态变量在程序运行期间只被初始化一次，然后其在下一次被访问时，其值都是上次的值，其在除了这个初始化方法以外的任何地方都不能直接修改这两个变量的值。这是单例只被初始化一次的前提。

![](http://og1yl0w9z.bkt.clouddn.com/18-5-16/53088695.jpg)

点击查看 dispatch_once 发现内部通过宏把 _dispatch_once 转化成 dispatch_once

![](http://og1yl0w9z.bkt.clouddn.com/18-5-16/1884809.jpg)

查找到 _dispatch_once 函数，我们发现 DISPATCH_EXPECT 方法

> ~0l 是长整型0按位取反，就是长整型的-1

![](http://og1yl0w9z.bkt.clouddn.com/18-5-16/11949737.jpg)

__GNUC__ 只代表gcc的主版本号，我们忽略它，剩下就是 DISPATCH_EXPECT(x, v) 了，DISPATCH_EXPECT(*predicate, ~0l)  就是说，*predicate 很可能是 ~0l ，而当  DISPATCH_EXPECT(*predicate, ~0l)  不是 ~0! 时 才调用真正的 dispatch_once 函数。

第一次运行，predicate的值是默认值0，按照逻辑，如果有两个进程同时运行到 dispatch_once 方法时，这个两个进程获取到的 predicate 值都是0，那么最终两个进程都会调用 最原始那个 dispatch_once 函数。

由此我再把上面的规则贴一遍，可以自己调试看看

* 当onceToken= 0时，线程执行dispatch_once的block中代码
* 当onceToken= -1时，线程跳过dispatch_once的block中代码不执行
* 当onceToken为其他值时，线程被线程被阻塞，等待onceToken值改变

> 以上原理解析文章来源：http://www.cocoachina.com/ios/20160907/17497.html，https://www.jianshu.com/p/160d77888443，https://blog.csdn.net/mlibai/article/details/46945331
