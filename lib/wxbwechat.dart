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

  static Future sendToWechat({String userName,String cardId,String headimgurl}) async {
    final String text = await _channel.invokeMethod("send",{"userName":userName,"cardId":cardId,"headimgurl":headumgurl});
    return text;
  }
}
