package com.plugin.record_mp3.record;

/**
 * Created by hujie on 16/5/25.
 */
public interface RecordMsg {

    int MSG_FILE_NOT_FOUNT = 5;
    int MSG_PERMISSION_ERROR = 10;
    int MSG_IO_EXCEPTION = 15;//读写异常
    int MSG_RECORD_HAS_USED = 20;//mic has used

    int MSG_STATUS_CHANGE = 125;
    int MSG_RECORD_COMPLETE = 135;//录音完成


}
