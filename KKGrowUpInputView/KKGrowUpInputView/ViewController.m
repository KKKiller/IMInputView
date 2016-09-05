//
//  ViewController.m
//  KKGrowUpInputView
//
//  Created by 我是MT on 16/8/31.
//  Copyright © 2016年 馒头科技. All rights reserved.
//

#import "ViewController.h"
#import "KKGrowUpInputView.h"
#import "KKVoiceRecordHUD.h"
#import "KKVoiceRecordHelper.h"
#import "KKPhotoPickerManager.h"
#import "AppDelegate.h"
#define WEAKSELF typeof(self) __weak weakSelf = self;

@interface ViewController ()<KKInputViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>
@property (strong, nonatomic) KKGrowUpInputView *inputView;
@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UIImageView *backImgView;
@property (strong, nonatomic) UILabel *textLbl;

@property (nonatomic, strong, readwrite) KKVoiceRecordHUD *voiceRecordHUD; //录音提示
@property (nonatomic, strong) KKVoiceRecordHelper *voiceRecordHelper; //录音管理工具
@property (nonatomic) BOOL isMaxTimeStop; //判断是不是超出了录音最大时长
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.scrollView];
    [self.view addSubview:self.inputView];
    [self.scrollView addSubview:self.backImgView];
    [self.scrollView addSubview:self.textLbl];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(inputHChange:) name:@"textInputFrameChange" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(inputHChange:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(inputHChange:) name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark 发送文字
//发送按钮按下
- (void)returnBtnClickedWithText:(NSString *)text{
    self.textLbl.text = text;
}
- (void)tapAtScrollView {
    if (self.inputView.isEditing) { //有键盘,隐藏键盘
        [self.inputView.textView resignFirstResponder];
    }else{ //没键盘,发图片模式,改变inputView的高度
        [self.scrollView setContentOffset:CGPointMake(0, self.inputView.inputH-49) animated:YES];
        [UIView animateWithDuration:0.2 animations:^{
            self.inputView.frame = CGRectMake(0, self.view.frame.size.height -self.inputView.inputH, self.view.frame.size.width, self.inputView.inputH) ;
        } completion:^(BOOL finished) {
            self.inputView.picBtn.hidden = YES;
            self.inputView.photoBtn.hidden = YES;
        }];
    }
}
//键盘变动,更新frame
- (void)inputHChange:(NSNotification *)noti {
    if ([noti.name isEqualToString:@"UIKeyboardWillShowNotification"]) {
        [self.scrollView setContentOffset:CGPointMake(0, self.inputView.inputH+self.inputView.keyboardHeight-49) animated:NO];
    }else if ([noti.name isEqualToString:@"UIKeyboardWillHideNotification"]){
        if(!self.inputView.isClickPlus){
            [self.scrollView setContentOffset:CGPointMake(0, self.inputView.inputH-49) animated:NO];
        }
        self.inputView.isClickPlus = NO;
    }else if ([noti.name isEqualToString:@"textInputFrameChange"]){
        CGFloat offset = [[noti.userInfo valueForKey:@"offset"] floatValue];
        [self.scrollView setContentOffset:CGPointMake(0, offset-49) animated:YES];
    }
}

#pragma mark - 发送音频代理
//准备开始录音
- (void)prepareRecordingVoiceActionWithCompletion:(BOOL (^)(void))completion {
    [self.voiceRecordHelper prepareRecordingWithPath:[self getRecorderPath] prepareRecorderCompletion:completion];
}
//开始录音
- (void)didStartRecordingVoiceAction {
    [self.voiceRecordHUD startRecordingHUDAtView:self.view];
    [self.voiceRecordHelper startRecordingWithStartRecorderCompletion:^{
    }];
}
//取消录音
- (void)didCancelRecordingVoiceAction {
    WEAKSELF
    [self.voiceRecordHUD cancelRecordCompled:^(BOOL fnished) {
        weakSelf.voiceRecordHUD = nil;
    }];
    [self.voiceRecordHelper cancelledDeleteWithCompletion:^{
    }];
}
//完成录音
- (void)didFinishRecoingVoiceAction {
    if (self.isMaxTimeStop == NO) {
        [self finishRecorded];
    } else {
        self.isMaxTimeStop = NO;
    }
}
- (void)finishRecorded {
    WEAKSELF
    [self.voiceRecordHUD stopRecordCompled:^(BOOL fnished) {
        weakSelf.voiceRecordHUD = nil;
    }];
    [self.voiceRecordHelper stopRecordingWithStopRecorderCompletion:^{
    }];
}
//移出录音区间
- (void)didDragOutsideAction {
    [self.voiceRecordHUD resaueRecord];
}
//移入录音区间
- (void)didDragInsideAction {
    [self.voiceRecordHUD pauseRecord];
}
//录音文件地址
- (NSString *)getRecorderPath {
    NSString *recorderPath = nil;
    recorderPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex: 0];
    recorderPath = [recorderPath stringByAppendingFormat:@"MySound.m4a"];
    return recorderPath;
}

#pragma mark - 照片
//图库
- (void)ChooseFromAlbum {
    ((AppDelegate*)[[UIApplication sharedApplication] delegate]).maxPicNum = 9 ;
    ((AppDelegate*)[[UIApplication sharedApplication] delegate]).selectedPicNum = 0;
    [[KKPhotoPickerManager shareInstace] getImagesfromController:self completionBlock:^(NSMutableArray *imageArray) {
        for (UIImage *image in imageArray) {
            //发送图片
        }
    }];
}
//拍照
- (void)openCamera {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self presentViewController:picker animated:YES completion:nil];
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    [picker dismissViewControllerAnimated:YES completion:nil];
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    //发送图片方法
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:^(){
    }];
}


#pragma mark - 懒加载
- (KKGrowUpInputView *)inputView {
    if (_inputView == nil) {
        _inputView = [[KKGrowUpInputView alloc]initWithFrame:CGRectMake(0, self.view.frame.size.height - 49, self.view.frame.size.width, 49)];
        _inputView.inputDelegate = self;
        [_inputView.picBtn addTarget:self action:@selector(ChooseFromAlbum) forControlEvents:UIControlEventTouchUpInside];
        [_inputView.photoBtn addTarget:self action:@selector(openCamera) forControlEvents:UIControlEventTouchUpInside];
    }
    return _inputView;
}
- (UIScrollView *)scrollView {
    if (_scrollView == nil) {
        _scrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 49)];
        _scrollView.contentSize =CGSizeMake(self.view.frame.size.width, self.view.frame.size.height-48);
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapAtScrollView)];
        [_scrollView addGestureRecognizer:tap];
    }
    return _scrollView;
}
- (UIImageView *)backImgView {
    if (_backImgView == nil) {
        _backImgView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 49)];
        _backImgView.image = [UIImage imageNamed:@"girl"];
        _backImgView.contentMode = UIViewContentModeScaleAspectFill;
        
    }
    return _backImgView;
}
- (UILabel *)textLbl {
    if (_textLbl == nil) {
        _textLbl = [[UILabel alloc]initWithFrame:CGRectMake(20, 380, self.view.frame.size.width -40, 100)];
        _textLbl.textColor = [UIColor whiteColor];
    }
    return _textLbl;
}

//录音HUD
- (KKVoiceRecordHUD *)voiceRecordHUD {
    if (!_voiceRecordHUD) {
        _voiceRecordHUD = [[KKVoiceRecordHUD alloc] initWithFrame:CGRectMake(0, 0, 140, 140)];
    }
    return _voiceRecordHUD;
}
//录音
- (KKVoiceRecordHelper *)voiceRecordHelper {
    if (!_voiceRecordHelper) {
        _isMaxTimeStop = NO;
        
        WEAKSELF
        _voiceRecordHelper = [[KKVoiceRecordHelper alloc] init];
        _voiceRecordHelper.maxTimeStopRecorderCompletion = ^{
            NSLog(@"已经达到最大限制时间了，进入下一步的提示");
            weakSelf.isMaxTimeStop = YES;
            [weakSelf finishRecorded]; //超时 直接发送
        };
        _voiceRecordHelper.peakPowerForChannel = ^(float peakPowerForChannel) {
            weakSelf.voiceRecordHUD.peakPower = peakPowerForChannel;
        };
        _voiceRecordHelper.maxRecordTime = 60.0;
    }
    return _voiceRecordHelper;
}
@end
