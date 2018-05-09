var GIZPlugin = function () {};

GIZPlugin.prototype.errorCallback = function (msg) {
  console.log('giz Callback Error: ' + msg)
}

GIZPlugin.prototype.callNative = function (name, args, successCallback, errorCallback) {
    if (errorCallback) {
        cordova.exec(successCallback, errorCallback, 'GIZPlugin', name, args)
    } else {
        cordova.exec(successCallback, this.errorCallback, 'GIZPlugin', name, args)
    }
}

GIZPlugin.prototype.init = function (successCallback, errorCallback) {
    this.callNative('init', [], successCallback, errorCallback);
}

GIZPlugin.prototype.userLogin = function (username, password, successCallback) {
    this.callNative('userLogin', [username, password], successCallback);
}

GIZPlugin.prototype.userRegister = function (username, password, code, type, successCallback) {
    this.callNative('userRegister', [username, password, code, type], successCallback);
}

GIZPlugin.prototype.getSMSCode = function (phone, successCallback) {
    this.callNative('getSMSCode', [phone], successCallback);
}

GIZPlugin.prototype.userLoginAnonymous = function (successCallback) {
    this.callNative('userLoginAnonymous', [], successCallback);
}

GIZPlugin.prototype.getBindDeviceList = function (uid, token, successCallback) {
    this.callNative('getBindDeviceList', [uid, token], successCallback);
}

GIZPlugin.prototype.setSubscribe = function (isSubscribe, successCallback) {
    this.callNative('setSubscribe', [isSubscribe], successCallback);
}

GIZPlugin.prototype.setCommand = function (command, sn, successCallback) {
    this.callNative('setCommand', [command, sn], successCallback);
}

GIZPlugin.prototype.bindDevice = function (uid, token, mac, successCallback) {
    this.callNative('bindDevice', [uid, token, mac], successCallback);
}

GIZPlugin.prototype.unbindDevice = function (uid, token, did, successCallback) {
    this.callNative('unbindDevice', [uid, token, did], successCallback);
}

GIZPlugin.prototype.startDeviceNotify = function (mac, successCallback, errorCallback) {
    this.callNative('startDeviceNotify', [mac], successCallback, errorCallback);
}

GIZPlugin.prototype.getNotifyDeviceStatus = function (successCallback, errorCallback) {
    this.callNative('getNotifyDeviceStatus', [], successCallback, errorCallback);
}

if (!window.GIZPlugin) {
  window.GIZPlugin = new GIZPlugin();
}

module.exports = new GIZPlugin()
