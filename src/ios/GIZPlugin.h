#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>
#import <GizWifiSDK/GizWifiSDK.h>
#import <GizWifiSDK/GizWifiDevice.h>

@interface GIZPlugin : CDVPlugin <GizWifiSDKDelegate, GizWifiDeviceDelegate> {
    GizWifiDevice *mBindDevice;
    NSArray *scanDeviceList;
    NSMutableDictionary* loginCallbacks;
    CDVInvokedUrlCommand *discoverWifiCommand;
    CDVInvokedUrlCommand *discoverDeviceCommand;
}

@property GizWifiDevice *device;

@end
