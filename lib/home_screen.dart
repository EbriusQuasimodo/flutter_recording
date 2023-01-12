import 'dart:async';
import 'dart:io' show Directory, Platform;

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isRecording = false;
  FlutterSoundRecorder _recordingSession = FlutterSoundRecorder();
  final Codec _codec = Codec.aacMP4;
  String pathToAudio = '';
  FlutterSoundPlayer playerModule = FlutterSoundPlayer();

  Future<void> initializer() async {
    Directory? tempDir;
    if (Platform.isIOS) {
      tempDir = await getApplicationDocumentsDirectory();
    } else {
      tempDir = await getExternalStorageDirectory();
    }
    pathToAudio = '${tempDir?.path}/fsound.mp4';

    _recordingSession = FlutterSoundRecorder();
    await playerModule.openPlayer();
    await _recordingSession.openRecorder();
    await Permission.microphone.request();
    await Permission.storage.request();
    await Permission.manageExternalStorage.request();
  }

  Future<void> init() async {
    await initializer();

    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.allowBluetooth |
              AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Audio Recording'),
        elevation: 0,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: FloatingActionButton(
              onPressed: () {
                _onButtonPressed(context);
              },
              backgroundColor: isRecording ? Colors.amber : Colors.blue,
              elevation: 1,
              child: const Icon(Icons.mic),
            ),
          ),
        ],
      ),
    );
  }

  Future _onButtonPressed(BuildContext context) async {
    if (isRecording == false) {
      setState(() {
        isRecording = true;
      });
      _startRecording();
    } else if (isRecording == true) {
      setState(() {
        isRecording = false;
      });
      _stopRecording();
    }
  }

  Future<void> _startRecording() async {
    _recordingSession.openRecorder();
    await _recordingSession.startRecorder(
      toFile: pathToAudio,
      codec: _codec,
    );
  }

  Future<String?> _stopRecording() async {
    _recordingSession.closeRecorder();
    await _recordingSession.stopRecorder();

    playerModule.startPlayer(
      fromURI: pathToAudio,
    );
  }
}
