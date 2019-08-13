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
      NSString *name = call.arguments[@"userName"];
      NSString *cardId = call.arguments[@"cardId"];
      NSString *imageUrl = call.arguments[@"headimgurl"];
      
      [self shareToWechatWithName:name visitingCardId:cardId imgUrl:imageUrl];
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
    UIImage *img = [self zipImageWithUrl:imgUrl];
    wxMiniObject.hdImageData = UIImageJPEGRepresentation(img, 1);
    wxMiniObject.miniProgramType = WXMiniProgramTypePreview;
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

- (UIImage *)zipImageWithUrl:(id)imageUrl
{
    NSData * imageData = [[NSData alloc]initWithContentsOfURL:[NSURL URLWithString:imageUrl]];
    imageData = UIImagePNGRepresentation(imageUrl);
    CGFloat maxFileSize = 32*1024;
    CGFloat compression = 0.9f;
    CGFloat maxCompression = 0.1f;
    UIImage *image = [UIImage imageWithData:imageData];
    NSData *compressedData = UIImageJPEGRepresentation(image, compression);
    while ([compressedData length] > maxFileSize && compression > maxCompression) {
        compression -= 0.1;
        compressedData = UIImageJPEGRepresentation(image, compression);
    }
    UIImage *compressedImage = [UIImage imageWithData:imageData];
    return compressedImage;
}


@end
