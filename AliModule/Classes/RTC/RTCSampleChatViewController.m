//
//  RTCSampleChatViewController.m
//  RtcSample
//
//  Created by daijian on 2019/2/27.
//  Copyright © 2019年 tiantian. All rights reserved.
//

#import "RTCSampleChatViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "UIViewController+RTCSampleAlert.h"
#import "RTCSampleRemoteUserManager.h"
#import "RTCSampleRemoteUserModel.h"

@interface RTCSampleChatViewController () <AliRtcEngineDelegate>

@property(nonatomic, strong) UIButton      *startButton;//
@property (nonatomic, strong) AliRtcEngine *engine;
@property(nonatomic, strong) RTCSampleRemoteUserManager *remoteUserManager;
@property(nonatomic, assign) BOOL isJoinChannel;
@property (nonatomic, weak) AliRenderView *remoteView;//远程预览, 即小窗口
@property (nonatomic, weak) AliRenderView *localView;//本地预览，即全屏窗口
@property (nonatomic, strong) UIButton *exchangePreViewButton;
@property (nonatomic, strong) NSString *curUid;
@property (nonatomic, assign) BOOL isExchanged;
@property(nonatomic, strong) UIButton * hangupButton;//挂断

@end

@implementation RTCSampleChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"视频通话";
    self.view.backgroundColor = [UIColor whiteColor];
    
    // 创建SDK实例，注册delegate，extras可以为空
    _engine = [AliRtcEngine sharedInstance:self extras:@""];
    
    //添加页面控件
    [self addSubviews];

    //开启本地预览
    int res = [self.engine startPreview];
    if (res != 0) {
        NSLog(@"本地预览失败 %@" ,@(res));
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.initiator) {
        //发起方
        [self.startButton setTitle:@"取消" forState:UIControlStateNormal];
        [self.startButton addTarget:self action:@selector(leaveChannel:) forControlEvents:UIControlEventTouchUpInside];
        [self joinChannel:self.startButton];
    } else {
        //
        CGRect frame = self.startButton.frame;
        frame.origin.x = self.view.center.x - frame.size.width / 2 + 60;
        self.startButton.frame = frame;
        [self.startButton setTitle:@"接听" forState:UIControlStateNormal];
        [self.startButton addTarget:self action:@selector(joinChannel:) forControlEvents:UIControlEventTouchUpInside];
        self.hangupButton.hidden = NO;
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidAppear:animated];
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    if (self.isJoinChannel) {
        [UIView animateWithDuration:0.5 animations:^{
            self.startButton.alpha = ABS(1 - self.startButton.alpha);
        }];
    }
}

#pragma mark - action

//离开频道
- (void)leaveChannel:(UIButton *)sender {
    [self stopPreView];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
//    [self.navigationController popViewControllerAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

//登陆服务器，并开始推流
- (void)joinChannel:(UIButton *)sender {
    if (self.isJoinChannel) {
        return;
    }
    //设置自动(手动)模式
    [self.engine setAutoPublish:YES withAutoSubscribe:YES];
    [self.engine enableSpeakerphone:YES];
    //采集音频
//    [self.engine muteLocalMic:YES];
//    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
//    [audioSession setActive:YES error:nil];
//    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord error:nil];

    //AliRtcAuthInfo:各项参数均需要客户App Server(客户的server端) 通过OpenAPI来获取，然后App Server下发至客户端，客户端将各项参数赋值后，即可joinChannel
    __weak __typeof(self) weakself = self;
    //加入频道
    [self.engine joinChannel:self.authInfo name:[NSString stringWithFormat:@"%@", self.userName] onResult:^(NSInteger errCode) {
        //加入频道回调处理
        NSLog(@"joinChannel result: %d", (int)errCode);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //离线block
            void(^offLineBlock)(void) = ^{
                [weakself showAlertWithMessage:@"对方已离线,请挂断" handler:^(UIAlertAction * _Nonnull action) {
                    __strong typeof(weakself) strongSelf = weakself;
                    [strongSelf leaveChannel:nil];
                }];
            };
            if (errCode != 0) {
                //有错误 强制离线
                offLineBlock();
            }
            __strong typeof(weakself) strongSelf = weakself;
            //离线状态暂时无法准确检测。
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                NSLog(@"online Users :%@", [strongSelf.engine getOnlineRemoteUsers]);
//                if (strongSelf.initiator == false && strongSelf.remote_user_id.length > 0) {
//                    // 当前为接收方时，远程用户不在线，强制离线
//                    BOOL isOnLine = [strongSelf.engine isUserOnline:strongSelf.remote_user_id];
//                    if (isOnLine == false) {
//                        offLineBlock();
//                    }
//                }
//            });
            strongSelf.isJoinChannel = YES;
            strongSelf.hangupButton.hidden = YES;
            CGRect frame = strongSelf.startButton.frame;
            frame.origin.x = strongSelf.view.center.x - frame.size.width / 2 ;
            strongSelf.startButton.frame = frame;
            
            [self.startButton setTitle:@"挂断" forState:UIControlStateNormal];
            [self.startButton removeTarget:self action:@selector(startPreview) forControlEvents:UIControlEventTouchUpInside];
            [self.startButton addTarget:self action:@selector(leaveChannel:) forControlEvents:UIControlEventTouchUpInside];
            [UIView animateWithDuration:0.5 animations:^{
                self.startButton.alpha = ABS(1 - self.startButton.alpha);
            }];
            
        });
    }];
    
    //防止屏幕锁定
    [UIApplication sharedApplication].idleTimerDisabled = YES;
}

#pragma mark - private


//离开频需要取消本地预览、离开频道、销毁SDK
- (void)stopPreView {
    
    [self.remoteUserManager removeAllUser];
    
    //停止本地预览
    [self.engine stopPreview];
    
    if (_isJoinChannel) {
        //离开频道
        [self.engine leaveChannel];
    }
    
    //销毁SDK实例
    [AliRtcEngine destroy];
}

//更新远程用户预览
- (void)updateRemoteView:(NSString*)uid {
    self.curUid = uid;
    if (self.remoteView == nil) {
        self.remoteView =  [self.remoteUserManager cameraView:uid];
        self.remoteView.frame = [self remoteFrame];
        [self.view insertSubview:self.remoteView aboveSubview:self.localView];
    }
}

//交互本地和远程预览窗口
- (void)exchangePreview {
    self.isExchanged = !self.isExchanged;
    if (self.isExchanged) {
        self.localView.frame = [self remoteFrame];
        self.remoteView.frame = self.view.bounds;
        [self.view exchangeSubviewAtIndex:[self.view.subviews indexOfObject:self.localView] withSubviewAtIndex:[self.view.subviews indexOfObject:self.remoteView]];
    } else {
        self.remoteView.frame = [self remoteFrame];
        self.localView.frame = self.view.bounds;
        [self.view exchangeSubviewAtIndex:[self.view.subviews indexOfObject:self.localView] withSubviewAtIndex:[self.view.subviews indexOfObject:self.remoteView]];
    }
}

- (void)cameraSwitch {
    BOOL res = [self.engine switchCamera];
    res ? NSLog(@"切换成功") : NSLog(@"切换失败");
}

- (void)hangupAction {
    //销毁SDK实例
    [AliRtcEngine destroy];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - AliRtcEngineDelegate

- (void)onSubscribeChangedNotify:(NSString *)uid audioTrack:(AliRtcAudioTrack)audioTrack videoTrack:(AliRtcVideoTrack)videoTrack {
    NSLog(@"onSubscribe:uid=%@,%lu", uid, (unsigned long)videoTrack);
    //收到远端订阅回调
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.remoteUserManager updateRemoteUser:uid forTrack:videoTrack];
        if (videoTrack == AliRtcVideoTrackCamera) {
            AliVideoCanvas *canvas = [[AliVideoCanvas alloc] init];
            canvas.renderMode = AliRtcRenderModeAuto;
            canvas.view = [self.remoteUserManager cameraView:uid];
            [self.engine setRemoteViewConfig:canvas uid:uid forTrack:AliRtcVideoTrackCamera];
        }else if (videoTrack == AliRtcVideoTrackScreen) {
            AliVideoCanvas *canvas2 = [[AliVideoCanvas alloc] init];
            canvas2.renderMode = AliRtcRenderModeAuto;
            canvas2.view = [self.remoteUserManager screenView:uid];
            [self.engine setRemoteViewConfig:canvas2 uid:uid forTrack:AliRtcVideoTrackScreen];
        }else if (videoTrack == AliRtcVideoTrackBoth) {
            
            AliVideoCanvas *canvas = [[AliVideoCanvas alloc] init];
            canvas.renderMode = AliRtcRenderModeAuto;
            canvas.view = [self.remoteUserManager cameraView:uid];
            [self.engine setRemoteViewConfig:canvas uid:uid forTrack:AliRtcVideoTrackCamera];
            
            AliVideoCanvas *canvas2 = [[AliVideoCanvas alloc] init];
            canvas2.renderMode = AliRtcRenderModeAuto;
            canvas2.view = [self.remoteUserManager screenView:uid];
            [self.engine setRemoteViewConfig:canvas2 uid:uid forTrack:AliRtcVideoTrackScreen];
        }
        [self updateRemoteView:uid];
    });
}

- (void)onFirstRemoteVideoFrameDrawn:(NSString *)uid videoTrack:(AliRtcVideoTrack)videoTrack {
    NSLog(@"%s", __func__);
}

- (void)onRemoteUserOnLineNotify:(NSString *)uid {
    NSLog(@"onRemoteOnLine");
    [self exchangePreview];
}

- (void)onRemoteUserOffLineNotify:(NSString *)uid {
    NSLog(@"onRemoteOffLine");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.remoteUserManager remoteUserOffLine:uid];
        [self updateRemoteView:uid];
        __weak typeof(self) weakSelf = self;
        [self showAlertWithMessage:@"对方已离线,请挂断" handler:^(UIAlertAction * _Nonnull action) {
             __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf leaveChannel:nil];
        }];
        
    });
}

- (void)onOccurError:(int)error {
    NSLog(@"onOccurError%d",error);
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (error == AliRtcErrorCodeHeartbeatTimeout || error == AliRtcErrorCodePollingError) {
            [strongSelf showAlertWithMessage:@"网络超时,请退出" handler:^(UIAlertAction * _Nonnull action) {
                [strongSelf leaveChannel:nil];
            }];
        }
    });
}

/**
 * @brief 网络质量变化时发出的消息
 * @note 当网络质量发生变化时触发
 */
- (void)onNetworkQualityChanged:(AliRtcNetworkQuality)quality {
    NSLog(@"%s", __func__);
}

/**
 * @brief 当远端用户的流发生变化时，返回这个消息
 * @note 远方用户停止推流，也会发送这个消息
 */
- (void)onRemoteTrackAvailableNotify:(NSString *)uid audioTrack:(AliRtcAudioTrack)audioTrack videoTrack:(AliRtcVideoTrack)videoTrack {
    NSLog(@"onRemoteTrackAvailableNotify:%@",uid);
}

/**
 * @brief 被服务器踢出频道的消息
 */
- (void)onBye:(int)code {
    NSLog(@"%s", __func__);
}

/**
 * @brief 如果engine出现warning，通过这个回调通知app
 * @param warn  Warning type
 */
- (void)onOccurWarning:(int)warn {
    NSLog(@"%s", __func__);
}

/**
 * @brief 订阅的视频数据回调
 * @param uid user id
 * @param videoSource video source
 * @param videoSample video sample
 */
- (void)onVideoSampleCallback:(NSString *)uid videoSource:(AliRtcVideoSource)videoSource videoSample:(AliRtcVideoDataSample *)videoSample {
    NSLog(@"%s ,%d,%d", __func__, videoSample.width, videoSample.height);
}


#pragma mark - add subviews

- (void)addSubviews {
    
    // 设置本地预览视频
    AliVideoCanvas *canvas   = [[AliVideoCanvas alloc] init];
    AliRenderView *renderView = [[AliRenderView alloc] initWithFrame:self.view.bounds];
    canvas.view = renderView;
    canvas.renderMode = AliRtcRenderModeAuto;
    [self.view addSubview:renderView];
    [self.engine setLocalViewConfig:canvas forTrack:AliRtcVideoTrackCamera];
    self.localView = renderView;
    
//    UIButton *exitButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    exitButton.frame = CGRectMake(0, 0, 60, 40);
//    [exitButton setTitle:@"退出" forState:UIControlStateNormal];
//    [exitButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
//    [exitButton addTarget:self action:@selector(leaveChannel:) forControlEvents:UIControlEventTouchUpInside];
//    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:exitButton];
    
    CGRect rcScreen = [UIScreen mainScreen].bounds;
    CGRect rc = rcScreen;
    rc.size   = CGSizeMake(60, 60);
    rc.origin.y  = rcScreen.size.height - 100;
    rc.origin.x  = self.view.center.x - rc.size.width/2;
    _startButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _startButton.frame = rc;
    [_startButton setTitle:@"开始" forState:UIControlStateNormal];
    [_startButton setBackgroundColor:[UIColor orangeColor]];
    _startButton.layer.cornerRadius  = rc.size.width/2;
    _startButton.layer.masksToBounds = YES;
//    [_startButton addTarget:self action:@selector(startPreview:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_startButton];
    
//    rc.origin.x = 20;
//    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    cancelButton.frame = rc;
//    [cancelButton setTitle:@"取消" forState:UIControlStateNormal];
//    [cancelButton setBackgroundColor:[UIColor redColor]];
//    cancelButton.layer.cornerRadius  = rc.size.width/2;
//    cancelButton.layer.masksToBounds = YES;
//    [cancelButton addTarget:self action:@selector(leaveChannel:) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:cancelButton];
    
//    UIButton *cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    cameraButton.frame = CGRectMake(CGRectGetWidth(self.view.bounds) - 60, self.view.layoutMarginsGuide.layoutFrame.origin.y + 10, 50, 50);
//    [cameraButton setTitle:@"摄像头" forState:UIControlStateNormal];
//    [cameraButton setBackgroundColor:[UIColor orangeColor]];
//    [cameraButton addTarget:self action:@selector(cameraSwitch) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:cameraButton];
    
    [self.view addSubview:self.exchangePreViewButton];
    [self.view addSubview:self.hangupButton];
    _remoteUserManager = [RTCSampleRemoteUserManager shareManager];
    
}

#pragma mark - Setter/Getter

- (UIButton  *)exchangePreViewButton {
    if (!_exchangePreViewButton) {
        _exchangePreViewButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _exchangePreViewButton.frame = [self remoteFrame];
//        [_exchangePreViewButton setTitle:@"切换预览" forState:UIControlStateNormal];
//        [_exchangePreViewButton setBackgroundColor:[UIColor orangeColor]];
        [_exchangePreViewButton addTarget:self action:@selector(exchangePreview) forControlEvents:UIControlEventTouchUpInside];
    }
    return _exchangePreViewButton;
}

- (UIButton  *)hangupButton {
    if (!_hangupButton) {
        _hangupButton = [UIButton buttonWithType:UIButtonTypeCustom];
        CGRect rcScreen = [UIScreen mainScreen].bounds;
        CGRect rc = rcScreen;
        rc.size   = CGSizeMake(60, 60);
        rc.origin.y  = rcScreen.size.height - 100;
        rc.origin.x  = self.view.center.x - rc.size.width/2 - 60;
        _hangupButton.frame = rc;
        [_hangupButton setTitle:@"挂断" forState:UIControlStateNormal];
        [_hangupButton setBackgroundColor:[UIColor colorWithRed:237/255.0 green:6/255.0 blue:0 alpha:1]];
        _hangupButton.layer.cornerRadius  = rc.size.width/2;
        _hangupButton.layer.masksToBounds = YES;
        _hangupButton.hidden = YES;
        [_hangupButton addTarget:self action:@selector(hangupAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _hangupButton;
}

- (CGRect)remoteFrame {
    return CGRectMake(10, self.view.layoutMarginsGuide.layoutFrame.origin.y + 20, 95, 170);
}

@end
