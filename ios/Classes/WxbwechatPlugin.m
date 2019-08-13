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
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:imgUrl]];
    UIImage *img = [UIImage imageWithData:data];
    wxMiniObject.hdImageData = [self resetSizeOfImageData:img maxSize:90];
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

- (NSData *)resetSizeOfImageData:(UIImage *)sourceImage maxSize:(NSInteger)maxSize {
    
    //先判断当前质量是否满足要求，不满足再进行压缩
    __block NSData *finallImageData = UIImageJPEGRepresentation(sourceImage, 1.0);
    NSUInteger sizeOrigin   = finallImageData.length;
    NSUInteger sizeOriginKB = sizeOrigin / 1000;
    
    if (sizeOriginKB <= maxSize) {
        return finallImageData;
    }
    
    //获取原图片宽高比
    CGFloat sourceImageAspectRatio = sourceImage.size.width / sourceImage.size.height;
    //先调整分辨率
    CGSize defaultSize = CGSizeMake(1024, 1024 / sourceImageAspectRatio);
    UIImage * newImage = [self newSizeImage:defaultSize image:sourceImage];
    finallImageData    = UIImageJPEGRepresentation(newImage, 1.0);
    
    //保存压缩系数
    NSMutableArray *compressionQualityArr = [NSMutableArray array];
    CGFloat avg   = 1.0 / 250;
    CGFloat value = avg;
    for (int i = 250; i >= 1; i --) {
        value = i * avg;
        [compressionQualityArr addObject:@(value)];
    }
    
    /*
     调整大小
     说明：压缩系数数组compressionQualityArr是从大到小存储。
     */
    //思路：使用二分法搜索
    finallImageData = [self halfFuntion:compressionQualityArr image:newImage sourceData:finallImageData maxSize:maxSize];
    //如果还是未能压缩到指定大小，则进行降分辨率
    while (finallImageData.length == 0) {
        //每次降100分辨率
        CGFloat reduceWidth  = 100.0;
        CGFloat reduceHeight = 100.0 / sourceImageAspectRatio;
        if (defaultSize.width - reduceWidth <= 0 || defaultSize.height - reduceHeight <= 0) {
            break;
        }
        defaultSize = CGSizeMake(defaultSize.width - reduceWidth, defaultSize.height - reduceHeight);
        UIImage *image = [self newSizeImage:defaultSize
                                      image:[UIImage imageWithData:UIImageJPEGRepresentation(newImage, [[compressionQualityArr lastObject] floatValue])]];
        finallImageData = [self halfFuntion:compressionQualityArr image:image sourceData:UIImageJPEGRepresentation(image,1.0) maxSize:maxSize];
    }
    return finallImageData;
}

#pragma mark 调整图片分辨率/尺寸（等比例缩放）
- (UIImage *)newSizeImage:(CGSize)size image:(UIImage *)sourceImage {
    
    CGSize newSize     = CGSizeMake(sourceImage.size.width, sourceImage.size.height);
    CGFloat tempHeight = newSize.height / size.height;
    CGFloat tempWidth  = newSize.width / size.width;
    
    if (tempWidth > 1.0 && tempWidth > tempHeight) {
        newSize = CGSizeMake(sourceImage.size.width / tempWidth, sourceImage.size.height / tempWidth);
    } else if (tempHeight > 1.0 && tempWidth < tempHeight) {
        newSize = CGSizeMake(sourceImage.size.width / tempHeight, sourceImage.size.height / tempHeight);
    }
    
    UIGraphicsBeginImageContext(newSize);
    [sourceImage drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

#pragma mark 二分法
- (NSData *)halfFuntion:(NSArray *)arr image:(UIImage *)image sourceData:(NSData *)finallImageData maxSize:(NSInteger)maxSize {
    
    NSData *tempData = [NSData data];
    NSUInteger start = 0;
    NSUInteger end   = arr.count - 1;
    NSUInteger index = 0;
    NSUInteger difference = NSIntegerMax;
    
    while(start <= end) {
        index = start + (end - start) / 2;
        finallImageData = UIImageJPEGRepresentation(image, [arr[index] floatValue]);
        NSUInteger sizeOrigin   = finallImageData.length;
        NSUInteger sizeOriginKB = sizeOrigin / 1024;
        NSLog(@"当前降到的质量：%ld", (unsigned long)sizeOriginKB);
        NSLog(@"\nstart：%zd\nend：%zd\nindex：%zd\n压缩系数：%lf", start, end, (unsigned long)index, [arr[index] floatValue]);
        
        if (sizeOriginKB > maxSize) {
            start = index + 1;
        } else if (sizeOriginKB < maxSize) {
            if (maxSize - sizeOriginKB < difference) {
                difference = maxSize - sizeOriginKB;
                tempData   = finallImageData;
            }
            if (index <= 0) {
                break;
            }
            end = index - 1;
        } else {
            break;
        }
    }
    return tempData;
}

@end
