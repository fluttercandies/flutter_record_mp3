import 'dart:async';

import 'package:flutter/services.dart';

class RecordMp3 {
  static final RecordMp3 _instance = RecordMp3._();

  static RecordMp3 get instance => _instance;

  RecordStatus _status = RecordStatus.IDEL;

  RecordStatus get status => _status;

  late MethodChannel _channel;

  ///record fail callback
  Function(RecordErrorType)? _onRecordError;

  RecordMp3._() {
    _channel = const MethodChannel('record_mp3');
    _channel.setMethodCallHandler(_methodCallHandler);
  }

  ///record fail handler from native
  Future<dynamic> _methodCallHandler(MethodCall call) async {
    if (call.method == "onRecordError") {
      _status = RecordStatus.IDEL;
      if (_onRecordError != null) {
        int errorCode = call.arguments;
        RecordErrorType type = RecordErrorType.UNKNOW_ERROR;
        if (errorCode == 5) {
          type = RecordErrorType.FILE_NOT_FOUNT;
        } else if (errorCode == 10) {
          type = RecordErrorType.PERMISSION_ERROR;
        } else if (errorCode == 15) {
          type = RecordErrorType.IO_EXCEPTION;
        } else if (errorCode == 20) {
          type = RecordErrorType.RECORD_HAS_USED;
        }
        _onRecordError?.call(type);
      }
    }
  }

  ///start record
  bool start(String path, Function(RecordErrorType) onRecordError) {
    _onRecordError = onRecordError;
    _status = RecordStatus.RECORDING;
    _channel.invokeMethod("start", {'path': path});
    return true;
  }

  ///pause record
  bool pause() {
    if (_status == RecordStatus.RECORDING) {
      _status = RecordStatus.PAUSE;
      _channel.invokeMethod("pause");
      return true;
    }
    return false;
  }

  ///stop record and export a record file
  bool stop() {
    if (_status == RecordStatus.RECORDING || _status == RecordStatus.PAUSE) {
      _onRecordError = null;
      _status = RecordStatus.IDEL;
      _channel.invokeMethod("stop");
      return true;
    }
    return false;
  }

  ///resume record
  bool resume() {
    if (_status == RecordStatus.PAUSE) {
      _status = RecordStatus.RECORDING;
      _channel.invokeMethod("resume");
      return true;
    }
    return false;
  }
}

///record status
enum RecordStatus {
  IDEL,
  RECORDING,
  PAUSE,
  // COMPLETE,
  // ERROR,
}

//record fail type
enum RecordErrorType {
  FILE_NOT_FOUNT, //(Android)
  PERMISSION_ERROR, //(Android,IOS)
  IO_EXCEPTION, //(Android,IOS)
  RECORD_HAS_USED, //(Android,IOS)
  UNKNOW_ERROR, //(Android)
}
