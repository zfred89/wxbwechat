#import "WxbwechatPlugin.h"

@implementation WxbwechatPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"wxbwechat"
            binaryMessenger:[registrar messenger]];
  WxbwechatPlugin* instance = [[WxbwechatPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"getPlatformVersion" isEqualToString:call.method]) {
    result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  } else if ([@"register" isEqualToString:call.method]){
      [WXApi registerApp:@"wx7df4c6aef7dd5845"];
      result(@"注册微信开发者");
  }else if ([@"send" isEqualToString:call.method]){
      [self shareToWechatWithName:@"大魔王" visitingCardId:@"VC1e9ecdb33f6b404d8045a8a91bc0" imgUrl:@"http://adv.wangxiaobao.com/1564989164333.jpg"];
      result(@"已发送");
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (void)shareToWechatWithName:(NSString *)name visitingCardId:(NSString *)cardId imgUrl:(NSString *)imgUrl {
    NSString *title = [NSString stringWithFormat:@"你好，我是%@，这是我的名片",name];
    NSString *path = [NSString stringWithFormat:@"pages/personal_card/card?visitingCardId=%@",cardId];
    WXMiniProgramObject *wxMiniObject = [[WXMiniProgramObject alloc]init];
    wxMiniObject.webpageUrl = @"https://api-test-c.wabgxiaobao.co/visiting-card/error";
    wxMiniObject.userName = @"gh_d2b176e76ef5";
    wxMiniObject.path = path;
    wxMiniObject.hdImageData = [self getDataWithImageUrl:imgUrl];
    wxMiniObject.miniProgramType = WXMiniProgramTypeTest;
    wxMiniObject.withShareTicket = YES;
    
    WXMediaMessage *message = [[WXMediaMessage alloc]init];
    message.title = title;
    message.description = title;
    message.mediaObject = wxMiniObject;
    message.thumbData = nil;
    
    SendMessageToWXReq *req = [[SendMessageToWXReq alloc]init];
    req.message = message;
    req.bText = NO;
    req.scene = WXSceneSession;
    [WXApi sendReq:req];
}

- (NSData*)getDataWithImageUrl:(NSString *)imgUrl{
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:imgUrl]];
    return data;
}

@end
