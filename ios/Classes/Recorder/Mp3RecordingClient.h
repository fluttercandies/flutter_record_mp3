//
//  Mp3RecordingClient.h
//  NewGS
//
//  Created by newgs on 16/5/25.
//  Copyright © 2016年 cnmobi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Recorder.h"
#import "Mp3EncodeOperation.h"

@interface Mp3RecordingClient : NSObject {
    Recorder *recorder;
    NSMutableArray *recordingQueue;
    Mp3EncodeOperation *encodeOperation;
    NSOperationQueue *opetaionQueue;
}

@property (nonatomic, strong) NSString *currentMp3File;
@property (nonatomic, copy)  void (^onRecordError)(NSInteger);

+ (instancetype)sharedClient;

- (void)start;
- (void)resume;
- (void)stop;
- (void)pause;
- (void)releaseQueue;

@end
