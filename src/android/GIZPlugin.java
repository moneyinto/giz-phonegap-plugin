package com.jieweifu.plugins.giz;

import android.content.ComponentName;
import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.util.Log;

import com.gizwits.gizwifisdk.api.GizWifiDevice;
import com.gizwits.gizwifisdk.api.GizWifiSDK;
import com.gizwits.gizwifisdk.enumration.GizEventType;
import com.gizwits.gizwifisdk.enumration.GizUserAccountType;
import com.gizwits.gizwifisdk.enumration.GizWifiErrorCode;
import com.gizwits.gizwifisdk.listener.GizWifiDeviceListener;
import com.gizwits.gizwifisdk.listener.GizWifiSDKListener;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaArgs;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ConcurrentHashMap;

public class GIZPlugin extends CordovaPlugin {
    private Context mContext;

    private static GIZPlugin instance;

    public GIZPlugin() {
        instance = this;
    }

    private CallbackContext discoverWifiCallback;

    private CallbackContext discoverDeviceCallback;

    private static GizWifiDevice mBindDevice;

    private List<GizWifiDevice> scanDeviceList;

    private String appId = "";

    private String appSecret = "";

    private String productKey = "";

    private String productSecret = "";

    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);
        mContext = cordova.getActivity().getApplicationContext();
    }

    @Override
    public boolean execute(final String action, final CordovaArgs args, final CallbackContext callbackContext) throws JSONException {
        cordova.getThreadPool().execute(new Runnable() {
            @Override
            public void run() {
                try {
                    Method method = GIZPlugin.class.getDeclaredMethod(action, CordovaArgs.class, CallbackContext.class);
                    method.invoke(GIZPlugin.this, args, callbackContext);
                } catch (Exception e) {
                    Log.e("", e.toString());
                }
            }
        });
        return true;
    }

    void init(CordovaArgs args, CallbackContext callbackContext) throws JSONException, PackageManager.NameNotFoundException {
        discoverWifiCallback = callbackContext;

        ApplicationInfo info = mContext.getPackageManager().getApplicationInfo(mContext.getPackageName(), PackageManager.GET_META_DATA);

        appId = info.metaData.getString("APP_ID") ;
        appSecret = info.metaData.getString("APP_SECRET");
        productKey = info.metaData.getString("PRODUCT_KEY");
        productSecret = info.metaData.getString("PRODUCT_SECRET");
        GizWifiSDK.sharedInstance().setListener(wifiListener);
        ConcurrentHashMap<String, String> appInfo = new ConcurrentHashMap();
        appInfo.put("appId", appId);
        appInfo.put("appSecret", appSecret);

        List<ConcurrentHashMap<String, String>> productInfo = new ArrayList();
        ConcurrentHashMap<String, String> product = new ConcurrentHashMap();
        product.put("productKey", productKey);
        product.put("productSecret", productSecret);
        productInfo.add(product);
        GizWifiSDK.sharedInstance().startWithAppInfo(mContext, appInfo, productInfo, null, false);
    }

    // 正常登录
    void userLogin(CordovaArgs args, CallbackContext callbackContext) throws JSONException {
        String username = args.getString(0);
        String password = args.getString(1);
        GizWifiSDK.sharedInstance().userLogin(username, password);
        callbackContext.success();
    }

    // 注册
    void userRegister(CordovaArgs args, CallbackContext callbackContext) throws JSONException {
        String username = args.getString(0);
        String password = args.getString(1);
        String code = args.getString(2);
        String type = args.getString(3);
        GizUserAccountType accountType = GizUserAccountType.GizUserNormal;
        if (type.equals("email")) {
            accountType = GizUserAccountType.GizUserEmail;
        } else if (type.equals("phone")) {
            accountType = GizUserAccountType.GizUserPhone;
        } else if (type.equals("normal")) {
            accountType = GizUserAccountType.GizUserNormal;
        }
        GizWifiSDK.sharedInstance().registerUser(username, password, code, accountType);
        callbackContext.success();
    }

    // 获取手机验证码
    void getSMSCode(CordovaArgs args, CallbackContext callbackContext) throws JSONException {
        String phone = args.getString(0);
        GizWifiSDK.sharedInstance().requestSendPhoneSMSCode (appSecret, phone);
        callbackContext.success();
    }

    // 匿名登录
    void userLoginAnonymous(CordovaArgs args, CallbackContext callbackContext) throws JSONException {
        GizWifiSDK.sharedInstance().userLoginAnonymous();
        callbackContext.success();
    }

    // 获取绑定的设备
    void getBindDeviceList(CordovaArgs args, CallbackContext callbackContext) throws JSONException {
        String uid = args.getString(0);
        String token = args.getString(1);
        GizWifiSDK.sharedInstance().getBoundDevices(uid, token);
        callbackContext.success();
    }

    // 获取监听设备状态
    void getNotifyDeviceStatus(CordovaArgs args, CallbackContext callbackContext) throws JSONException {
        JSONObject deviceObj = new JSONObject();
        deviceObj.put("macAddress", mBindDevice.getMacAddress());
        deviceObj.put("did", mBindDevice.getDid());
        deviceObj.put("productKey", mBindDevice.getProductKey());
        deviceObj.put("ipAddress", mBindDevice.getIPAddress());
        deviceObj.put("isLAN", mBindDevice.isLAN());
        deviceObj.put("netStatus", mBindDevice.getNetStatus());
        deviceObj.put("isBind", mBindDevice.isBind());
        deviceObj.put("productType", mBindDevice.getProductType());
        deviceObj.put("productName", mBindDevice.getProductName());
        deviceObj.put("remark", mBindDevice.getRemark());
        deviceObj.put("alias", mBindDevice.getAlias());
        deviceObj.put("isSubscribe", mBindDevice.isSubscribed());
        callbackContext.success(deviceObj);
    }

    // 设置订阅
    void setSubscribe(CordovaArgs args, CallbackContext callbackContext) throws JSONException {
        String isSubscribe = args.getString(0);
        mBindDevice.setSubscribe("",  Boolean.parseBoolean(isSubscribe));
        callbackContext.success();
    }

    // 发送控制命令
    void setCommand(CordovaArgs args, CallbackContext callbackContext) throws JSONException {
        String commandString = args.getString(0);
        Integer sn = args.getInt(1);
        ConcurrentHashMap<String, Object> command = jsonStringToByte(commandString);
        mBindDevice.write(command, sn);
        callbackContext.success();
    }

    // 解除绑定设备
    void unbindDevice(CordovaArgs args, CallbackContext callbackContext) throws JSONException {
        String uid = args.getString(0);
        String token = args.getString(1);
        String did = args.getString(2);
        GizWifiSDK.sharedInstance().unbindDevice (uid, token, did);
        callbackContext.success();
    }

    // 绑定设备
    void bindDevice(CordovaArgs args, CallbackContext callbackContext) throws JSONException {
        String uid = args.getString(0);
        String token = args.getString(1);
        String mac = args.getString(2);
        GizWifiSDK.sharedInstance().bindRemoteDevice (uid, token, mac, productKey, productSecret);
        callbackContext.success();
    }

    // 开启设备监听
    void startDeviceNotify(CordovaArgs args, CallbackContext callbackContext) throws JSONException {
        discoverDeviceCallback = callbackContext;

        if (mBindDevice != null) {
            mBindDevice = null;
        }

        String mac = args.getString(0);
        for (GizWifiDevice device: scanDeviceList) {
            if (mac.equals(device.getMacAddress())) {
                mBindDevice = device;
                mBindDevice.setListener(deviceListener);
            }
        }
    }

    // WIFI Listener
    private GizWifiSDKListener wifiListener = new GizWifiSDKListener() {
        @Override
        public void didNotifyEvent(GizEventType eventType, Object eventSource, GizWifiErrorCode eventID, String eventMessage) {
            try {
                JSONObject response = new JSONObject();
                response.put("type", "system");
                response.put("gizEventType", eventType.name());
                keepCallbackResult(discoverWifiCallback, response);
            } catch (JSONException e) {

            }
        }

        // 登录回调
        @Override
        public void didUserLogin(GizWifiErrorCode result, String uid, String token) {
            try {
                JSONObject response = new JSONObject();
                response.put("type", "userLogin");
                response.put("gizEventType", result.name());
                response.put("uid", uid);
                response.put("token", token);
                keepCallbackResult(discoverWifiCallback, response);
            } catch (JSONException e) {

            }
        }

        // 注册回调
        @Override
        public void didRegisterUser(GizWifiErrorCode result, String uid, String token) {
            try {
                JSONObject response = new JSONObject();
                response.put("type", "userRegister");
                response.put("gizEventType", result.name());
                response.put("uid", uid);
                response.put("token", token);
                keepCallbackResult(discoverWifiCallback, response);
            } catch (JSONException e) {

            }
        }

        // 获取手机验证码回调
        @Override
        public void didRequestSendPhoneSMSCode(GizWifiErrorCode result, String token) {
            try {
                JSONObject response = new JSONObject();
                response.put("type", "getSMSCode");
                response.put("gizEventType", result.name());
                response.put("token", token);
                keepCallbackResult(discoverWifiCallback, response);
            } catch (JSONException e) {

            }
        }

        // 获取设备列表回调
        @Override
        public void didDiscovered(GizWifiErrorCode result, List<GizWifiDevice> deviceList) {
            try {
                JSONObject response = new JSONObject();
                response.put("type", "getDeviceList");
                response.put("gizEventType", result.name());

                JSONArray jsonArray = new JSONArray();

                for(GizWifiDevice device: deviceList) {
                    JSONObject deviceObj = new JSONObject();
                    deviceObj.put("macAddress", device.getMacAddress());
                    deviceObj.put("did", device.getDid());
                    deviceObj.put("productKey", device.getProductKey());
                    deviceObj.put("ipAddress", device.getIPAddress());
                    deviceObj.put("isLAN", device.isLAN());
                    deviceObj.put("netStatus", device.getNetStatus());
                    deviceObj.put("isBind", device.isBind());
                    deviceObj.put("productType", device.getProductType());
                    deviceObj.put("productName", device.getProductName());
                    deviceObj.put("remark", device.getRemark());
                    deviceObj.put("alias", device.getAlias());
                    deviceObj.put("isSubscribe", device.isSubscribed());
                    jsonArray.put(deviceObj);
                }

                response.put("deviceList", jsonArray);

                scanDeviceList = deviceList;
                keepCallbackResult(discoverWifiCallback, response);
            } catch (JSONException e) {

            }
        }

        // 解除绑定设备回调
        @Override
        public void didUnbindDevice(GizWifiErrorCode result, String did) {
            try {
                JSONObject response = new JSONObject();
                response.put("type", "unbindDevice");
                response.put("gizEventType", result.name());
                keepCallbackResult(discoverWifiCallback, response);
            } catch (JSONException e) {

            }
        }

        // 绑定设备回调
        @Override
        public void didBindDevice(GizWifiErrorCode result, String did) {
            try {
                JSONObject response = new JSONObject();
                response.put("type", "bindDevice");
                response.put("gizEventType", result.name());
                keepCallbackResult(discoverWifiCallback, response);
            } catch (JSONException e) {

            }
        }
    };

    // 设备监听Listener
    private GizWifiDeviceListener deviceListener = new GizWifiDeviceListener() {
        @Override
        public void didSetSubscribe(GizWifiErrorCode result, GizWifiDevice device, boolean isSubscribed) {
            try {
                JSONObject response = new JSONObject();
                response.put("type", "setSubscribe");
                response.put("gizEventType", result.name());
                keepCallbackResult(discoverDeviceCallback, response);
            } catch (JSONException e) {

            }
        }

        @Override
        public void didReceiveData(GizWifiErrorCode result, GizWifiDevice device, ConcurrentHashMap<String, Object> dataMap, int sn) {
            try {
                if (result == GizWifiErrorCode.GIZ_SDK_SUCCESS) {
                    // 查询成功
                    if (dataMap != null && dataMap.size() > 0) {
                        if (dataMap.toString().contains("binary")) {
                            byte[] byteStrx = (byte[])dataMap.get("binary");
                            JSONObject obj = byteToJson(byteStrx);
                            JSONObject response = new JSONObject();
                            response.put("type", "write");
                            response.put("gizEventType", result.name());
                            response.put("result", obj);
                            keepCallbackResult(discoverDeviceCallback, response);
                        }
                    }
                } else {
                    // 查询失败
                    Log.i("getDeviceStatus", "fail");
                }
            } catch (JSONException e) {

            }
        }
    };

    private void keepCallbackResult(CallbackContext callbackContext, JSONObject data) {
        PluginResult result = new PluginResult(PluginResult.Status.OK, data);
        result.setKeepCallback(true);
        callbackContext.sendPluginResult(result);
    }

    private static JSONObject byteToJson(byte[] data) throws JSONException {
        int len = data.length;
        int i = 8;
        String s = "";
        while(i < len) {
            int b = data[i] & 255;
            char c = (char) b;
            s = s + String.valueOf(c);
            i ++;
            if (i == len) {
                break;
            }
        }
        return new JSONObject(s);
    }

    private static ConcurrentHashMap<String, Object> jsonStringToByte(String commandString) throws JSONException {
        String str = "dccd0202";
        int strLen = commandString.length();
        String hexLenStr = Integer.toHexString(strLen);

        for (int i = 8; i > hexLenStr.length(); i--) {
            str = str + "0";
        }

        str = str + hexLenStr;

        for (int i = 0; i < strLen; i++) {
            int ch = (int) commandString.charAt(i);
            String s4 = Integer.toHexString(ch);
            str = str + s4;
        }

        byte[] bytes = new byte[str.length() / 2];
        for (int i = 0; i < str.length() / 2; i++) {
            String subStr = str.substring(i * 2, i * 2 + 2);
            bytes[i] = (byte) Integer.parseInt(subStr, 16);
        }

        ConcurrentHashMap<String, Object> command = new ConcurrentHashMap();
        command.put("binary", bytes);
        return command;
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        instance = null;
    }
}