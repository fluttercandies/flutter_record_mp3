# Record Mp3
[![pub package](https://img.shields.io/pub/v/record_mp3.svg)](https://pub.dartlang.org/packages/record_mp3)

##### Record an MP3 using the native API
## Usage
 
 
### iOS
Make sure you add the following key to Info.plist for iOS
```
<key>NSMicrophoneUsageDescription</key>
<string>xxxxxx</string>
```
 
### Example
```
import 'package:record_mp3/record_mp3.dart';

//start record 
RecordMp3.instance.start(recordFilePath, (type) {
       // record fail callback
      });
	  
//pause record
RecordMp3.instance.pause();

//resume record
RecordMp3.instance.resume();

//stop record 
RecordMp3.instance.stop();

```


