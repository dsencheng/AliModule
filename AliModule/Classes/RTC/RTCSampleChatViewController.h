//
//  RTCSampleChatViewController.h
//  RtcSample
//
//  Created by daijian on 2019/2/27.
//  Copyright © 2019年 tiantian. All rights reserved.
//

#import <AliRTCSdk/AliRTCSdk.h>

NS_ASSUME_NONNULL_BEGIN

@interface RTCSampleChatViewController : UIViewController

@property(nonatomic, strong) AliRtcAuthInfo *authInfo;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic, assign) BOOL initiator;//是否发起方
@property (nonatomic, retain) NSString *remote_user_id;//远程用户id

@end

NS_ASSUME_NONNULL_END

