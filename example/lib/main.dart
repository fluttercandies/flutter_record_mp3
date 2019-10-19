import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record_mp3/record_mp3.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String statusText = "";

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              GestureDetector(
                child: Container(
                  width: 120.0,
                  height: 48.0,
                  decoration: BoxDecoration(color: Colors.red.shade300),
                  child: Center(
                    child: Text(
                      'start',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                onTap: () async {
                  startRecord();
                },
              ),
              GestureDetector(
                child: Container(
                  width: 120.0,
                  height: 48.0,
                  decoration: BoxDecoration(color: Colors.blue.shade300),
                  child: Center(
                    child: Text(
                      RecordMp3.instance.status == RecordStatus.PAUSE
                          ? 'resume'
                          : 'pause',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                onTap: () {
                  pauseRecord();
                },
              ),
              GestureDetector(
                child: Container(
                  width: 120.0,
                  height: 48.0,
                  decoration: BoxDecoration(color: Colors.green.shade300),
                  child: Center(
                    child: Text(
                      'stop',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                onTap: () {
                  stopRecord();
                },
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Text(
              statusText,
              style: TextStyle(color: Colors.red),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: GestureDetector(
              onTap: () {
                play();
              },
              child: RecordMp3.instance.status == RecordStatus.COMPLETE
                  ? Text(
                      "播放",
                      style: TextStyle(color: Colors.red),
                    )
                  : Container(),
            ),
          ),
        ]),
      ),
    );
  }

  Future<bool> checkPermission() async {
    Map<PermissionGroup, PermissionStatus> map = await new PermissionHandler()
        .requestPermissions(
            [PermissionGroup.storage, PermissionGroup.microphone]);
    print(map[PermissionGroup.microphone]);
    return map[PermissionGroup.microphone] == PermissionStatus.granted;
  }

  void startRecord() async {
    bool hasPermission = await checkPermission();
    if (hasPermission) {
      statusText = "正在录音中...";
      recordFilePath = await getFilePath();
      RecordMp3.instance.start(recordFilePath, (type) {
        statusText = "录音失败";
        print(type);
        setState(() {});
      });
    } else {
      statusText = "没有录音权限";
    }
    setState(() {});
  }

  void pauseRecord() {
    if (RecordMp3.instance.status == RecordStatus.PAUSE) {
      bool s = RecordMp3.instance.resume();
      if (s) {
        statusText = "正在录音中...";
        setState(() {});
      }
    } else {
      bool s = RecordMp3.instance.pause();
      if (s) {
        statusText = "录音暂停中...";
        setState(() {});
      }
    }
  }

  void stopRecord() {
    bool s = RecordMp3.instance.stop();
    if (s) {
      statusText = "录音已完成";
      setState(() {});
    }
  }

  void resumeRecord() {
    bool s = RecordMp3.instance.resume();
    if (s) {
      statusText = "正在录音中...";
      setState(() {});
    }
  }

  String recordFilePath;

  void play() {
    if (recordFilePath != null) {
      AudioPlayer audioPlayer = AudioPlayer();
      audioPlayer.play(recordFilePath, isLocal: true);
    }
  }

  int i = 0;

  Future<String> getFilePath() async {
    Directory storageDirectory = await getApplicationDocumentsDirectory();
    String sdPath = storageDirectory.path + "/record";
    var d = Directory(sdPath);
    if (!d.existsSync()) {
      d.createSync(recursive: true);
    }
    return sdPath + "/test_${i++}.mp3";
  }
}
