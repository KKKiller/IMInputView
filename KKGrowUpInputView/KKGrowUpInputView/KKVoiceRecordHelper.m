//
//  MTCommIMInputView.m
//  Mentor
//
//  Created by 我是MT on 16/7/12.
//  Copyright © 2016年 馒头科技. All rights reserved.
//

#import "KKVoiceRecordHelper.h"
#import <AVFoundation/AVFoundation.h>
#define kVoiceRecorderTotalTime 60.0
#define WEAKSELF typeof(self) __weak weakSelf = self;
#define STRONGSELF typeof(weakSelf) __strong strongSelf = weakSelf;

#ifdef DEBUG
#   define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define DLog(...)
#endif

@interface KKVoiceRecordHelper () <AVAudioRecorderDelegate> {
    NSTimer *_timer;
    
    BOOL _isPause;
    
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    UIBackgroundTaskIdentifier _backgroundIdentifier;
#endif
}
@property (nonatomic, copy, readwrite) NSString *recordPath;
@property (nonatomic, readwrite) NSTimeInterval currentTimeInterval;

@property (nonatomic, strong) AVAudioRecorder *recorder;

@end

@implementation KKVoiceRecordHelper

- (id)init {
    self = [super init];
    if (self) {
        self.maxRecordTime = kVoiceRecorderTotalTime;
        self.recordDuration = @"0";
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
		_backgroundIdentifier = UIBackgroundTaskInvalid;
#endif
    }
    return self;
}

- (void)dealloc {
    [self stopRecord];
    self.recordPath = nil;
    [self stopBackgroundTask];
}

- (void)startBackgroundTask {
	[self stopBackgroundTask];
	
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
	_backgroundIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
		[self stopBackgroundTask];
	}];
#endif
}

- (void)stopBackgroundTask {
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
	if (_backgroundIdentifier != UIBackgroundTaskInvalid) {
		[[UIApplication sharedApplication] endBackgroundTask:_backgroundIdentifier];
		_backgroundIdentifier = UIBackgroundTaskInvalid;
	}
#endif
}

- (void)resetTimer {
    if (!_timer)
        return;
    
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
    
}

- (void)cancelRecording {
    if (!_recorder)
        return;
    
    if (self.recorder.isRecording) {
        [self.recorder stop];
    }
    
    self.recorder = nil;
}

- (void)stopRecord {
    [self cancelRecording];
    [self resetTimer];
}

- (void)prepareRecordingWithPath:(NSString *)path prepareRecorderCompletion:(XHPrepareRecorderCompletion)prepareRecorderCompletion {
    WEAKSELF
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        _isPause = NO;
        
        NSError *error = nil;
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setCategory :AVAudioSessionCategoryPlayAndRecord error:&error];
        if(error) {
            DLog(@"audioSession: %@ %ld %@", [error domain], (long)[error code], [[error userInfo] description]);
            return;
        }
        
        error = nil;
        [audioSession setActive:YES error:&error];
        if(error) {
            DLog(@"audioSession: %@ %ld %@", [error domain], (long)[error code], [[error userInfo] description]);
            return;
        }
        
        NSMutableDictionary * recordSetting = [NSMutableDictionary dictionary];
        [recordSetting setValue :[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
        [recordSetting setValue:[NSNumber numberWithFloat:16000.0] forKey:AVSampleRateKey];
        [recordSetting setValue:[NSNumber numberWithInt: 1] forKey:AVNumberOfChannelsKey];
        
        if (weakSelf) {
            STRONGSELF
            strongSelf.recordPath = path;
            error = nil;
            
            if (strongSelf.recorder) {
                [strongSelf cancelRecording];
            } else {
                strongSelf.recorder = [[AVAudioRecorder alloc] initWithURL:[NSURL fileURLWithPath:strongSelf.recordPath] settings:recordSetting error:&error];
                strongSelf.recorder.delegate = strongSelf;
                [strongSelf.recorder prepareToRecord];
                strongSelf.recorder.meteringEnabled = YES;
                [strongSelf.recorder recordForDuration:(NSTimeInterval) 160];
                [strongSelf startBackgroundTask];
            }
            
            if(error) {
                DLog(@"audioSession: %@ %ld %@", [error domain], (long)[error code], [[error userInfo] description]);
                return;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                //上層如果傳會來說已經取消了, 那這邊就做原先取消的動作
                if (!prepareRecorderCompletion()) {
                    [strongSelf cancelledDeleteWithCompletion:^{
                    }];
                }
            });
        }
    });
}

- (void)startRecordingWithStartRecorderCompletion:(XHStartRecorderCompletion)startRecorderCompletion {
    if ([_recorder record]) {
        [self resetTimer];
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(updateMeters) userInfo:nil repeats:YES];
        if (startRecorderCompletion)
            dispatch_async(dispatch_get_main_queue(), ^{
                startRecorderCompletion();
            });
    }
}

- (void)resumeRecordingWithResumeRecorderCompletion:(XHResumeRecorderCompletion)resumeRecorderCompletion {
    _isPause = NO;
    if (_recorder) {
        if ([_recorder record]) {
            dispatch_async(dispatch_get_main_queue(), resumeRecorderCompletion);
        }
    }
}

- (void)pauseRecordingWithPauseRecorderCompletion:(XHPauseRecorderCompletion)pauseRecorderCompletion {
    _isPause = YES;
    if (_recorder) {
        [_recorder pause];
    }
    if (!_recorder.isRecording)
        dispatch_async(dispatch_get_main_queue(), pauseRecorderCompletion);
}

- (void)stopRecordingWithStopRecorderCompletion:(XHStopRecorderCompletion)stopRecorderCompletion {
    _isPause = NO;
    [self stopBackgroundTask];
    [self stopRecord];
    [self getVoiceDuration:_recordPath];
    dispatch_async(dispatch_get_main_queue(), stopRecorderCompletion);
}

- (void)cancelledDeleteWithCompletion:(XHCancellRecorderDeleteFileCompletion)cancelledDeleteCompletion {
    
    _isPause = NO;
    [self stopBackgroundTask];
    [self stopRecord];
    
    if (self.recordPath) {
        // 删除目录下的文件
        NSFileManager *fileManeger = [NSFileManager defaultManager];
        if ([fileManeger fileExistsAtPath:self.recordPath]) {
            NSError *error = nil;
            [fileManeger removeItemAtPath:self.recordPath error:&error];
            if (error) {
                DLog(@"error :%@", error.description);
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                cancelledDeleteCompletion(error);
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                cancelledDeleteCompletion(nil);
            });
        }
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            cancelledDeleteCompletion(nil);
        });
    }
}

- (void)updateMeters {
    if (!_recorder)
        return;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_recorder updateMeters];
        
        self.currentTimeInterval = _recorder.currentTime;
        
        if (!_isPause) {
            float progress = self.currentTimeInterval / self.maxRecordTime * 1.0;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (_recordProgress) {
                    _recordProgress(progress);
                }
            });
        }
        //开始倒计时
        if(self.currentTimeInterval > 50){
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter]postNotificationName:@"recordHUDBeginCutdown" object:nil];
            });
        }
        float peakPower = [_recorder averagePowerForChannel:0];
        double ALPHA = 0.015;
        double peakPowerForChannel = pow(10, (ALPHA * peakPower));
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // 更新扬声器
            if (_peakPowerForChannel) {
                _peakPowerForChannel(peakPowerForChannel);
            }
        });
        
        
        if (self.currentTimeInterval > self.maxRecordTime) {
            [self stopRecord];
            dispatch_async(dispatch_get_main_queue(), ^{
                _maxTimeStopRecorderCompletion();
            });
        }
    });
}

- (void)getVoiceDuration:(NSString*)recordPath {
    NSError *error = nil;
    AVAudioPlayer *play = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:recordPath] error:&error];
    if (error) {
        DLog(@"recordPath：%@ error：%@", recordPath, error);
        self.recordDuration = @"";
    } else {
        DLog(@"时长:%f", play.duration);
        self.recordDuration = [NSString stringWithFormat:@"%.1f", play.duration];
    }
}

@end
