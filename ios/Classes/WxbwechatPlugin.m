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
      NSString *type = call.arguments[@"type"];
      
      [self shareToWechatWithName:name visitingCardId:cardId imgUrl:imageUrl type:type];
  }else if ([@"shareweb" isEqualToString:call.method]){
      NSString *title = call.arguments[@"title"];
      NSString *desc = call.arguments[@"desc"];
      NSString *url = call.arguments[@"url"];
      NSString *thumbUrl = call.arguments[@"thumbUrl"];
      NSString *type = call.arguments[@"type"];
      [self shareWebToWxWithTitle:title desc:desc thumbImage:thumbUrl url:url type:type];
  } else {
    result(FlutterMethodNotImplemented);
  }
}

-(void)shareWebToWxWithTitle:(NSString *)title desc:(NSString *)desc thumbImage:(NSString *)thumbImg url:(NSString *)url type:(NSString *)type{
    WXWebpageObject *webpageObject = [WXWebpageObject object];
    webpageObject.webpageUrl = url;
    
    WXMediaMessage *message = [WXMediaMessage message];
    message.title = title;
    message.description = desc;
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:thumbImg]];
    [message setThumbImage:[UIImage imageWithData:data]];
    message.mediaObject = webpageObject;
    
    SendMessageToWXReq *req = [[SendMessageToWXReq alloc] init];
    req.bText = NO;
    req.message = message;
    req.scene = [type isEqualToString:@"moment"] ? WXSceneTimeline : WXSceneSession;
    [WXApi sendReq:req];
}

- (void)shareToWechatWithName:(NSString *)name visitingCardId:(NSString *)cardId imgUrl:(NSString *)imgUrl type:(NSString *)type {
    NSString *title = [NSString stringWithFormat:@"你好，我是%@，这是我的名片",name];
    NSString *path = [NSString stringWithFormat:@"pages/personal_card/card?visitingCardId=%@",cardId];
    WXMiniProgramObject *wxMiniObject = [[WXMiniProgramObject alloc]init];
    wxMiniObject.webpageUrl = @"https://api-test-c.wabgxiaobao.co/visiting-card/error";
    wxMiniObject.userName = @"gh_d2b176e76ef5";
    wxMiniObject.path = path;
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:imgUrl]];
    UIImage *img = [UIImage imageWithData:data];
    wxMiniObject.hdImageData = [self reSizeImageData:img maxImageSize:500 maxFileSizeWithKB:100];
    wxMiniObject.miniProgramType = [type isEqualToString:@"release"] ? WXMiniProgramTypeRelease : WXMiniProgramTypePreview;
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


- (NSData *)reSizeImageData:(UIImage *)sourceImage maxImageSize:(CGFloat)maxImageSize maxFileSizeWithKB:(CGFloat)maxFileSize
{
    
    if (maxFileSize <= 0.0)  maxFileSize = 1024.0;
    if (maxImageSize <= 0.0) maxImageSize = 1024.0;
    
    //先调整分辨率
    CGSize newSize = CGSizeMake(sourceImage.size.width, sourceImage.size.height);
    
    CGFloat tempHeight = newSize.height / maxImageSize;
    CGFloat tempWidth = newSize.width / maxImageSize;
    
    if (tempWidth > 1.0 && tempWidth > tempHeight) {
        newSize = CGSizeMake(sourceImage.size.width / tempWidth, sourceImage.size.height / tempWidth);
    }
    else if (tempHeight > 1.0 && tempWidth < tempHeight){
        newSize = CGSizeMake(sourceImage.size.width / tempHeight, sourceImage.size.height / tempHeight);
    }
    
    UIGraphicsBeginImageContext(newSize);
    [sourceImage drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //调整大小
    NSData *imageData = UIImageJPEGRepresentation(newImage,1.0);
    CGFloat sizeOriginKB = imageData.length / 1024.0;
    
    CGFloat resizeRate = 0.9;
    while (sizeOriginKB > maxFileSize && resizeRate > 0.1) {
        imageData = UIImageJPEGRepresentation(newImage,resizeRate);
        sizeOriginKB = imageData.length / 1024.0;
        resizeRate -= 0.1;
    }
    
    return imageData;
}


@end
