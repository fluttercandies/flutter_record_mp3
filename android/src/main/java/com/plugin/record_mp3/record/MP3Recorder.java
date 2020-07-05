package com.plugin.record_mp3.record;

import android.media.AudioFormat;
import android.media.AudioRecord;
import android.media.MediaRecorder;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.os.Process;
import android.util.Log;

import com.czt.mp3recorder.PCMFormat;
import com.czt.mp3recorder.util.LameUtil;
import com.plugin.record_mp3.record.port.RecordListener;
import com.plugin.record_mp3.record.port.SimpleRecordListener;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;

public class MP3Recorder {
    //=======================AudioRecord Default Settings=======================
    private static final int DEFAULT_AUDIO_SOURCE = MediaRecorder.AudioSource.MIC;
    /**
     * 以下三项为默认配置参数。Google Android文档明确表明只有以下3个参数是可以在所有设备上保证支持的。
     */
    private static final int DEFAULT_SAMPLING_RATE = 44100;//模拟器仅支持从麦克风输入8kHz采样率
    private static final int DEFAULT_CHANNEL_CONFIG = AudioFormat.CHANNEL_IN_MONO;
    /**
     * 下面是对此的封装
     * private static final int DEFAULT_AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT;
     */
    private static final PCMFormat DEFAULT_AUDIO_FORMAT = PCMFormat.PCM_16BIT;

    //======================Lame Default Settings=====================
    private static final int DEFAULT_LAME_MP3_QUALITY = 4;
    /**
     * 与DEFAULT_CHANNEL_CONFIG相关，因为是mono单声，所以是1
     */
    private static final int DEFAULT_LAME_IN_CHANNEL = 1;
    /**
     * Encoded bit rate. MP3 file will be encoded with bit rate 32kbps
     */
    private static final int DEFAULT_LAME_MP3_BIT_RATE = 32;

    //==================================================================

    /**
     * 自定义 每160帧作为一个周期，通知一下需要进行编码
     */
    private static final int FRAME_COUNT = 160;
    private AudioRecord mAudioRecord = null;
    private int mBufferSize;
    private short[] mPCMBuffer;
    private DataEncodeThread mEncodeThread;
    private File mRecordFile;

    private int lastReadSize = -100;


    //初始化状态
    private RecordStatus status = RecordStatus.IDEL;
    private RecordListener listener;


    private boolean isRecording = false;


    public RecordStatus getStatus() {
        return status;
    }

    /**
     * Default constructor. Setup recorder with default sampling rate 1 channel,
     * 16 bits pcm
     *
     * @param recordFile target file
     */
    public MP3Recorder(File recordFile, RecordListener listener) {
        mRecordFile = recordFile;
        this.listener = listener;
    }

    public void setRecordFile(File recordFile) {
        mRecordFile = recordFile;
    }

    private void setRecording(boolean recording) {
        isRecording = recording;
    }

    public boolean isRecording() {
        return isRecording;
    }

    Handler handler = new Handler(Looper.getMainLooper()) {
        @Override
        public void handleMessage(Message msg) {
            if (listener == null) {
                return;
            }
            if (msg.what == RecordMsg.MSG_FILE_NOT_FOUNT) {
                listener.onFileNotFound();
            }
            if (msg.what == RecordMsg.MSG_PERMISSION_ERROR) {
                listener.onPermissionError();
            }
            if (msg.what == RecordMsg.MSG_IO_EXCEPTION) {
                listener.onIOExecption();
            }
            if (msg.what == RecordMsg.MSG_RECORD_HAS_USED) {
                listener.onRecordMayUsed();
            }
            if (msg.what == RecordMsg.MSG_STATUS_CHANGE) {
                RecordStatus status = (RecordStatus) msg.obj;
                listener.onRecorderStatusChange(status);
            }
            if (msg.what == RecordMsg.MSG_RECORD_COMPLETE) {
                listener.onComplete();
            }
        }
    };


    private void postHandler(int what) {
        handler.sendEmptyMessage(what);
    }


    /**
     * Start recording. Create an encoding thread. Start record from this
     * thread.
     *
     * @throws IOException initAudioRecorder throws
     */
    public void start() {

        if (isRecording()) {
            return;
        }
        new Thread() {
            @Override
            public void run() {
                try {
                    while (mAudioRecord != null) ;
                    initAudioRecorder();
                    mAudioRecord.startRecording();
                    setRecording(true);
                    setStatus(RecordStatus.START);
                    //设置线程权限
                    Process.setThreadPriority(Process.THREAD_PRIORITY_URGENT_AUDIO);
                    while (isRecording()) {
                        RecordStatus status = getStatus();
                        if (status == RecordStatus.PAUSE) {
                            continue;
                        }
                        int readSize = mAudioRecord.read(mPCMBuffer, 0, mBufferSize);
                        // int volume = calculateRealVolume(mPCMBuffer, readSize);
                        if (readSize <= 0) {
                            if (readSize == 0) {
                                lastReadSize++;
                            }
                            if (lastReadSize >= 0 && readSize == 0) {
                                setRecording(false);
                                lastReadSize = -100;
                                postHandler(RecordMsg.MSG_RECORD_HAS_USED);
                            }
                        } else {
                            if (mEncodeThread != null) {
                                mEncodeThread.addTask(mPCMBuffer, readSize);
                            }
                        }
                    }
                } catch (FileNotFoundException e) {
                    Log.e("RecordMp3", "Can not find record file");
                    postHandler(RecordMsg.MSG_FILE_NOT_FOUNT);
                } catch (IllegalStateException |
                        IllegalArgumentException e) {
                    Log.e("RecordMp3", "NO Record Permission");
                    postHandler(RecordMsg.MSG_PERMISSION_ERROR);
                } catch (Exception e) {
                    Log.e("RecordMp3", e + "");
                    postHandler(RecordMsg.MSG_IO_EXCEPTION);
                } finally {
                    release();
                    //如果不是停止 如终止录音 则不输出录音文件
                    if (getStatus() == RecordStatus.STOP) {
                        // stop the encoding thread and try to wait
                        // until the thread finishes its job
                        Message msg = Message.obtain(mEncodeThread.getHandler(),
                                DataEncodeThread.PROCESS_STOP);
                        msg.sendToTarget();
                    } else {
                        Message msg = Message.obtain(mEncodeThread.getHandler(),
                                DataEncodeThread.PROCESS_BREAK);
                        msg.sendToTarget();
                    }
                }
            }
        }.start();
    }

    /**
     * 此计算方法来自samsung开发范例
     *
     * @param buffer   buffer
     * @param readSize readSize
     */
    private int calculateRealVolume(short[] buffer, int readSize) {
        double sum = 0;
        for (int i = 0; i < readSize; i++) {
            // 这里没有做运算的优化，为了更加清晰的展示代码
            sum += buffer[i] * buffer[i];
        }
        if (readSize > 0) {
            double amplitude = sum / readSize;
            mVolume = (int) Math.sqrt(amplitude);
        }
        return mVolume;
    }


    private int mVolume;

    public int getVolume() {
        return mVolume;
    }

    private static final int MAX_VOLUME = 2000;

    public int getMaxVolume() {
        return MAX_VOLUME;
    }


    /**
     * Initialize audio recorder
     */
    private void initAudioRecorder() throws FileNotFoundException, IllegalArgumentException {
        mBufferSize = AudioRecord.getMinBufferSize(DEFAULT_SAMPLING_RATE,
                DEFAULT_CHANNEL_CONFIG, DEFAULT_AUDIO_FORMAT.getAudioFormat());

        int bytesPerFrame = DEFAULT_AUDIO_FORMAT.getBytesPerFrame();
        /* Get number of samples. Calculate the buffer size
         * (round up to the factor of given frame size)
         * 使能被整除，方便下面的周期性通知
         * */
        int frameSize = mBufferSize / bytesPerFrame;
        if (frameSize % FRAME_COUNT != 0) {
            frameSize += (FRAME_COUNT - frameSize % FRAME_COUNT);
            mBufferSize = frameSize * bytesPerFrame;
        }

        /* Setup audio recorder */
        mAudioRecord = new AudioRecord(DEFAULT_AUDIO_SOURCE,
                DEFAULT_SAMPLING_RATE, DEFAULT_CHANNEL_CONFIG, DEFAULT_AUDIO_FORMAT.getAudioFormat(),
                mBufferSize);

        mPCMBuffer = new short[mBufferSize];
        /*
         * Initialize lame buffer
         * mp3 sampling rate is the same as the recorded pcm sampling rate
         * The bit rate is 32kbps
         *
         */
        LameUtil.init(DEFAULT_SAMPLING_RATE, DEFAULT_LAME_IN_CHANNEL, DEFAULT_SAMPLING_RATE, DEFAULT_LAME_MP3_BIT_RATE, DEFAULT_LAME_MP3_QUALITY);
        // Create and run thread used to encode data
        // The thread will
        mEncodeThread = new DataEncodeThread(mRecordFile, mBufferSize, new SimpleRecordListener() {
            @Override
            public void onComplete() {
                setStatus(RecordStatus.COMPLETE);
                postHandler(RecordMsg.MSG_RECORD_COMPLETE);
            }

            @Override
            public void onIOExecption() {
                postHandler(RecordMsg.MSG_IO_EXCEPTION);
            }
        });
        mEncodeThread.start();
        mAudioRecord.setRecordPositionUpdateListener(mEncodeThread, mEncodeThread.getHandler());
        mAudioRecord.setPositionNotificationPeriod(FRAME_COUNT);
    }

    /**
     * 完成并输出录音文件
     */
    public void stop() {
        if (getStatus() == RecordStatus.START || getStatus() == RecordStatus.PAUSE || getStatus() == RecordStatus.RESUME) {
            setStatus(RecordStatus.STOP);
            setRecording(false);
        }
    }

    /**
     * 中断录制
     */
    public void breakRecord() {
        if (isRecording) {
            setStatus(RecordStatus.BREAK);
            setRecording(false);
        }
    }


    /**
     * 释放资源
     */
    private void release() {
        if (mAudioRecord != null) {
            try {
                mAudioRecord.stop();
                mAudioRecord.release();
                mAudioRecord = null;
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    /**
     * 暂停
     */
    public void pause() {
        if (getStatus() == RecordStatus.START || getStatus() == RecordStatus.RESUME)
            setStatus(RecordStatus.PAUSE);
    }

    /**
     * 继续
     */
    public void resume() {
        if (getStatus() == RecordStatus.PAUSE)
            setStatus(RecordStatus.RESUME);
    }


    private void setStatus(RecordStatus status) {
        this.status = status;
        Log.d("RecordMp3", "status = " + status);
        postStatusHandler(status);
    }


    private void postStatusHandler(RecordStatus status) {
        Message message = handler.obtainMessage();
        message.what = RecordMsg.MSG_STATUS_CHANGE;
        message.obj = status;
        handler.sendMessage(message);
    }


}