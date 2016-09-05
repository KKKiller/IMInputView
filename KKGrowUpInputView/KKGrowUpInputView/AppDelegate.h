//
//  AppDelegate.h
//  KKGrowUpInputView
//
//  Created by 我是MT on 16/8/31.
//  Copyright © 2016年 馒头科技. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>
#define App_Delegate      ((AppDelegate*)[[UIApplication sharedApplication]delegate])

@property (strong, nonatomic) UIWindow *window;

@property (assign, nonatomic) NSInteger maxPicNum; //发布跟帖可选最大图片张数
@property (assign, nonatomic) NSInteger selectedPicNum; //已选择张数
@end

