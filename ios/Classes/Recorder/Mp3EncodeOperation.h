//
//  Mp3EncodeOperation.h
//  NewGS
//
//  Created by newgs on 16/5/25.
//  Copyright © 2016年 cnmobi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Mp3EncodeOperation : NSOperation

@property (nonatomic, assign) BOOL setToStopped ;

@property (nonatomic, assign) NSMutableArray *recordQueue;
@property (nonatomic, strong) NSString *currentMp3File;
@property (nonatomic, copy)  void (^onRecordError)(NSInteger);



@end
