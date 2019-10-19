//
//  Mp3EncodeOperation.m
//  NewGS
//
//  Created by newgs on 16/5/25.
//  Copyright © 2016年 cnmobi. All rights reserved.
//

#import "Mp3EncodeOperation.h"
#import "lame.h"

// GLobal var
lame_t lame;

@implementation Mp3EncodeOperation

- (void)main {
    if (!_currentMp3File) {
        NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        _currentMp3File = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp3", [NSDate date]]];
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:_currentMp3File]) {
        [[NSFileManager defaultManager] createFileAtPath:_currentMp3File contents:[@"" dataUsingEncoding:NSASCIIStringEncoding] attributes:nil];
    }
    
    NSFileHandle *handle = [NSFileHandle fileHandleForUpdatingAtPath:_currentMp3File];
    [handle seekToEndOfFile];
    
    // lame param init
    lame = lame_init();
    lame_set_num_channels(lame, 1);
    lame_set_in_samplerate(lame, 16000);
    lame_set_brate(lame, 128);
    lame_set_mode(lame, 1);
    lame_set_quality(lame, 2);
    lame_init_params(lame);
    
    while (true) {
        NSData *audioData = nil;
        // @synchronized 的作用是创建一个互斥锁，保证此时没有其它线程对self对象进行修改。这个是objective-c的一个锁定令牌，防止self对象在同一时间内被其它线程访问，起到线程的保护作用。 一般在公用变量的时候使用，如单例模式或者操作类的static变量中使
        @synchronized(_recordQueue){
            if (_recordQueue.count > 0) {
                audioData = [_recordQueue objectAtIndex:0];
                [_recordQueue removeObjectAtIndex:0];
            }
        }
        
        if (audioData.bytes > 0) {
            short *recordingData = (short *)audioData.bytes;
            NSUInteger pcmLen = audioData.length;
            NSUInteger nsamples = pcmLen / 2;
            
            unsigned char buffer[pcmLen];
            @try {
                // mp3 encode
                int recvLen = lame_encode_buffer(lame, recordingData, recordingData, (int)nsamples, buffer, (int)pcmLen);
                
                if (recvLen != -1) {
                    NSData *piece = [NSData dataWithBytes:buffer length:recvLen];
                    [handle writeData:piece];
                }
            } @catch (NSException *exception) {
//                MyLog(@"exception = %@", exception);
                if(!_setToStopped) {
                    if( _onRecordError != nil) {
                        //IO_EXCEPTION
                        _onRecordError(15);
                    }
                }
            } @finally {
               
            }
        } else {
            if (_setToStopped) {
                break;
            } else {
                [NSThread sleepForTimeInterval:0.05];
            }
        }
    }
    [handle closeFile];
    lame_close(lame);
    NSLog(@"结束本次录音%@",_currentMp3File);
    if(!_setToStopped){
        [ self removeCurrentMp3File ];
    }
    
}
-(void)removeCurrentMp3File {
    if(_currentMp3File){
       [[NSFileManager defaultManager] removeItemAtPath:_currentMp3File error:nil];
        NSLog(@"非正常停止情况下删除文件");
    }
}


@end
