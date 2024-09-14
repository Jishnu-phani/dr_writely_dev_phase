import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:dr_writely/login/record_view.dart';

class AudioRecorderPage extends StatefulWidget {
  static String tag = 'audio_recording-page';
  @override
  _AudioRecorderPageState createState() => _AudioRecorderPageState();
}

class _AudioRecorderPageState extends State<AudioRecorderPage> {
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  bool isRecording = false;
  bool isPlaying = false;
  String recordedFilePath = '';

  @override
  void initState() {
    super.initState();
    initRecorder();
  }

  @override
  void dispose() {
    _recorder?.closeRecorder();
    _player?.closePlayer();
    super.dispose();
  }

  Future<void> initRecorder() async {
    // Check for microphone permission
    if (await Permission.microphone.request().isGranted) {
      _recorder = FlutterSoundRecorder();
      _player = FlutterSoundPlayer();

      await _recorder!.openRecorder();
      await _player!.openPlayer();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Microphone permission not granted')),
      );
    }
  }

  Future<void> startRecording() async {
    try {
      recordedFilePath = '${Directory.systemTemp.path}/audio_record.wav';
      await _recorder!.startRecorder(
        toFile: recordedFilePath,
        codec: Codec.pcm16WAV,
      );
      setState(() {
        isRecording = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting recording: $e')),
      );
    }
  }

  Future<void> stopRecording() async {
    try {
      await _recorder!.stopRecorder();
      setState(() {
        isRecording = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error stopping recording: $e')),
      );
    }
  }

  Future<void> sendFile() async {
    if (recordedFilePath.isEmpty) return;

    var uri = Uri.parse('http://172.16.128.130:5000/upload');
    var request = http.MultipartRequest('POST', uri);
    request.files.add(
      await http.MultipartFile.fromPath(
        'audio',
        recordedFilePath,
        contentType: MediaType('audio', 'wav'),
      ),
    );

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File uploaded successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File upload failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File upload failed: $e')),
      );
    }
  }

  Future<void> playAudio() async {
    if (recordedFilePath.isNotEmpty) {
      try {
        await _player!.startPlayer(
          fromURI: recordedFilePath,
          codec: Codec.pcm16WAV,
          whenFinished: () {
            setState(() {
              isPlaying = false;
            });
          },
        );
        setState(() {
          isPlaying = true;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing audio: $e')),
        );
      }
    }
  }

  Future<void> deleteFile() async {
    try {
      final file = File(recordedFilePath);
      if (await file.exists()) {
        await file.delete();
        setState(() {
          recordedFilePath = '';
          isPlaying = false; // Stop any ongoing playback
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File deleted successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting file: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Audio Recorder'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: isRecording ? stopRecording : startRecording,
              child: Text(isRecording ? 'Stop Recording' : 'Start Recording'),
            ),
            ElevatedButton(
              onPressed: isPlaying ? null : playAudio,
              child: Text('Play Audio'),
            ),
            ElevatedButton(
              onPressed: () {
                if (recordedFilePath.isNotEmpty) {
                  sendFile();
                }
                Navigator.of(context).pushNamed(RecordView.tag);
              },
              child: Text('Send to Server'),
            ),
            ElevatedButton(
              onPressed: recordedFilePath.isNotEmpty ? deleteFile : null,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red), // Red button for delete
              child: Text('Delete Recording'),
            ),
            SizedBox(height: 20),
            if (isRecording) ...[
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text('Recording in progress...'),
            ] else if (recordedFilePath.isNotEmpty) ...[
              Text('Recording complete. Ready to send or delete.'),
            ],
          ],
        ),
      ),
    );
  }
}
