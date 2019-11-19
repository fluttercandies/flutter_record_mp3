package com.plugin.record_mp3.record;

import android.media.AudioRecord;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.util.Log;

import com.czt.mp3recorder.util.LameUtil;
import com.plugin.record_mp3.record.port.RecordListener;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.CountDownLatch;


/**
 * 边录边转
 */
public class DataEncodeThread extends Thread implements AudioRecord.OnRecordPositionUpdateListener {
    public static final int PROCESS_STOP = 1;
    public static final int PROCESS_BREAK = 2;
    private StopHandler mHandler;
    private byte[] mMp3Buffer;
    private FileOutputStream mFileOutputStream;
    private File mFile;

    private CountDownLatch mHandlerInitLatch = new CountDownLatch(1);

    private RecordListener listener;


    /**
     * @author buihong_ha
     * @see <a>https://groups.google.com/forum/?fromgroups=#!msg/android-developers/1aPZXZG6kWk/lIYDavGYn5UJ</a>
     */
    class StopHandler extends Handler {

        WeakReference<DataEncodeThread> encodeThread;

        public StopHandler(DataEncodeThread encodeThread) {
            this.encodeThread = new WeakReference<>(encodeThread);
        }

        @Override
        public void handleMessage(Message msg) {
            if (msg.what == PROCESS_STOP || msg.what == PROCESS_BREAK) {
                DataEncodeThread threadRef = encodeThread.get();
                if (threadRef != null) {
                    //处理缓冲区中的数据
                    while (threadRef.processData() > 0) ;
                    // Cancel any event left in the queue
                    removeCallbacksAndMessages(null);
                    threadRef.flushAndRelease();
                    getLooper().quit();
                    if (msg.what == PROCESS_STOP) {
                        if (listener != null)
                            listener.onComplete();
                    } else {
                        deleteFile();
                    }
                }
            }
            if (msg.what == RecordMsg.MSG_IO_EXCEPTION) {
                if (listener != null)
                    listener.onIOExecption();
            }
            super.handleMessage(msg);
        }
    }


    private void deleteFile() {
        if (mFile != null) {
            mFile.deleteOnExit();
            Log.e("record", "非正常结束情况下,删除原录音文件");
        }
    }


    /**
     * Constructor
     *
     * @param file       file
     * @param bufferSize bufferSize
     * @throws FileNotFoundException file not found
     */
    public DataEncodeThread(File file, int bufferSize, RecordListener listener) throws FileNotFoundException {
        this.mFileOutputStream = new FileOutputStream(file);
        this.mFile = file;
        mMp3Buffer = new byte[(int) (7200 + (bufferSize * 2 * 1.25))];
        this.listener = listener;
    }

    @Override
    public void run() {
        Looper.prepare();
        mHandler = new StopHandler(this);
        mHandlerInitLatch.countDown();
        Looper.loop();
    }

    /**
     * Return the handler attach to this thread
     *
     * @return the handler attach to this thread
     */
    public Handler getHandler() {
        try {
            mHandlerInitLatch.await();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        return mHandler;
    }

    @Override
    public void onMarkerReached(AudioRecord recorder) {
        // Do nothing
    }

    @Override
    public void onPeriodicNotification(AudioRecord recorder) {
        processData();
    }

    /**
     * 从缓冲区中读取并处理数据，使用lame编码MP3
     *
     * @return 从缓冲区中读取的数据的长度
     * 缓冲区中没有数据时返回0
     */
    private int processData() {
        if (mTasks.size() > 0) {
            Task task = mTasks.remove(0);
            short[] buffer = task.getData();
            int readSize = task.getReadSize();
            int encodedSize = LameUtil.encode(buffer, buffer, readSize, mMp3Buffer);
            if (encodedSize > 0) {
                try {
                    mFileOutputStream.write(mMp3Buffer, 0, encodedSize);
                } catch (IOException e) {
                    mHandler.sendEmptyMessage(RecordMsg.MSG_IO_EXCEPTION);
                    Log.e("RecordMp3", "write exception");
                }
            }
            return readSize;
        }
        return 0;
    }

    /**
     * Flush all data left in lame buffer to file
     */
    private void flushAndRelease() {
        //将MP3结尾信息写入buffer中
        final int flushResult = LameUtil.flush(mMp3Buffer);
        if (flushResult > 0) {
            try {
                mFileOutputStream.write(mMp3Buffer, 0, flushResult);
            } catch (IOException e) {
                mHandler.sendEmptyMessage(RecordMsg.MSG_IO_EXCEPTION);
                e.printStackTrace();
            } finally {
                if (mFileOutputStream != null) {
                    try {
                        mFileOutputStream.close();
                    } catch (IOException e) {
                        Log.e("RecordMp3", "write exception");
                    }
                }
                LameUtil.close();
            }
        }
    }

    private List<Task> mTasks = Collections.synchronizedList(new ArrayList<Task>());

    public void addTask(short[] rawData, int readSize) {
        mTasks.add(new Task(rawData, readSize));
    }

    private class Task {
        private short[] rawData;
        private int readSize;

        public Task(short[] rawData, int readSize) {
            this.rawData = rawData.clone();
            this.readSize = readSize;
        }

        public short[] getData() {
            return rawData;
        }

        public int getReadSize() {
            return readSize;
        }
    }
}
