import 'dart:async';

import 'package:flutter/services.dart';

class Wxbwechat {
  static const MethodChannel _channel =
      const MethodChannel('wxbwechat');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<String> get registerWechat async {
    final String text = await _channel.invokeMethod("register");
    return text;
  }

  static Future sendToWechat({String userName,String cardId,String headimgurl,String type}) async {
    final String text = await _channel.invokeMethod("send",{"userName":userName,"cardId":cardId,"headimgurl":headimgurl,"type":type});
    return text;
  }

  static Future sendWebToWechat({String title,String desc,String thumbUrl,String url,String type}) async {
    final String text = await _channel.invokeMethod("shareweb",{"title":title,"desc":desc,"thumbUrl":thumbUrl,"url":url,"type":type});
    return text;
  }
}
