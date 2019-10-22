package com.example.wxbwechat;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import com.tencent.mm.opensdk.modelmsg.WXWebpageObject;
import com.tencent.mm.opensdk.openapi.IWXAPI;
import com.tencent.mm.opensdk.openapi.IWXAPIEventHandler;
import com.tencent.mm.opensdk.openapi.WXAPIFactory;
import com.tencent.mm.opensdk.modelbiz.WXLaunchMiniProgram;
import com.tencent.mm.opensdk.modelmsg.SendMessageToWX;
import com.tencent.mm.opensdk.modelmsg.WXMediaMessage;
import com.tencent.mm.opensdk.modelmsg.WXMiniProgramObject;


import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import android.os.Message;
import android.os.Handler;

/** WxbwechatPlugin */
public class WxbwechatPlugin implements MethodCallHandler {

  private static IWXAPI api;
  private Context context;
  private WXMediaMessage message;
  private Bitmap bitmap;
  private String kind;

  private WxbwechatPlugin(Context ctx) {
    context = ctx;
  }

  /** Plugin registration. */
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "wxbwechat");
    channel.setMethodCallHandler(new WxbwechatPlugin(registrar.context()));
//    channel.setMethodCallHandler(new WxbwechatPlugin());
  }



  @Override
  public void onMethodCall(MethodCall call, Result result) {
    if (call.method.equals("getPlatformVersion")) {
      result.success("Android " + android.os.Build.VERSION.RELEASE);
    } else if(call.method.equals("register")) {
      api = WXAPIFactory.createWXAPI(context,"wx7df4c6aef7dd5845",true);
      api.registerApp("wx7df4c6aef7dd5845");
      result.success("");
    } else if (call.method.equals("send")) {
      String name = call.argument("userName");
      String cardId = call.argument("cardId");
      String headimgurl = call.argument("headimgurl");
      String type = call.argument("type");

      sendCard(name,cardId,headimgurl,type);
    }else if (call.method.equals("shareweb")){
      String title = call.argument("title");
      String desc = call.argument("desc");
      String thumbUrl = call.argument("thumbUrl");
      String url = call.argument("url");
      String type = call.argument("type");
      shareWebToWx(title,desc,thumbUrl,url,type);
    } else{
      result.notImplemented();
    }
  }

  private Handler handler = new Handler(new Handler.Callback() {
    @Override
    public boolean handleMessage(Message osMessage) {

      SendMessageToWX.Req req = new SendMessageToWX.Req();
      int maxSize = osMessage.what==0 ? 128 : 32;

      if (bitmap != null) {
        Bitmap thumbBitmap = Bitmap.createScaledBitmap(bitmap, 200, 200, true);
        message.thumbData = bitmap2Bytes(bitmap,maxSize);
      }

      if (osMessage.what==0) {
        req.transaction = "miniProgram" + System.currentTimeMillis();

        req.scene = SendMessageToWX.Req.WXSceneSession;  // 目前只支持会话
        req.message = message;
        api.sendReq(req);
      }else{
        req.transaction = String.valueOf(System.currentTimeMillis());
        req.message =message;
        req.scene = kind.equals("moment") ? SendMessageToWX.Req.WXSceneTimeline : SendMessageToWX.Req.WXSceneSession;;
        api.sendReq(req);
      }


      return false;
    }
  });

  private void shareWebToWx(String title, String desc, final String thumbUrl, String url, String type) {
    //初始化一个WXWebpageObject，填写url
    kind = type;
    WXWebpageObject webpage = new WXWebpageObject();
    webpage.webpageUrl =url;

    message = new WXMediaMessage(webpage);
    message.title =title;
    message.description =desc;

    new Thread() {
      public void run() {
        Message osMessage = new Message();
        bitmap = GetBitmap(thumbUrl);
        osMessage.what = 1;
        handler.sendMessage(osMessage);
      }
    }.start();

//构造一个Req

  }

  private void sendCard(String name, String cardId, final String headImgurl, String type) {
    WXMiniProgramObject miniProgramObj = new WXMiniProgramObject();
    miniProgramObj.userName = "gh_d2b176e76ef5";// 小程序原始id
    miniProgramObj.webpageUrl = "https://api-test-c.wabgxiaobao.co/visiting-card/error"; // 兼容低版本的网页链接
    miniProgramObj.miniprogramType = type.equals("release") ? WXMiniProgramObject.MINIPTOGRAM_TYPE_RELEASE : WXMiniProgramObject.MINIPROGRAM_TYPE_PREVIEW; // 正式版:0，测试版:1，体验版:2

    String path = "pages/personal_card/card?visitingCardId=".concat(cardId);
    miniProgramObj.path = path; // 小程序页面路径

    message = new WXMediaMessage(miniProgramObj);
    String title = "你好，我是"+name+",这是我的名片";
    message.title = title; // 小程序消息title
    message.description = title; // 小程序消息desc
    new Thread() {
      public void run() {
        Message osMessage = new Message();
        bitmap = GetBitmap(headImgurl);
        osMessage.what = 0;
        handler.sendMessage(osMessage);
      }
    }.start();

  }

  /**
   * Bitmap转换成byte[]并且进行压缩,压缩到不大于maxkb
   * @param bitmap
   * @param
   * @return
   */
  public static byte[] bitmap2Bytes(Bitmap bitmap, int maxkb) {
    ByteArrayOutputStream output = new ByteArrayOutputStream();
    bitmap.compress(Bitmap.CompressFormat.PNG, 100, output);
    int options = 100;
    while (output.toByteArray().length > maxkb&& options != 10) {
      output.reset(); //清空output
      bitmap.compress(Bitmap.CompressFormat.JPEG, options, output);//这里压缩options%，把压缩后的数据存放到output中
      options -= 10;
    }
    return output.toByteArray();
  }


  public Bitmap GetBitmap(String url) {
    Bitmap bitmap = null;
    InputStream in = null;
    BufferedOutputStream out = null;
    try {
      in = new BufferedInputStream(new URL(url).openStream(), 1024);
      final ByteArrayOutputStream dataStream = new ByteArrayOutputStream();
      out = new BufferedOutputStream(dataStream, 1024);
      copy(in, out);
      out.flush();
      byte[] data = dataStream.toByteArray();
      bitmap = BitmapFactory.decodeByteArray(data, 0, data.length);
      return bitmap;
    } catch (IOException e) {
      e.printStackTrace();
      return null;
    }
  }

  private static void copy(InputStream in, OutputStream out) throws IOException {
    byte[] b = new byte[1024];
    int read;
    while ((read = in.read(b)) != -1) {
      out.write(b, 0, read);
    }
  }
}
