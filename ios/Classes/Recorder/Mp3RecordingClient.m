//
//  Mp3RecordingClient.m
//  NewGS
//
//  Created by newgs on 16/5/25.
//  Copyright © 2016年 cnmobi. All rights reserved.
//

#import "Mp3RecordingClient.h"

@implementation Mp3RecordingClient

+ (instancetype)sharedClient {
    static Mp3RecordingClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [Mp3RecordingClient new];
    });
    
    return _sharedClient;
}

- (id)init {
    self = [super init];
    if (self) {
        recordingQueue = [[NSMutableArray alloc] init];
        opetaionQueue = [[NSOperationQueue alloc] init];
        recorder = [[Recorder alloc] init];
        recorder.recordQueue = recordingQueue;
    }
    return self;
}

- (void)start {
    [self releaseQueue];
    [self deleteRecordFile];
    BOOL success = [recorder startRecording];
    if (success) {
        NSLog(@"开始录音");
        [self createEncodeOperation];
        [opetaionQueue addOperation:encodeOperation];
    }else {
        [self breakRecord];
        //可能是权限问题 具体不清楚 PERMISSION_ERROR = 10
        //也有可能是麦克风被占用？RECORD_HAS_USED = 20
        [self notifyRecordError:20];
    }
}

-(void)notifyRecordError: (NSInteger)code {
    if(_onRecordError != nil ) {
        _onRecordError(code);
    }
}

-(void)createEncodeOperation {
    
    encodeOperation = [[Mp3EncodeOperation alloc] init];
    encodeOperation.currentMp3File = self.currentMp3File;
    encodeOperation.onRecordError = self.onRecordError;
    encodeOperation.recordQueue = recordingQueue;
    lastMp3File = self.currentMp3File;
}

-(void)breakRecord {
    
    [recorder stopRecording];
    [self releaseQueue];
    [self deleteRecordFile];
}



- (void)resume {
    [recorder startRecording];
}

- (void)stop {
    lastMp3File = nil;
    [recorder stopRecording];
    [self releaseQueue];
}

- (void)pause {
    [recorder pauseRecording];
}

- (void)releaseQueue {
    [recordingQueue removeAllObjects];
    if (encodeOperation) {
        encodeOperation.setToStopped = YES;
        encodeOperation = nil;
    }
  
}


///删除上次遗留的录音文件
///可能是重新开始录音
-(void)deleteRecordFile {
    if(lastMp3File){
       [[NSFileManager defaultManager] removeItemAtPath:_currentMp3File error:nil];
        lastMp3File = nil;
        NSLog(@"删除录音文件");
    }
}


@end
