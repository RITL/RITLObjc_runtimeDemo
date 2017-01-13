//
//  RITLRootViewModel.m
//  RITLObjc_runtimeDemo
//
//  Created by YueWen on 2017/1/13.
//  Copyright © 2017年 YueWen. All rights reserved.
//

#import "RITLRootViewModel.h"

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
