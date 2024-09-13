import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:http_parser/http_parser.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio Recorder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AudioRecorderPage(),
    );
  }
}

class AudioRecorderPage extends StatefulWidget {
  @override
  _AudioRecorderPageState createState() => _AudioRecorderPageState();
}

class _AudioRecorderPageState extends State<AudioRecorderPage> {
  FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool isRecording = false;
  String recordedFilePath = '';

  @override
  void initState() {
    super.initState();
    initRecorder();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    super.dispose();
  }

  Future<void> initRecorder() async {
    // Check if the microphone permission is already granted
    var status = await Permission.microphone.status;
    if (status != PermissionStatus.granted) {
      // Request the microphone permission
      status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        // Handle the case where the permission is not granted
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Microphone permission not granted')),
        );
        return;
      }
    }

    // Open the recorder if permission is granted
    await _recorder.openRecorder();
  }

  Future<void> startRecording() async {
    recordedFilePath = '${Directory.systemTemp.path}/audio_record.wav';
    await _recorder.startRecorder(
      toFile: recordedFilePath,
      codec: Codec.pcm16WAV,
    );
    setState(() {
      isRecording = true;
    });
  }

  Future<void> stopRecording() async {
    await _recorder.stopRecorder();
    setState(() {
      isRecording = false;
    });
  }

  Future<void> sendFile() async {
    if (recordedFilePath.isEmpty) return;

    var uri = Uri.parse('http://192.168.1.14:5000/upload');
    var request = http.MultipartRequest('POST', uri);
    request.files.add(
      await http.MultipartFile.fromPath(
        'audio',
        recordedFilePath,
        contentType: MediaType('audio', 'wav'),
      ),
    );

    var response = await request.send();
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('File uploaded successfully')));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('File upload failed')));
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
              onPressed: isRecording ? null : startRecording,
              child: Text('Start Recording'),
            ),
            ElevatedButton(
              onPressed: isRecording ? stopRecording : null,
              child: Text('Stop Recording'),
            ),
            ElevatedButton(
              onPressed: recordedFilePath.isNotEmpty ? sendFile : null,
              child: Text('Send to Server'),
            ),
            SizedBox(height: 20),
            if (isRecording) ...[
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text('Recording in progress...'),
            ] else if (recordedFilePath.isNotEmpty) ...[
              Text('Recording complete. Ready to send.'),
            ],
          ],
        ),
      ),
    );
  }
}
