//
//  ViewController.m
//  RITLObjc_runtimeDemo
//
//  Created by YueWen on 2017/1/13.
//  Copyright © 2017年 YueWen. All rights reserved.
//

#import "RITLRootViewController.h"
#import "RITLRootViewModel.h"

@import ObjectiveC;

#define RITL_Objc_msgSend

static NSUInteger classValue = 0;

@interface RITLRootViewController ()

@property (nonatomic, strong) RITLRootViewModel * viewModel;

@end

@implementation RITLRootViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    classValue ++;
    
    if (!self.backColor)
    {
        self.backColor = [UIColor whiteColor];
    }
    
    self.view.backgroundColor = self.backColor;
    self.title = @"RITLRootViewController";
    
    printf("现在存在%ld个RITLRootViewController\n",(long)classValue);
    
    [self bindViewModel];

}

-(void)dealloc
{
    classValue --;
    printf("现在存在%ld个RITLRootViewController\n",(long)classValue);
}


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






- (IBAction)pushBtnDidTap:(id)sender
{
    
    UIButton * button = (UIButton *)sender;
    
    [self.viewModel buttonDidTapWithTag:button.tag];
    
//测试内存泄露的代码如下:
    
//#ifdef RITL_Objc_msgSend
//    
//    Class class = objc_getClass("RITLRootViewController");
//    
//    id viewController = ((id(*)(id,SEL))objc_msgSend)(class,NSSelectorFromString(@"new"));
//    
////    [self pushViewController:viewController];
//    [self ritl_pushViewController:viewController];
//    
//    
//#else
//    //普通的,在ARC管理之下
//    RITLRootViewController * viewController = [RITLRootViewController new];
//    viewController.title = @"Two";
//    viewController.backColor = [UIColor yellowColor];
//    
//    [self pushViewController:viewController];
//    
//#endif
    
}


- (void)pushViewController:(__kindof UIViewController *)viewController
{
    [self.navigationController pushViewController:viewController animated:true];
}


- (void)ritl_pushViewController:(__kindof UIViewController *)viewController
{
    [self pushViewController:viewController];
    
    //release
    ((void(*)(id,SEL))objc_msgSend)(viewController,NSSelectorFromString(@"release"));
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(RITLRootViewModel *)viewModel
{
    if (!_viewModel)
    {
        _viewModel = [RITLRootViewModel new];
    }
    
    return _viewModel;
}


@end
