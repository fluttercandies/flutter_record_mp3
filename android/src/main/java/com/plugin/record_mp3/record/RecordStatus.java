package com.plugin.record_mp3.record;

/**
 * Created by hujie on 16/5/24.
 */
public enum RecordStatus {

    IDEL,//未初始化
    START, //开始录音
    RESUME,  //重起录音
    PAUSE,  //暂停录音
    BREAK,//中断录制
    STOP,//结束录音
    COMPLETE //录音完成
}
