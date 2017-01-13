# RITLObjc_runtimeDemo
一个MVVM架构用于解决runtime使用msgSend方法创建对象不能释放问题的小demo

好几个月没有发表点东西了，但也一直关注简书上优秀的博文学习，漫长的这段时间一直在不断的重构公司项目，为了使代码尽可能的优雅，除了不断地进行组件化重写之外，很多地方也逐渐的开始使用runtime进行编程。说实话，这样编程比较爽，却会出现一系列之前没有考虑过的问题，比如这篇文章记录的使用objc_msgSend()创建对象不能释放的问题。

先列出常用的初始化方法，这里就以最常用的ViewController为例。

#普遍的初始化
```
UIViewController * viewController = [[UIViewController alloc]init];

//或者

UIViewController * viewController = [UIViewController new];
```

楼主比较喜欢后面一种，因为毕竟能少打几个字母嘛，当然这不是重点。

#runtime的初始化
```
Class class = objc_getClass("UIViewController");

id viewController = (id(*)(id,SEL)objc_msgSend)(class,NSSelectorFromString(@"new"));
```
两者对比一下，貌似使用runtime要更加的麻烦，因为它甚至需要两行比较长代码来完成一个控制器的初始化，至于为什么选择runtime后面会说一下个人的看法，如果非要说装X - - (我也说不了什么其实😀)。

#问题
先来说明一下问题，利用Demo中的Let's push oneSelf来不断的push与pop当前控制器类的实例对象, 查看当前实例对象的个数，这个很简单，在类中定义一个全局变量来记录当前类对象实力对象的个数
```
static NSUInteger classValue = 0;
```
在`RITLRootViewController`控制器的`ViewDidLoad`以及`deallco`方法中分别对数字进行`++`或者`--`操作，并打印当前类的个数:

##使用普通的初始化方法以及打印结果:
```
RITLRootViewController * viewController = [RITLRootViewController new];
[self.navigationController pushViewController:viewController animated:true];

//result:
现在存在1个RITLRootViewController
现在存在2个RITLRootViewController
现在存在1个RITLRootViewController
现在存在2个RITLRootViewController
现在存在1个RITLRootViewController
现在存在2个RITLRootViewController
现在存在1个RITLRootViewController
```

可以看出，数字在viewDidLoad中进行了累加，在dealloc中进行了累减，这样是平衡的。

##使用runtime方法初始化打出结果:
```
Class class = objc_getClass("RITLRootViewController");
id viewController = ((id(*)(id,SEL))objc_msgSend)(class,NSSelectorFromString(@"new"));
[self.navigationController pushViewController:viewController animated:true];

//result:
现在存在1个RITLRootViewController
现在存在2个RITLRootViewController
现在存在3个RITLRootViewController
现在存在4个RITLRootViewController
现在存在5个RITLRootViewController
```

对象的个数是不断上升的，间接地告诉我们实例对象是没有释放掉的。

#原因

用群里一个朋友的话说:"C语言的方式还要用C语言来解决"。

runtime大家都知道它就是C/C++ ， 再直接一点就是直接使用runtime执行初始化方法创建的对象的时候是不在ARC控制之下的，也就是说在对应创建的那个文件里销毁的时候需要我们自行release。

楼主分析的小过程，很简单:
-  初始化完毕之后，当前对象的retainCount = 1。
-  导航控制器push的时候，ARC下的编译器帮我们进行了一次retain，当前对象的retainCount = 2。
-  导航控制器pop的时候，ARC下的编译器又帮我们进行了一次release，当前对象的retainCount = 1。
-   此时当前控制器的retainCount恒为非0正整数，无法释放。

#解决
上面的步骤看完之后，基本就能进行解决位置的定位了，那么我们在导航控制器retain之后进行自身的release即可，ARC下由于不能使用release方法，解决办法如下:
```
// 由于导航控制器持有viewController，所以viewController不会释放
[self.navigationController pushViewController:viewController animated:true];
    
//release，这个时候viewController的retainCount = 1，也就是在导航控制器释放的时候viewController也就会跟着进行释放
((void(*)(id,SEL))objc_msgSend)(viewController,NSSelectorFromString(@"release"));
```

#楼主的使用场景

说明一下楼主使用runtime的场景之一，既然问题那么多，并且代码这么麻烦，为什么还要用它呢，难道就是为了装X吗，实际上并不是这样的。

比如一个viewController需要跳转不同的控制器，由于楼主比较喜欢使用MVVM模型，每次处理完毕数据就要进行一个回调，跳入不同的控制器，如果有跳入100个不同的控制器的可能，那我岂不是要写N个回调，但是如果是使用runtime，我貌似只使用一个或者根据情况使用几个回调，返回控制器的类名以及相应的参数就好了吧。

下面是一个逻辑十分简单的Demo，有三个不同的按钮，分别表示跳入三个不同的控制器，每点击一个按钮都会触发ViewModel的方法(MVVM模型的数据是在ViewModel中的呢，ViewController只是作为一个View层，不会有任何的逻辑)，由viewModel通过某些方法进行数据处理完毕后进行界面的回调。

![简单的效果.git](http://upload-images.jianshu.io/upload_images/1622004-f93bf53a61913982.gif?imageMogr2/auto-orient/strip)

控制器的viewModel很简单，如下:
```
RITLRootViewModel.h

NS_ASSUME_NONNULL_BEGIN

/// RITLRootViewController的viewModel对象
@interface RITLRootViewModel : NSObject

///buttonDidTapWithTag:触发的block
@property (nonatomic, copy, nullable)void(^ButtonDidTapBlock)(NSString * controllerName);

/**
 根据不同的tag进行响应不同的事件，触发ButtonDidTapBlock

 @param tag button的tag值
 */
- (void)buttonDidTapWithTag:(NSUInteger)tag;

@end

NS_ASSUME_NONNULL_END
```
```
RITLRootViewModel.m

@interface RITLRootViewModel ()

@property (nonatomic, copy)NSArray < NSString * > * controllerNames;

@end

@implementation RITLRootViewModel

-(instancetype)init
{
    if (self = [super init])
    {
        _controllerNames = @[@"RITLRootViewController",@"RITLViewControllerTwo",@"RITLViewControllerThree"];
    }
    
    return self;
}


-(void)buttonDidTapWithTag:(NSUInteger)tag
{
    NSUInteger realTag = tag - 10001;
    
    if (self.ButtonDidTapBlock)
    {
        self.ButtonDidTapBlock(self.controllerNames[realTag]);
    }
}

@end
```

只需要在button点击的时候调用viewModel的buttonDidTapWithTag:方法即可:
```
- (IBAction)pushBtnDidTap:(id)sender
{
      UIButton * button = (UIButton *)sender;
      [self.viewModel buttonDidTapWithTag:button.tag];
 }
```

在viewDidLoad绑定好viewModel即可
```
- (void)bindViewModel
{
    __weak typeof(self) weakSelf = self;
    
    self.viewModel.ButtonDidTapBlock = ^(NSString * controllerName){
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        Class class = objc_getClass(controllerName.UTF8String);
        
        id viewController = ((id(*)(id,SEL))objc_msgSend)(class,NSSelectorFromString(@"new"));

        [strongSelf ritl_pushViewController:viewController];
    };
}

// 导航控制器获得控制权后进行release即可
- (void)ritl_pushViewController:(__kindof UIViewController *)viewController
{
    [self pushViewController:viewController];
    
    //release
    ((void(*)(id,SEL))objc_msgSend)(viewController,NSSelectorFromString(@"release"));
}
```


