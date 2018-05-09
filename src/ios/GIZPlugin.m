#import "GIZPlugin.h"

@implementation GIZPlugin

- (void)pluginInitialize {
    [super pluginInitialize];
    mBindDevice = nil;
    discoverWifiCommand = nil;
    discoverDeviceCommand = nil;
    scanDeviceList = @[];
}

// ----------------------------------- cordova 方法 ----------------------------------
- (void)init:(CDVInvokedUrlCommand*)command
{
    // 设置 SDK 委托
    [GizWifiSDK sharedInstance].delegate = self;
    
    // 设置 AppInfo
    NSDictionary* appInfo = @{@"appId": @"5fa1e143f0ce4c5cba05b682e833fe71", @"appSecret": @"d02788561db64b14a495f9a76f0d9e74"};
    
    // 设置要过滤的设备 productKey 列表。不过滤则直接传 nil
    NSArray *productInfo = [NSArray arrayWithObjects: @{@"productKey": @"f38e24d49d0e47a7934746171fdbf382",
                                                        @"productSecret": @"108c99829030439d876ac65ca148eb3e"}, nil];
    
    [GizWifiSDK startWithAppInfo:appInfo productInfo:productInfo cloudServiceInfo:nil autoSetDeviceDomain:NO];
    discoverWifiCommand = command;
}

- (void)userLogin:(CDVInvokedUrlCommand*)command
{
    NSString *userName = [command.arguments objectAtIndex:0];
    NSString *password = [command.arguments objectAtIndex:1];
    [[GizWifiSDK sharedInstance] userLogin:userName password:password];
    [self callback:command response:nil];
}

// 用户注册
- (void)userRegister:(CDVInvokedUrlCommand*)command
{
    NSString *username = [command.arguments objectAtIndex:0];
    NSString *password = [command.arguments objectAtIndex:1];
    NSString *code = [command.arguments objectAtIndex:2];
    NSString *type = [command.arguments objectAtIndex:3];
    GizUserAccountType accountType = GizUserNormal;
    if ([type isEqualToString:@"email"]){
        accountType = GizUserEmail;
    }
    if ([type isEqualToString:@"phone"]){
        accountType = GizUserPhone;
    }
    if ([type isEqualToString:@"normal"]){
        accountType = GizUserNormal;
    }
    [[GizWifiSDK sharedInstance] registerUser:username password:password verifyCode:code accountType:accountType];
    [self callback:command response:nil];
}

// 获取手机验证码
- (void)getSMSCode:(CDVInvokedUrlCommand*)command
{
    NSString *phone = [command.arguments objectAtIndex:0];
    [[GizWifiSDK sharedInstance] requestSendPhoneSMSCode:@"108c99829030439d876ac65ca148eb3e" phone:phone];
    [self callback:command response:nil];
}

// 匿名登录
- (void)userLoginAnonymous:(CDVInvokedUrlCommand*)command
{
    [[GizWifiSDK sharedInstance] userLoginAnonymous];
    [self callback:command response:nil];
}

// 获取绑定的设备
- (void)getBindDeviceList:(CDVInvokedUrlCommand*)command
{
    NSString *uid = [command.arguments objectAtIndex:0];
    NSString *token = [command.arguments objectAtIndex:1];
    [[GizWifiSDK sharedInstance] getBoundDevices:uid token:token];
    [self callback:command response:nil];
}

// 获取监听设备状态
- (void)getNotifyDeviceStatus:(CDVInvokedUrlCommand*)command
{
    NSDictionary *device = @{@"macAddress":mBindDevice.macAddress,@"did":mBindDevice.did,@"productKey":mBindDevice.productKey,@"ipAddress":mBindDevice.ipAddress,@"isLAN":@(mBindDevice.isLAN),@"netStatus":@(mBindDevice.netStatus),@"isBind":@(mBindDevice.isBind),@"productType":@(mBindDevice.productType),@"productName":mBindDevice.productName,@"remark":mBindDevice.remark,@"alias":mBindDevice.alias,@"isSubscribe":@(mBindDevice.isSubscribed)};
    [self callback:command response:device];
}

// 设置订阅
- (void)setSubscribe:(CDVInvokedUrlCommand*)command
{
    // NSString *isSubscribe = [command.arguments objectAtIndex:0];
    [mBindDevice setSubscribe:@"108c99829030439d876ac65ca148eb3e" subscribed:YES];
    [self callback:command response:nil];
}

// 发送控制命令
- (void) setCommand:(CDVInvokedUrlCommand*)command
{
    NSString *commandString = [command.arguments objectAtIndex:0];
    NSString *snString = [command.arguments objectAtIndex:1];
    int sn = [snString intValue];
    NSString *ResultString = [self jsonToHex: commandString];
    NSDictionary *data = @{@"binary": [self stringToByte: ResultString]};
    [mBindDevice write: data withSN:sn];
    [self callback:command response:nil];
}

// 解除绑定设备
- (void) unbindDevice:(CDVInvokedUrlCommand*)command
{
    NSString *uid = [command.arguments objectAtIndex:0];
    NSString *token = [command.arguments objectAtIndex:1];
    NSString *did = [command.arguments objectAtIndex:2];
    
    [[GizWifiSDK sharedInstance] unbindDevice:uid token:token did:did];
    [self callback:command response:nil];
}

// 绑定设备
-(void) bindDevice:(CDVInvokedUrlCommand*)command
{
    NSString *uid = [command.arguments objectAtIndex:0];
    NSString *token = [command.arguments objectAtIndex:1];
    NSString *mac = [command.arguments objectAtIndex:2];
    [[GizWifiSDK sharedInstance] bindRemoteDevice:uid token:token mac:mac productKey:@"f38e24d49d0e47a7934746171fdbf382" productSecret:@"108c99829030439d876ac65ca148eb3e" beOwner:YES];
    [self callback:command response:nil];
}

// 开启设备监听
-(void) startDeviceNotify:(CDVInvokedUrlCommand*)command
{
    if (mBindDevice != nil) {
        mBindDevice = nil;
    }
    
    NSString *mac = [command.arguments objectAtIndex:0];
    for (GizWifiDevice* dev in scanDeviceList) {
        if ([mac isEqualToString:dev.macAddress]) {
            mBindDevice = dev;
        }
    }
    
    discoverDeviceCommand = command;
    
    mBindDevice.delegate = self;
}

// ----------------------------------- cordova 方法 ----------------------------------

// ----------------------------------- 数据回调监听 ------------------------------------
// 实现系统事件通知回调
- (void)wifiSDK:(GizWifiSDK *)wifiSDK didNotifyEvent:(GizEventType)eventType eventSource:(id)eventSource eventID:(GizWifiErrorCode)eventID eventMessage: (NSString *)eventMessage {
    if(eventType == GizEventSDK) {
        // SDK发生异常的通知
        NSLog(@"SDK event happened: [%@] = %@", @(eventID), eventMessage);
    } else if(eventType == GizEventDevice) {
        // 设备连接断开时可能产生的通知
        GizWifiDevice* mDevice = (GizWifiDevice*)eventSource;
        NSLog(@"device mac %@ disconnect caused by %@", mDevice.macAddress, eventMessage);
    } else if(eventType == GizEventM2MService) {
        // M2M服务返回的异常通知
        NSLog(@"M2M domain %@ exception happened: [%@] = %@", (NSString*)eventSource, @(eventID), eventMessage);
    } else if(eventType == GizEventToken) {
        // token失效通知
        NSLog(@"token %@ expired: %@", (NSString*)eventSource, eventMessage);
    }
    NSLog(@"------------------------------------ init success -----------------------------------");
    NSDictionary *response = @{@"type":@"system",@"gizEventType":@(eventType)};
    [self keepCallback:discoverWifiCommand response:response];
}

// 登录回调
- (void)wifiSDK:(GizWifiSDK *)wifiSDK didUserLogin:(NSError *)result uid:(NSString *)uid token:(NSString *)token {
    NSDictionary *response = @{@"type":@"userLogin",@"gizEventType":@(result.code),@"uid":uid,@"token":token};
    [self keepCallback:discoverWifiCommand response:response];
}

// 注册回调
- (void)wifiSDK:(GizWifiSDK *)wifiSDK didRegisterUser:(NSError *)result uid:(NSString *)uid token:(NSString *)token {
    NSDictionary *response = @{@"type":@"userRegister",@"gizEventType":@(result.code),@"uid":uid,@"token":token};
    [self keepCallback:discoverWifiCommand response:response];
}

// 获取手机验证码回调
- (void)wifiSDK:(GizWifiSDK *)wifiSDK didRequestSendPhoneSMSCode:(NSError *)result token:(NSString *)token {
    NSDictionary *response = @{@"type":@"getSMSCode",@"gizEventType":@(result.code),@"token":token};
    [self keepCallback:discoverWifiCommand response:response];
}

// 接收设备列表变化上报pingcan
- (void)wifiSDK:(GizWifiSDK *)wifiSDK didDiscovered:(NSError *)result deviceList:(NSArray *)deviceList {
    NSMutableArray *devices = [NSMutableArray array];
    scanDeviceList = deviceList;
    for (GizWifiDevice* dev in deviceList) {
        NSDictionary *device = @{@"macAddress":dev.macAddress,@"did":dev.did,@"productKey": dev.productKey,@"ipAddress":dev.ipAddress,@"isLAN":@(dev.isLAN),@"netStatus":@(dev.netStatus),@"isBind":@(dev.isBind),@"productType":@(dev.productType),@"productName":dev.productName,@"remark":dev.remark,@"alias":dev.alias,@"isSubscribe":@(dev.isSubscribed)};
        [devices addObject:device];
    }
    NSDictionary *response = @{@"type":@"getDeviceList",@"gizEventType":@(result.code),@"deviceList": devices};
    [self keepCallback:discoverWifiCommand response:response];
}

// 解除绑定设备回调
- (void)wifiSDK:(GizWifiSDK *)wifiSDK didUnbindDevice:(NSError *)result did:(NSString *)did {
    NSDictionary *response = @{@"type":@"unbindDevice",@"gizEventType":@(result.code)};
    [self keepCallback:discoverWifiCommand response:response];
}

// 绑定设备回调
- (void)wifiSDK:(GizWifiSDK *)wifiSDK didBindDevice:(NSError *)result did:(NSString *)did {
    NSDictionary *response = @{@"type":@"bindDevice",@"gizEventType":@(result.code)};
    [self keepCallback:discoverWifiCommand response:response];
}

// 订阅回调
- (void)device:(GizWifiDevice *)device didSetSubscribe:(NSError *)result isSubscribed:(BOOL)isSubscribed {
    NSDictionary *response = @{@"type":@"setSubscribe",@"gizEventType":@(result.code)};
    [self keepCallback:discoverDeviceCommand response:response];
}

// 数据回调
- (void)device:(GizWifiDevice *)device didReceiveData:(NSError *)result data:(NSDictionary *)data withSN:(NSNumber *)sn {
    if(result.code == GIZ_SDK_SUCCESS) {
        NSLog(@"write successfully");
        if (data != nil) {
            NSData *binary = [data valueForKey:@"binary"];
            Byte *bytes = (Byte *)[binary bytes];
            NSString *dataString = [self byteToHexString: bytes];
            NSDictionary *response = @{@"type":@"write",@"gizEventType":@(result.code),@"result":[self hexToJson:dataString]};
            [self keepCallback:discoverDeviceCommand response:response];
        }
    } else {
        // 执行失败
    }
}
// ----------------------------------- 数据回调监听 ------------------------------------



// ----------------------------------- 基础方法 ------------------------------------
// keep callback
-(void)keepCallback:(CDVInvokedUrlCommand *) command response:(NSDictionary *) response
{
    CDVPluginResult *pluginResult = nil;
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary: response];
    [pluginResult setKeepCallbackAsBool:TRUE];
    //通过cordova框架中的callBackID回调至JS的回调函数上
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

// callback
-(void)callback:(CDVInvokedUrlCommand *) command response:(NSDictionary *) response
{
    CDVPluginResult *pluginResult = nil;
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary: response];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

// hex to json
- (NSData *)hexToJson:(NSString *)hexString
{
    if (!hexString || [hexString length] == 0) {
        return nil;
    }
    
    NSMutableData *hexData = [[NSMutableData alloc] initWithCapacity:8];
    NSRange range;
    if ([hexString length] %2 == 0) {
        range = NSMakeRange(0,2);
    } else {
        range = NSMakeRange(0,1);
    }
    for (NSInteger i = range.location; i < [hexString length]; i += 2) {
        unsigned int anInt;
        NSString *hexCharStr = [hexString substringWithRange:range];
        NSScanner *scanner = [[NSScanner alloc] initWithString:hexCharStr];
        
        [scanner scanHexInt:&anInt];
        NSData *entity = [[NSData alloc] initWithBytes:&anInt length:1];
        [hexData appendData:entity];
        
        range.location += range.length;
        range.length = 2;
    }
    
    return hexData;
}

// 16进制转byte
-(NSData*)stringToByte:(NSString*)string
{
    NSString *hexString=[[string uppercaseString] stringByReplacingOccurrencesOfString:@" " withString:@""];
    if ([hexString length]%2!=0) {
        return nil;
    }
    Byte tempbyt[1]={0};
    NSMutableData* bytes=[NSMutableData data];
    for(int i=0;i<[hexString length];i++)
    {
        unichar hex_char1 = [hexString characterAtIndex:i]; ////两位16进制数中的第一位(高位*16)
        int int_ch1;
        if(hex_char1 >= '0' && hex_char1 <='9')
            int_ch1 = (hex_char1-48)*16;   //// 0 的Ascll - 48
        else if(hex_char1 >= 'A' && hex_char1 <='F')
            int_ch1 = (hex_char1-55)*16; //// A 的Ascll - 65
        else
            return nil;
        i++;
        
        unichar hex_char2 = [hexString characterAtIndex:i]; ///两位16进制数中的第二位(低位)
        int int_ch2;
        if(hex_char2 >= '0' && hex_char2 <='9')
            int_ch2 = (hex_char2-48); //// 0 的Ascll - 48
        else if(hex_char2 >= 'A' && hex_char2 <='F')
            int_ch2 = hex_char2-55; //// A 的Ascll - 65
        else
            return nil;
        
        tempbyt[0] = int_ch1+int_ch2;  ///将转化后的数放入Byte数组里
        [bytes appendBytes:tempbyt length:1];
    }
    return bytes;
}

// 字符串转16进制
-(NSString *)jsonToHex:(NSString *)string
{
    NSData *myD = [string dataUsingEncoding:NSUTF8StringEncoding];
    Byte *bytes = (Byte *)[myD bytes];
    NSString *hexStr=@"";
    
    for(int i=0;i<[myD length];i++)
    {
        NSString *newHexStr = [NSString stringWithFormat:@"%x",bytes[i]&0xff];///16进制数
        if([newHexStr length]==1)
            hexStr = [NSString stringWithFormat:@"%@0%@",hexStr,newHexStr];
        else
            hexStr = [NSString stringWithFormat:@"%@%@",hexStr,newHexStr];
    }
    NSString *headerString = @"dccd0202";
    long hexStringInt = [hexStr length]/2;
    NSString *hexStringLen = [self ToHex:hexStringInt];
    for (int i = 8; i > [hexStringLen length]; i--) {
        headerString = [NSString stringWithFormat:@"%@%@", headerString, @"0" ];
    }
    if([hexStringLen length]==1 || [hexStringLen length]==3 || [hexStringLen length]==5 || [hexStringLen length]==7) {
        hexStringLen = [NSString stringWithFormat:@"%@%@",@"0", hexStringLen];
    }
    headerString = [NSString stringWithFormat:@"%@%@",headerString, hexStringLen];
    hexStr = [NSString stringWithFormat:@"%@%@",headerString, hexStr];
    return hexStr;
}

// 10进制转16进制
- (NSString *)ToHex:(long)tmpid
{
    NSString *nLetterValue;
    NSString *str = @"";
    int ttmpig;
    for (int i =0; i<9; i++) {
        ttmpig=tmpid%16;
        tmpid=tmpid/16;
        switch (ttmpig)
        {
            case 10:
                nLetterValue =@"A";break;
            case 11:
                nLetterValue =@"B";break;
            case 12:
                nLetterValue =@"C";break;
            case 13:
                nLetterValue =@"D";break;
            case 14:
                nLetterValue =@"E";break;
            case 15:
                nLetterValue =@"F";break;
            default:nLetterValue=[[NSString alloc]initWithFormat:@"%i",ttmpig];
                
        }
        str = [nLetterValue stringByAppendingString:str];
        if (tmpid == 0) {
            break;
        }
    }
    return str;
}

// byte to hex
-(NSString *)byteToHexString:(Byte *)bytes
{
    NSString *hexStr=@"";
    for(int i=0;i<sizeof(bytes);i++)
    {
        NSString *newHexStr = [NSString stringWithFormat:@"%x",bytes[i]&0xff];///16进制数

        if([newHexStr length]==1)

            hexStr = [NSString stringWithFormat:@"%@0%@",hexStr,newHexStr];

        else

            hexStr = [NSString stringWithFormat:@"%@%@",hexStr,newHexStr];
    }
    return hexStr;
}
@end
