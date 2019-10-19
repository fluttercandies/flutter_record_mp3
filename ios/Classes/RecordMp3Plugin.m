#import "RecordMp3Plugin.h"
#import <record_mp3/record_mp3-Swift.h>

@implementation RecordMp3Plugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftRecordMp3Plugin registerWithRegistrar:registrar];
}
@end
