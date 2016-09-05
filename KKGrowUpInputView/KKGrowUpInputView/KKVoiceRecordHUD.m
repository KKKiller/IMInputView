//
//  MTCommIMInputView.m
//  Mentor
//
//  Created by 我是MT on 16/7/12.
//  Copyright © 2016年 馒头科技. All rights reserved.
//

#import "KKVoiceRecordHUD.h"

@interface KKVoiceRecordHUD ()

@property (nonatomic, weak) UILabel *remindLabel;
@property (nonatomic, weak) UIImageView *microPhoneImageView;
@property (nonatomic, weak) UIImageView *cancelRecordImageView;
@property (nonatomic, weak) UIImageView *recordingHUDImageView;

@property (assign, nonatomic) BOOL isBeginCutdown;
@property (strong, nonatomic) UILabel *cutdownLbl; //倒计时
@property (strong, nonatomic) NSTimer *cutdownTimer;
@property (assign, nonatomic) NSInteger cutdownNum;

/**
 *  逐渐消失自身
 *
 *  @param compled 消失完成的回调block
 */
- (void)dismissCompled:(void(^)(BOOL fnished))compled;

/**
 *  配置是否正在录音，需要隐藏和显示某些特殊的控件
 *
 *  @param recording 是否录音中
 */
- (void)configRecoding:(BOOL)recording;

/**
 *  根据语音输入的大小来配置需要显示的HUD图片
 *
 *  @param peakPower 输入音频的声音大小
 */
- (void)configRecordingHUDImageWithPeakPower:(CGFloat)peakPower;

/**
 *  配置默认参数
 */
- (void)setup;

@end

@implementation KKVoiceRecordHUD

- (void)startRecordingHUDAtView:(UIView *)view {
    CGPoint center = CGPointMake(CGRectGetWidth(view.frame) / 2.0, CGRectGetHeight(view.frame) / 2.0);
    self.center = center;
    [view addSubview:self];
    [self configRecoding:YES];
}

- (void)pauseRecord {
    [self configRecoding:YES];
    self.remindLabel.backgroundColor = [UIColor clearColor];
    self.remindLabel.text = NSLocalizedStringFromTable(@"SlideToCancel", @"MessageDisplayKitString", nil);
}

- (void)resaueRecord {
    [self configRecoding:NO];
    self.remindLabel.backgroundColor = [UIColor colorWithRed:1.000 green:0.000 blue:0.000 alpha:0.630];
    self.remindLabel.text = NSLocalizedStringFromTable(@"ReleaseToCancel", @"MessageDisplayKitString", nil);
}

- (void)stopRecordCompled:(void(^)(BOOL fnished))compled {
    [self dismissCompled:compled];
}

- (void)cancelRecordCompled:(void(^)(BOOL fnished))compled {
    [self dismissCompled:compled];
}

- (void)dismissCompled:(void(^)(BOOL fnished))compled {
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.alpha = 0.0;
    } completion:^(BOOL finished) {
        [super removeFromSuperview];
        compled(finished);
    }];
}

- (void)configRecoding:(BOOL)recording {
    self.microPhoneImageView.hidden = !recording;
    self.recordingHUDImageView.hidden = !recording;
    self.cancelRecordImageView.hidden = recording;
}

- (void)configRecordingHUDImageWithPeakPower:(CGFloat)peakPower {
    NSString *imageName = @"RecordingSignal00";
    if (peakPower >= 0 && peakPower <= 0.1) {
        imageName = [imageName stringByAppendingString:@"1"];
    } else if (peakPower > 0.1 && peakPower <= 0.2) {
        imageName = [imageName stringByAppendingString:@"2"];
    } else if (peakPower > 0.3 && peakPower <= 0.4) {
        imageName = [imageName stringByAppendingString:@"3"];
    } else if (peakPower > 0.4 && peakPower <= 0.5) {
        imageName = [imageName stringByAppendingString:@"4"];
    } else if (peakPower > 0.5 && peakPower <= 0.6) {
        imageName = [imageName stringByAppendingString:@"5"];
    } else if (peakPower > 0.7 && peakPower <= 0.8) {
        imageName = [imageName stringByAppendingString:@"6"];
    } else if (peakPower > 0.8 && peakPower <= 0.9) {
        imageName = [imageName stringByAppendingString:@"7"];
    } else if (peakPower > 0.9 && peakPower <= 1.0) {
        imageName = [imageName stringByAppendingString:@"8"];
    }
    self.recordingHUDImageView.image = [UIImage imageNamed:imageName];
}

- (void)setPeakPower:(CGFloat)peakPower {
    _peakPower = peakPower;
    [self configRecordingHUDImageWithPeakPower:peakPower];
}

- (void)setup {
    self.backgroundColor = [UIColor darkGrayColor];
    self.alpha = 0.95;
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = 10;
    
    if (!_remindLabel) {
        UILabel *remindLabel= [[UILabel alloc] initWithFrame:CGRectMake(9.0, 112.0, 120.0, 21.0)];
        remindLabel.textColor = [UIColor whiteColor];
        remindLabel.font = [UIFont systemFontOfSize:13];
        remindLabel.layer.masksToBounds = YES;
        remindLabel.layer.cornerRadius = 4;
        remindLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        remindLabel.backgroundColor = [UIColor clearColor];
        remindLabel.text = NSLocalizedStringFromTable(@"SlideToCancel", @"MessageDisplayKitString", nil);
        remindLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:remindLabel];
        _remindLabel = remindLabel;
    }
    
    if (!_cutdownLbl) {
        UILabel *cutdownLbl = [[UILabel alloc]initWithFrame:CGRectMake(9, 26, 120, 80)];
        cutdownLbl.textColor = [UIColor whiteColor];
        
        cutdownLbl.font = [UIFont systemFontOfSize:80];
        cutdownLbl.layer.masksToBounds = YES;
        cutdownLbl.layer.cornerRadius = 4;
        cutdownLbl.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        cutdownLbl.backgroundColor = [UIColor clearColor];
        cutdownLbl.text = NSLocalizedStringFromTable(@"SlideToCancel", @"MessageDisplayKitString", nil);
        cutdownLbl.textAlignment = NSTextAlignmentCenter;
        [self addSubview:cutdownLbl];
        _cutdownLbl = cutdownLbl;
        cutdownLbl.text = @"";
        _cutdownLbl.hidden=YES;
    }
    
    if (!_microPhoneImageView) {
        UIImageView *microPhoneImageView = [[UIImageView alloc] initWithFrame:CGRectMake(40.0, 35.0, 34.0, 61.0)];
        microPhoneImageView.image = [UIImage imageNamed:@"micro"];
        microPhoneImageView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        microPhoneImageView.contentMode = UIViewContentModeScaleToFill;
        [self addSubview:microPhoneImageView];
        _microPhoneImageView = microPhoneImageView;
    }
    
    if (!_recordingHUDImageView) {
        UIImageView *recordHUDImageView = [[UIImageView alloc] initWithFrame:CGRectMake(85.0, 34.0, 18.0, 61.0)];
        recordHUDImageView.image = [UIImage imageNamed:@"RecordingSignal001"];
        recordHUDImageView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        recordHUDImageView.contentMode = UIViewContentModeScaleToFill;
        [self addSubview:recordHUDImageView];
        _recordingHUDImageView = recordHUDImageView;
    }
    
    if (!_cancelRecordImageView) {
        UIImageView *cancelRecordImageView = [[UIImageView alloc] initWithFrame:CGRectMake(45.0, 35.0, 40.0, 50.0)];
        cancelRecordImageView.image = [UIImage imageNamed:@"60second"];
        cancelRecordImageView.hidden = YES;
        cancelRecordImageView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        cancelRecordImageView.contentMode = UIViewContentModeScaleToFill;
        [self addSubview:cancelRecordImageView];
        _cancelRecordImageView = cancelRecordImageView;
    }
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setup];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(beginCutdown) name:@"recordHUDBeginCutdown" object:nil];
    }
    return self;
}

//倒计时功能
- (void)beginCutdown {
    if (!self.isBeginCutdown) {
        self.isBeginCutdown = YES;
        self.cutdownNum = 11;
        [self setCutdownText];
        self.cutdownTimer  = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(setCutdownText) userInfo:nil repeats:YES];
        self.cutdownLbl.hidden= NO;
    }
}
- (void)setCutdownText {
    if (self.cutdownNum > 0) {
        self.cutdownNum--;
        self.cutdownLbl.text = [NSString stringWithFormat:@"%zd",self.cutdownNum];
        self.microPhoneImageView.hidden=YES;
        self.recordingHUDImageView.hidden=YES;
    }else{
        self.cutdownLbl.hidden = YES;
    }
}
@end
