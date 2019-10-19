//
//  Recorder.m
//  NewGS
//
//  Created by newgs on 16/5/25.
//  Copyright © 2016年 cnmobi. All rights reserved.

#import "Recorder.h"
#import <AVFoundation/AVFoundation.h>

static const int sampeleRate = 16000;
static const int bitsPerChannel = 16;

@implementation Recorder

- (id)init
{
    self = [super init];
    if (self) {
        self.sampleRate = kNumberAudioQueueBuffers;
        self.bufferDurationSeconds = kBufferDurationSeconds;
        //设置录音的format数据
        [self setupAudioFormat:kAudioFormatLinearPCM SampleRate:sampeleRate];
        
    }
    return self;
}

// 设置录音格式
- (void) setupAudioFormat:(UInt32) inFormatID SampleRate:(int) sampeleRate {
     //重置下
    memset(&_recordFormat, 0, sizeof(_recordFormat));
    
    //采样率的意思是每秒需要采集的帧数
    _recordFormat.mSampleRate = sampeleRate;
    
     //设置通道数
    _recordFormat.mChannelsPerFrame = 1;
    
    //设置format
    _recordFormat.mFormatID = inFormatID;
    if (inFormatID == kAudioFormatLinearPCM){
        // if we want pcm, default to signed 16-bit little-endian
        _recordFormat.mChannelsPerFrame = 1;
        _recordFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
        _recordFormat.mBitsPerChannel = bitsPerChannel;
        _recordFormat.mBytesPerPacket = _recordFormat.mBytesPerFrame = (_recordFormat.mBitsPerChannel / 8) * _recordFormat.mChannelsPerFrame;
        _recordFormat.mFramesPerPacket = 1;
    }
}

// 回调函数
void inputBufferHandler(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer, const AudioTimeStamp *inStartTime,
                        UInt32 inNumPackets, const AudioStreamPacketDescription *inPacketDesc) {
    
    // __bridge_transfer告诉ARC:"嘿!ARC,这个inUserData 对象现在是一个OC对象了,我希望你来销毁它,我这里就不调用 CFRelease()来释放它了"
    // 如果使用 __bridge,就会导致内存泄漏。ARC并不知道自己应该在使 用完对象之后释放该对象,也没有人调用 CFRelease()。结果这个对象就会永远 保留在内存中
    // 需要在合适的时候释放内存 http://blog.csdn.net/xiaoluodecai/article/details/47153945 参考这个链接
    Recorder *recorder = (__bridge Recorder *)inUserData;
    if (inNumPackets > 0){
        NSData *pcmData = [[NSData alloc]initWithBytes:inBuffer->mAudioData length:inBuffer->mAudioDataByteSize];
        if (pcmData && pcmData.length > 0) {
            if (!recorder.recordQueue) {
                recorder.recordQueue = [NSMutableArray array];
            }
            [recorder.recordQueue addObject:pcmData];
        }
    }
    
    if (recorder.isRecording > 0) {
        AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
    }
}

// 开始录音
- (BOOL)startRecording {
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    //设置audio session的category
    NSError *error = nil;
    // AVAudioSessionCategoryPlayAndRecord
    BOOL ret = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    if (!ret) {
        NSLog(@"设置声音环境失败");
        return NO;
    }
    
    //启用audio session
     ret = [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
    if (!ret) {
        NSLog(@"启动失败");
        return NO;
    }
    
     //初始化音频输入队列
    AudioQueueNewInput(&_recordFormat, inputBufferHandler, (__bridge void *)(self), NULL, NULL, 0, &_audioQueue);
    
    //计算估算的缓存区大小
    UInt32 frames = (UInt32)(self.bufferDurationSeconds * (double)_recordFormat.mSampleRate);
    UInt32 bufferByteSize = frames * _recordFormat.mBytesPerFrame;
    NSLog(@"缓冲区大小:%u",(unsigned int)bufferByteSize);
    
    // 创建缓冲器
    for (int i = 0; i < kNumberAudioQueueBuffers; ++i){
        AudioQueueAllocateBuffer(_audioQueue, bufferByteSize, &_audioBuffers[i]);
        AudioQueueEnqueueBuffer(_audioQueue, _audioBuffers[i], 0, NULL);
    }
    
    // 开始录音
    AudioQueueStart(_audioQueue, NULL);
    
    self.isRecording = YES;
    return YES;
}

// 停止录音
- (void)stopRecording {
    if (_isRecording) {
        _isRecording = NO;
        AudioQueueStop(_audioQueue, true);
        AudioQueueDispose(_audioQueue, true);
    }
}

// 暂停录音
- (void)pauseRecording {
    if (_isRecording) {
        AudioQueuePause(_audioQueue);
    }
}

- (NSMutableArray *)recordQueue {
    if (!_recordQueue) {
        _recordQueue = [NSMutableArray array];
    }
    return _recordQueue;
}


@end
