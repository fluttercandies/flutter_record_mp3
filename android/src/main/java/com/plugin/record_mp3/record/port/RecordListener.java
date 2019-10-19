package com.plugin.record_mp3.record.port;


import com.plugin.record_mp3.record.RecordStatus;

/**
 * Created by hujie on 16/5/24.
 */
public interface RecordListener {

    /**
     * 录音状态变化
     * @param status
     */
    void onRecorderStatusChange(RecordStatus status);

    /**
     * 文件不存在
     */
    void onFileNotFound();

    /**
     * 权限错误
     */
    void onPermissionError();

    /**
     * 完成转码
     */
    void onComplete();

    /**
     * 可能是写入失败,内存不足
     */
    void onIOExecption();



    /**
     * 麦克风可能正在被使用
     */
    void onRecordMayUsed();
}
