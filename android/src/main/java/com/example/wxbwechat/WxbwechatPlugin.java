package com.example.wxbwechat;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

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

/** WxbwechatPlugin */
public class WxbwechatPlugin implements MethodCallHandler {

  private static IWXAPI api;
  private Context context;

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
      api = WXAPIFactory.createWXAPI(context,"",true);

    } else if (call.method.equals("send")) {
      String name = call.argument("userName");
      String cardId = call.argument("cardId");
      String headimgurl = call.argument("headimgurl");

      sendCard(name,cardId,headimgurl);
    }else {
      result.notImplemented();
    }
  }

  private void sendCard(String name,String cardId,String headImgurl) {
    WXMiniProgramObject miniProgramObj = new WXMiniProgramObject();
    miniProgramObj.userName = "gh_d2b176e76ef5";// 小程序原始id
    miniProgramObj.webpageUrl = "https://api-test-c.wabgxiaobao.co/visiting-card/error"; // 兼容低版本的网页链接
    miniProgramObj.miniprogramType = WXMiniProgramObject.MINIPROGRAM_TYPE_PREVIEW; // 正式版:0，测试版:1，体验版:2

    String path = "pages/personal_card/card?visitingCardId=".concat(cardId);
    miniProgramObj.path = path; // 小程序页面路径

    WXMediaMessage msg = new WXMediaMessage(miniProgramObj);
    String title = "你好，我是"+name+",这是我的名片";
    msg.title = title; // 小程序消息title
    msg.description = title; // 小程序消息desc
    msg.thumbData = getZoomBitmapBytes(GetBitmap(headImgurl),32); // 小程序消息封面图片，小于128k

    SendMessageToWX.Req req = new SendMessageToWX.Req();
    req.transaction = "miniProgram" + System.currentTimeMillis();
    req.message = msg;
    req.scene = SendMessageToWX.Req.WXSceneSession;  // 目前只支持会话
//    CardApplication.getWxApi().sendReq(req);
  }
  public byte[] convertBitmapToByteArray(final Bitmap bitmap, final boolean needRecycle) {
    ByteArrayOutputStream output = new ByteArrayOutputStream();
    bitmap.compress(Bitmap.CompressFormat.PNG, 100, output);
    if (needRecycle) {
      bitmap.recycle();
    }

    byte[] result = output.toByteArray();
    try {
      output.close();
    } catch (Exception e) {
      e.printStackTrace();
    }

    return result;
  }

  public static byte[] getZoomBitmapBytes(Bitmap srcBitmap, int desSize) {
    try {
      if (srcBitmap == null) {
        return null;
      }

      byte[] data;
      long fileSize;
      int quality = 90;
      desSize = desSize * 1024;

      int srcWidth = srcBitmap.getWidth();
      int srcHeight = srcBitmap.getHeight();
      if (srcWidth != srcHeight) {
        int squareSize = Math.min(srcWidth, srcHeight);
        int x = 0;
        int y = 0;
        if (srcWidth > squareSize) {
          x = (srcWidth - squareSize) / 2;
        }
        if (srcHeight > squareSize) {
          y = (srcWidth - squareSize) / 2;
        }
        srcBitmap = Bitmap.createBitmap(srcBitmap, x, y, squareSize, squareSize);
      }

      ByteArrayOutputStream out = new ByteArrayOutputStream();
      srcBitmap.compress(Bitmap.CompressFormat.JPEG, 100, out);
      out.flush();
      out.close();
      fileSize = out.size();

      if (fileSize <= desSize) {
        data = out.toByteArray();
        return data;
      }

      while (fileSize > desSize) {
        out = new ByteArrayOutputStream();
        srcBitmap.compress(Bitmap.CompressFormat.JPEG, quality, out);
        out.flush();
        out.close();
        fileSize = out.size();
        quality -= 10;
      }

      data = out.toByteArray();
      return data;
    } catch (IOException e) {
      e.printStackTrace();
    }
    return null;
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
