import 'dart:async';

import 'package:flutter/material.dart';
import 'package:thetaf/thetaf.dart' as thetaf;

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final StreamController controller = StreamController();
  bool videoRunning = false;
  var responseText = 'camera response';

  @override
  Widget build(BuildContext context) {
    final preview = thetaf.Preview(controller);
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Expanded(
                flex: 8,
                child: videoRunning
                    ? thetaf.LivePreview(controller)
                    : Text(responseText)),
            Expanded(
                flex: 1,
                child: Row(
                  children: [
                    OutlinedButton(
                      onPressed: () async {
                        var response = await thetaf.ThetaBase.get('info');
                        setState(() {
                          responseText = response;
                        });
                        print(response);
                      },
                      child: const Text('info'),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        preview.getLivePreview(frames: 300);
                        setState(() {
                          videoRunning = true;
                        });
                      },
                      child: const Text('stream'),
                    ),
                    OutlinedButton(
                        onPressed: () {
                          preview.stopPreview();
                          setState(() {
                            videoRunning = false;
                          });
                        },
                        child: const Text('stop video'))
                  ],
                )),
          ],
        ),
      ),
    );
  }
}
