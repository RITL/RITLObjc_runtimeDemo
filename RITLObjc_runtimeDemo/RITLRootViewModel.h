//
//  RITLRootViewModel.h
//  RITLObjc_runtimeDemo
//
//  Created by YueWen on 2017/1/13.
//  Copyright © 2017年 YueWen. All rights reserved.
//

#import <Foundation/Foundation.h>

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
