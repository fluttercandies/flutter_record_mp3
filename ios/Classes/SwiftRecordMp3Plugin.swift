import Flutter
import UIKit

public class SwiftRecordMp3Plugin: NSObject, FlutterPlugin {
    
    let mp3client = Mp3RecordingClient.shared()
    var methodChannel:FlutterMethodChannel?
    public  init(registrar: FlutterPluginRegistrar) {
        super.init()
        methodChannel = FlutterMethodChannel(name: "record_mp3", binaryMessenger: registrar.messenger())
        
        registrar.addMethodCallDelegate(self, channel: methodChannel!)
        
        onRecordErrorListener()
        
    }
    
    
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        
        SwiftRecordMp3Plugin(registrar: registrar)
        
    }
    
    
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let method = call.method
        
        if method == "start" {
            let arguments = call.arguments as? Dictionary<String, Any> ?? nil
            startRecord(path: arguments?["path"] as! String)
        }
        
        if method == "resume" {
            resumeRecord()
        }
        
        if method == "stop" {
            stopRecord();
        }
        
        if method == "pause" {
            pauseRecord()
        }
        
    
        
    }
    
    
    
    //录音失败回调
    private func onRecordErrorListener(){
        mp3client?.onRecordError = { code in
            self.methodChannel?.invokeMethod("onRecordError", arguments: code)
        }
    }
    
    
    
    //开始录音
    private func startRecord(path:String) {
        mp3client?.currentMp3File = path
        mp3client?.start()
    }
    
    //继续录音
    private func resumeRecord(){
        mp3client?.resume()
    }
    
    //停止录音,并输出录音文件
    private func stopRecord() {
        mp3client?.stop()
    }
    
    //暂停
    private func pauseRecord(){
        mp3client?.pause()
    }
    
   
    
}
