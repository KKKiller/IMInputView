//
//  MTCommIMInputView.h
//  Mentor
//
//  Created by 我是MT on 16/7/12.
//  Copyright © 2016年 馒头科技. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "Masonry.h"
@protocol KKInputViewDelegate<NSObject>
//发送文字
- (void)returnBtnClickedWithText:(NSString *)text;
//准备录音
- (void)prepareRecordingVoiceActionWithCompletion:(BOOL (^)(void))completion;
//开始录音
- (void)didStartRecordingVoiceAction;
//手指向上滑动取消录音
- (void)didCancelRecordingVoiceAction;
//松开手指完成录音
- (void)didFinishRecoingVoiceAction;
//当手指离开按钮的范围内时，主要为了通知外部的HUD
- (void)didDragOutsideAction;
//当手指再次进入按钮的范围内时，主要也是为了通知外部的HUD
- (void)didDragInsideAction;

@end

@interface KKGrowUpInputView : UIView
@property (nonatomic, strong) UILabel *placeholderLabel;

@property (nonatomic, strong) UITextView *textView;
@property (strong, nonatomic) UIButton *plusBtn;
@property (strong, nonatomic) UIButton *voiceBtn;
@property (strong, nonatomic) UIButton *voicePressBtn;

@property (strong, nonatomic) UIButton *picBtn;
@property (strong, nonatomic) UIButton *photoBtn;
@property (strong, nonatomic) UILabel *picLbl;
@property (strong, nonatomic) UILabel *photoLbl;

@property (assign, nonatomic) CGFloat keyboardHeight;
@property (assign, nonatomic) CGFloat inputH;
@property (assign, nonatomic) BOOL isEditing;
@property (assign, nonatomic) BOOL isClickPlus; //点击加号

@property (strong, nonatomic) id<KKInputViewDelegate> inputDelegate;
@property (assign, nonatomic) BOOL isCancleRecord;
@property (assign, nonatomic) BOOL isRecording;

@end
