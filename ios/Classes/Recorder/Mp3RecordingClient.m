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
    [self breaekRecord];
   // [recordingQueue removeAllObjects];
    BOOL success = [recorder startRecording];
    if (success) {
        NSLog(@"开始录音");
        [self createEncodeOperation];
        [opetaionQueue addOperation:encodeOperation];
    }else {
        [self breaekRecord];
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
}

-(void)breaekRecord {
    [recorder stopRecording];
    if (encodeOperation) {
        [encodeOperation removeCurrentMp3File];
        [self releaseQueue];
    }
}



- (void)resume {
    [recorder startRecording];
}

- (void)stop {
    [recorder stopRecording];
    encodeOperation.setToStopped = YES;
    [self releaseQueue];
}

- (void)pause {
    [recorder pauseRecording];
}

- (void)releaseQueue {
    [recordingQueue removeAllObjects];
    if (encodeOperation) {
        encodeOperation = nil;
    }
}

@end
