# Record Mp3
[![pub package](https://img.shields.io/pub/v/record_mp3.svg)](https://pub.dartlang.org/packages/record_mp3)

##### Record an MP3 using the platform native API

## Depend on it
Add this to your package's pubspec.yaml file:

```
Flutter <= 1.19.x
dependencies:
  record_mp3: ^1.0.1
```


```
Flutter >=1.12.x  <2.0.0
dependencies:
  record_mp3: ^2.1.0
```

```
Flutter >=2.0.0 nullsafety
dependencies:
  record_mp3: 
  	git:
	 url:git://github.com/fluttercandies/flutter_record_mp3

dependencies:
  record_mp3: ^3.0.0

```


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

//complete record and export a record file
RecordMp3.instance.stop();

```


