package com.plugin.record_mp3;

import android.content.Context;

import com.plugin.record_mp3.record.MP3Recorder;
import com.plugin.record_mp3.record.RecordMsg;
import com.plugin.record_mp3.record.RecordStatus;
import com.plugin.record_mp3.record.port.RecordListener;

import java.io.File;

import io.flutter.Log;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * RecordMp3Plugin
 */
public class RecordMp3Plugin implements MethodCallHandler {

    private MethodChannel methodChannel;

    private MP3Recorder recorder;
    private Context context;
    private RecordListener listener;

    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
        final RecordMp3Plugin plugin = new RecordMp3Plugin(registrar);
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        switch (call.method) {
            case "start":
                String filePath = call.argument("path");
                onStartRecord(filePath);
                break;
            case "pause":
                onPauseRecord();
                break;
            case "resume":
                onResumeRecord();
                break;
            case "stop":
                onStopRecord();
                break;
        }
    }

    private RecordMp3Plugin(Registrar registrar) {
        this.context = registrar.context();
        methodChannel = new MethodChannel(registrar.messenger(), "record_mp3");
        methodChannel.setMethodCallHandler(this);

        this.listener = new RecordListener() {
            @Override
            public void onRecorderStatusChange(RecordStatus status) {
            }

            @Override
            public void onFileNotFound() {
                onErrorCallBack(RecordMsg.MSG_FILE_NOT_FOUNT, "无法创建录音文件,请查看权限及存储空间");
            }

            @Override
            public void onPermissionError() {
                onErrorCallBack(RecordMsg.MSG_PERMISSION_ERROR, "请允许麦克风权限");
            }

            @Override
            public void onComplete() {
                System.out.println("录音完成");
            }

            @Override
            public void onIOExecption() {
                onErrorCallBack(RecordMsg.MSG_IO_EXCEPTION, "无法读写录音文件,请查看存储空间");
            }

            @Override
            public void onRecordMayUsed() {
                onErrorCallBack(RecordMsg.MSG_RECORD_HAS_USED, "麦克风没有声音,请检查麦克风是否正被其它应用使用或者未开启录音权限");
            }
        };
    }


    //开启录音
    private void onStartRecord(String path) {
        Log.d("RecordMp3Plugin", "record = " + path);
        File recordFile = new File(path);
        if (recorder != null) {
            recorder.breakRecord();
            recorder.setRecordFile(recordFile);
            recorder.start();
        } else {
            recorder = new MP3Recorder(recordFile, listener);
            recorder.start();
        }
    }

    //继续录音
    private void onResumeRecord() {
        if (recorder != null) {
            recorder.resume();
        }
    }

    //暂停录音
    private void onPauseRecord() {
        if (recorder != null) {
            recorder.pause();
        }
    }

    //停止录音 并输出录音文件
    private void onStopRecord() {
        if (recorder != null) {
            recorder.stop();
        }
    }

    private void onErrorCallBack(int tag, String msg) {
        Log.d("RecordMp3Plugin", "error = " + msg);
        methodChannel.invokeMethod("onRecordError", tag, new Result() {
            @Override
            public void success(Object o) {
            }

            @Override
            public void error(String s, String s1, Object o) {
            }

            @Override
            public void notImplemented() {
            }
        });
    }
}
