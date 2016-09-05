//
//  MTCommIMInputView.m
//  Mentor
//
//  Created by 我是MT on 16/7/12.
//  Copyright © 2016年 馒头科技. All rights reserved.
//

#import "KKGrowUpInputView.h"

#define App_Height [[UIScreen mainScreen] bounds].size.height //主屏幕的高度
#define App_Width  [[UIScreen mainScreen] bounds].size.width  //主屏幕的宽度
#define WEAKSELF typeof(self) __weak weakSelf = self;
#define STRONGSELF typeof(weakSelf) __strong strongSelf = weakSelf;
#define RGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16)) / 255.0 green:((float)((rgbValue & 0xFF00) >> 8)) / 255.0 blue:((float)(rgbValue & 0xFF)) / 255.0 alpha:1.0]
#define IMAGENAMED(NAME)       [UIImage imageNamed:NAME]


@interface KKGrowUpInputView()<UITextViewDelegate,UIScrollViewDelegate>
@property (assign, nonatomic) BOOL isTextMaxH; //当文字大于限定高度之后的状态
@property (nonatomic, strong) UIView *backGroundView;
@property (strong, nonatomic) UILabel *lineLbl;

@property (assign, nonatomic) CGFloat currentTextViewH;


@end

@implementation KKGrowUpInputView

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self setUI];
        self.inputH = 49;
        self.keyboardHeight = 258;
        self.backgroundColor = [UIColor whiteColor];
        //增加监听，当键盘出现或改变时收出消息
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:)name:UIKeyboardWillShowNotification object:nil];
        //增加监听，当键退出时收出消息
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:)name:UIKeyboardWillHideNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow)name:UIKeyboardDidShowNotification
                                                   object:nil];
    }
    return self;
}
#pragma mark - 图片按钮点击
- (void)plusBtnClick {
    if (!self.isEditing) { //没有弹出键盘,点击加号弹出键盘
        NSString *offset = [NSString stringWithFormat:@"%f",self.keyboardHeight + self.inputH];
        [[NSNotificationCenter defaultCenter]postNotificationName:@"textInputFrameChange" object:nil userInfo:@{@"offset":offset}];
    }
    if (self.frame.origin.y < App_Height - self.inputH && !self.isEditing) { //当前是发照片模式,或者编辑模式,再点击加号,退出发照片键盘
        NSString *offset = [NSString stringWithFormat:@"%f", self.inputH];
        [[NSNotificationCenter defaultCenter]postNotificationName:@"textInputFrameChange" object:nil userInfo:@{@"offset":offset}];
    }
    [self.voiceBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mas_left).offset(10);
        make.centerY.equalTo(self.textView.mas_centerY);
        make.width.height.mas_equalTo(30);
    }];
    self.picBtn.hidden = NO;
    self.photoBtn.hidden =NO;
    self.isClickPlus = YES;
    if (self.isEditing) {
        [self.textView resignFirstResponder];
    }else{
        CGFloat y = (self.frame.origin.y  < (App_Height - self.inputH)) ? App_Height - self.inputH : (App_Height - self.keyboardHeight - self.inputH);
        [UIView animateWithDuration:0.25 animations:^{
            self.frame = CGRectMake(0, y, App_Width,self.inputH + self.keyboardHeight );
        }];
    }
    [self performSelector:@selector(hidePicBtn) withObject:nil afterDelay:0.5];
}
- (void)hidePicBtn {
    self.picBtn.hidden = NO;
    self.photoBtn.hidden =NO;
}

#pragma mark - 录音按钮点击
- (void)voiceBtnClick:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) { //语音状态
        self.voicePressBtn.hidden = NO;
        [self.textView resignFirstResponder];
        [UIView animateWithDuration:0.25 animations:^{
            self.frame = CGRectMake(0, App_Height - 49, App_Width, 49);
        }];
        [self.voiceBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.mas_left).offset(10);
            make.centerY.equalTo(self.mas_centerY);
            make.width.height.mas_equalTo(30);
        }];
    }else{ //文字状态
        self.voicePressBtn.hidden = YES;
        [self.textView becomeFirstResponder];
        self.frame = CGRectMake(0, App_Height-self.keyboardHeight-self.inputH, App_Width, self.keyboardHeight+self.inputH);
        [self.voiceBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.mas_left).offset(10);
            make.centerY.equalTo(self.textView.mas_centerY);
            make.width.height.mas_equalTo(30);
        }];
    }
}
#pragma mark - 键盘各种状态
//当键盘出现
- (void)keyboardWillShow:(NSNotification *)aNotification{
    //获取键盘的高度
    self.isEditing = YES;
    NSValue *aValue = [[aNotification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [aValue CGRectValue];
    if (keyboardRect.size.height > self.keyboardHeight) {
        self.keyboardHeight = keyboardRect.size.height;
    }
    self.frame = CGRectMake(0, App_Height - self.keyboardHeight  - self.inputH, App_Width, self.inputH + self.keyboardHeight);
    self.backGroundView.frame = CGRectMake(0, 0, App_Width, self.inputH);
    [self.voiceBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mas_left).offset(10);
        make.centerY.equalTo(self.textView.mas_centerY);
        make.width.height.mas_equalTo(30);
    }];
}

- (void)keyboardWillHide:(NSNotification *)aNotification{
    self.isEditing = NO;
    if (self.isClickPlus) {
        return;
    }
    self.frame = CGRectMake(0, App_Height - self.inputH, App_Width, self.inputH) ;
}
- (void)keyboardDidShow {
    self.isEditing = YES;
    self.isClickPlus = NO;
}
#pragma mark - UITextViewDelegate
- (void)textViewDidChange:(UITextView *)textView{
    self.placeholderLabel.text =  textView.text.length == 0 ? @"说点什么吧...":@"";
    //---- 计算高度 ---- //
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:16],NSFontAttributeName, nil];
    CGFloat curheight = [textView.text boundingRectWithSize:CGSizeMake(App_Width-110, CGFLOAT_MAX)
                                                    options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:dic
                                                    context:nil].size.height;
    self.inputH = textView.contentSize.height + 12;
    if (self.currentTextViewH != curheight && curheight < 80) {
        self.currentTextViewH = curheight;
        NSString *offset = [NSString stringWithFormat:@"%f",self.keyboardHeight + self.inputH];
        [[NSNotificationCenter defaultCenter]postNotificationName:@"textInputFrameChange" object:nil userInfo:@{@"offset":offset}];
    }
    if (curheight < 19.094) { //一行
        self.isTextMaxH = NO;
        self.backGroundView.frame = CGRectMake(0,0 , App_Width, 49);//y - 49
    }else if(curheight < 80){ //多行
        self.isTextMaxH = NO;
        self.backGroundView.frame = CGRectMake(0, 0, App_Width, self.inputH);
    }else{
        self.isTextMaxH = YES;
        return;
    }
    self.frame = CGRectMake(0, App_Height - self.keyboardHeight - self.inputH, App_Width,self.inputH + self.keyboardHeight );
}

#pragma mark - 发送按钮 回车
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    if ([text isEqualToString:@"\n"]){ //判断输入的字是否是回车，即按下return
        if ([self.inputDelegate respondsToSelector:@selector(returnBtnClickedWithText:)]) {
            [self.inputDelegate returnBtnClickedWithText:self.textView.text];
        }
        self.inputH = 49;
        self.textView.text = @"";
        self.placeholderLabel.text = @"说点什么吧...";
        self.frame = CGRectMake(0, App_Height-self.inputH-self.keyboardHeight, App_Width, self.inputH+self.keyboardHeight);
        self.backGroundView.frame = CGRectMake(0, 0, App_Width, self.inputH);
        NSString *offset = [NSString stringWithFormat:@"%f",self.keyboardHeight + self.inputH];
        [[NSNotificationCenter defaultCenter]postNotificationName:@"textInputFrameChange" object:nil userInfo:@{@"offset":offset}];
        return NO; //这里返回NO，就代表return键值失效，即页面上按下return，不会出现换行，如果为yes，则输入
    }
    return YES;
}

#pragma mark - 录音按钮各种点击状态
- (void)holdDownButtonTouchDown {
    self.isCancleRecord = NO;
    self.isRecording = NO;
    //    SHOW(@"按下");
    if ([self.inputDelegate respondsToSelector:@selector(prepareRecordingVoiceActionWithCompletion:)]) {
        WEAKSELF
        //這邊回調 return 的 YES, 或 NO, 可以讓底層知道該次錄音是否成功, 進而處理無用的 record 對象
        [self.inputDelegate prepareRecordingVoiceActionWithCompletion:^BOOL{
            STRONGSELF
            //這邊要判斷回調回來的時候, 使用者是不是已經早就鬆開手了
            if (strongSelf && !strongSelf.isCancleRecord) {
                strongSelf.isRecording = YES;
                [strongSelf.inputDelegate didStartRecordingVoiceAction];
                return YES;
            } else {
                NSLog(@"说话时间太短");
                return NO;
            }
        }];
    }
}

- (void)holdDownButtonTouchUpOutside {
    //如果已經開始錄音了, 才需要做取消的動作, 否則只要切換 isCancelled, 不讓錄音開始.
    if (self.isRecording) {
        if ([self.inputDelegate respondsToSelector:@selector(didCancelRecordingVoiceAction)]) {
            [self.inputDelegate didCancelRecordingVoiceAction];
        }
    } else {
        self.isCancleRecord = YES;
    }
}

- (void)holdDownButtonTouchUpInside {
    //如果已經開始錄音了, 才需要做結束的動作, 否則只要切換 isCancelled, 不讓錄音開始.
    if (self.isRecording) {
        if ([self.inputDelegate respondsToSelector:@selector(didFinishRecoingVoiceAction)]) {
            [self.inputDelegate didFinishRecoingVoiceAction];
        }
    } else {
        self.isCancleRecord = YES;
    }
}

- (void)holdDownDragOutside {
    //如果已經開始錄音了, 才需要做拖曳出去的動作, 否則只要切換 isCancelled, 不讓錄音開始.
    if (self.isRecording) {
        if ([self.inputDelegate respondsToSelector:@selector(didDragOutsideAction)]) {
            [self.inputDelegate didDragOutsideAction];
        }
    } else {
        self.isCancleRecord = YES;
    }
}

- (void)holdDownDragInside {
    //如果已經開始錄音了, 才需要做拖曳回來的動作, 否則只要切換 isCancelled, 不讓錄音開始.
    if (self.isRecording) {
        if ([self.inputDelegate respondsToSelector:@selector(didDragInsideAction)]) {
            [self.inputDelegate didDragInsideAction];
        }
    } else {
        self.isCancleRecord = YES;
    }
}
#pragma mark - UI

- (void)setUI{
    [self addSubview:self.backGroundView];
    [self.backGroundView addSubview:self.plusBtn];
    
    self.picBtn = [[UIButton alloc]init];
    [self.picBtn setImage:[UIImage imageNamed:@"keyboard_pic"] forState:UIControlStateNormal];
    [self addSubview:self.picBtn];
    self.picBtn.hidden = YES;
    self.photoBtn =[[UIButton alloc]init];
    [self.photoBtn setImage:[UIImage imageNamed:@"keyboard_camera"] forState:UIControlStateNormal];
    [self addSubview:self.photoBtn];
    self.photoBtn.hidden = YES;
    
    [self.lineLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mas_left).offset(0);
        make.right.equalTo(self.mas_right);
        make.bottom.equalTo(self.backGroundView.mas_bottom).offset(0);
        make.height.mas_equalTo(0.5);
    }];
    [self.voiceBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mas_left).offset(10);
        make.centerY.equalTo(self.backGroundView.mas_centerY);
        make.width.height.mas_equalTo(30);
    }];
    [self.plusBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.mas_right).offset(-15);
        make.centerY.equalTo(self.textView.mas_centerY);
        make.width.height.mas_equalTo(30);
    }];
    [self.textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(6);
        make.left.equalTo(self.voiceBtn.mas_right).offset(10);
        make.bottom.equalTo(self.backGroundView.mas_bottom).offset(-6);
        make.right.equalTo(self.plusBtn.mas_left).offset(-15);
    }];
    [self.voicePressBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.textView.mas_left).offset(0);
        make.top.equalTo(self.textView.mas_top).offset(0);
        make.right.equalTo(self.textView.mas_right);
        make.bottom.equalTo(self.textView.mas_bottom);
    }];
    [self.placeholderLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(5);
        make.left.equalTo(self.textView.mas_left).offset(8);
        make.height.mas_equalTo(39);
    }];
    [self.picBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mas_left).offset(35);
        make.top.equalTo(self.textView.mas_bottom).offset(25);
        make.width.height.mas_equalTo(50);
    }];
    [self.photoBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.picBtn.mas_right).offset(35);
        make.top.equalTo(self.picBtn.mas_top).offset(0);
        make.width.height.mas_equalTo(50);
    }];
    [self.picLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.picBtn.mas_centerX);
        make.top.equalTo(self.picBtn.mas_bottom).offset(10);
    }];
    [self.photoLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.photoBtn.mas_centerX);
        make.top.equalTo(self.photoBtn.mas_bottom).offset(10);
    }];
    
}

#pragma mark - 懒加载控件
- (UIView *)backGroundView{
    if (!_backGroundView) {
        _backGroundView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, App_Width, 49)];
        [self addSubview:_backGroundView];
        _backGroundView.backgroundColor = RGB(0xf6f6f6);
    }
    return _backGroundView;
}
- (UITextView *)textView{
    if (!_textView) {
        _textView = [[UITextView alloc]init];
        _textView.font = [UIFont systemFontOfSize:16];
        _textView.delegate = self;
        _textView.layer.cornerRadius = 5;
        _textView.returnKeyType =  UIReturnKeySend;
        [self.backGroundView addSubview:_textView];
    }
    return _textView;
}
- (UIButton *)plusBtn {
    if (_plusBtn == nil) {
        _plusBtn = [[UIButton alloc]init];
        [_plusBtn setImage:[UIImage imageNamed:@"keyboard_plus"] forState:UIControlStateNormal];
        [_plusBtn addTarget:self action:@selector(plusBtnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _plusBtn;
}
- (UILabel *)placeholderLabel{
    if (!_placeholderLabel) {
        _placeholderLabel = [[UILabel alloc]init];
        _placeholderLabel.text = @"说点什么吧...";
        _placeholderLabel.textColor = RGB(0x999999);
        _placeholderLabel.font = [UIFont systemFontOfSize:14];
        [self.backGroundView addSubview:_placeholderLabel];
    }
    return _placeholderLabel;
}
- (UILabel *)lineLbl {
    if (_lineLbl == nil) {
        _lineLbl = [[UILabel alloc]init];
        _lineLbl.backgroundColor = RGB(0xe5e5e5);
        [self addSubview:_lineLbl];
    }
    return _lineLbl;
}
- (UILabel *)picLbl {
    if (_picLbl == nil) {
        _picLbl = [[UILabel alloc]init];
        _picLbl.text = @"照片";
        _picLbl.textColor = RGB(0x666666);
        _picLbl.font = [UIFont systemFontOfSize:12];
        [self addSubview:_picLbl];
    }
    return _picLbl;
}
- (UILabel *)photoLbl {
    if (_photoLbl == nil) {
        _photoLbl = [[UILabel alloc]init];
        _photoLbl.text = @"拍照";
        _photoLbl.textColor = RGB(0x666666);
        _photoLbl.font = [UIFont systemFontOfSize:12];
        [self addSubview:_photoLbl];
    }
    return _photoLbl;
}
- (UIButton *)voiceBtn {
    if (_voiceBtn == nil) {
        _voiceBtn = [[UIButton alloc]init];
        _voiceBtn.titleLabel.textColor = RGB(0x666666);
        _voiceBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        [_voiceBtn setImage:IMAGENAMED(@"input_voice") forState:UIControlStateNormal];
        [_voiceBtn setImage:IMAGENAMED(@"input_word") forState:UIControlStateSelected];
        [self addSubview:_voiceBtn];
        [_voiceBtn addTarget:self action:@selector(voiceBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _voiceBtn;
}
- (UIButton *)voicePressBtn {
    if (_voicePressBtn == nil) {
        _voicePressBtn = [[UIButton alloc]init];
        [_voicePressBtn setTitle:@"按住 说话" forState:UIControlStateNormal];
        [_voicePressBtn setTitleColor:RGB(0x666666) forState:UIControlStateNormal];
        _voicePressBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        _voicePressBtn.layer.borderColor = RGB(0x666666).CGColor;
        _voicePressBtn.layer.borderWidth = 0.5;
        _voicePressBtn.layer.cornerRadius = 5;
        [_voicePressBtn setTitle:@"松开 结束" forState:UIControlStateHighlighted];
        [_voicePressBtn setBackgroundImage:IMAGENAMED(@"im_input_voice_normal") forState:UIControlStateNormal];
        [_voicePressBtn setBackgroundImage:IMAGENAMED(@"im_input_voice_highlited") forState:UIControlStateHighlighted];
        [self addSubview:_voicePressBtn];
        _voicePressBtn.hidden = YES;
        _voicePressBtn.backgroundColor = RGB(0xf6f6f6);
        
        [_voicePressBtn addTarget:self action:@selector(holdDownButtonTouchDown) forControlEvents:UIControlEventTouchDown];
        [_voicePressBtn addTarget:self action:@selector(holdDownButtonTouchUpOutside) forControlEvents:UIControlEventTouchUpOutside];
        [_voicePressBtn addTarget:self action:@selector(holdDownButtonTouchUpInside) forControlEvents:UIControlEventTouchUpInside];
        [_voicePressBtn addTarget:self action:@selector(holdDownDragOutside) forControlEvents:UIControlEventTouchDragExit];
        [_voicePressBtn addTarget:self action:@selector(holdDownDragInside) forControlEvents:UIControlEventTouchDragEnter];
    }
    return _voicePressBtn;
}
@end
