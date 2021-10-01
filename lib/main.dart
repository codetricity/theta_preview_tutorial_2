import 'dart:async';

import 'package:flutter/material.dart';
import 'package:thetaf/thetaf.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamController controller = StreamController();
  bool videoRunning = false;
  var responseText = 'camera response';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Expanded(
                flex: 8,
                child: videoRunning
                    ? LivePreview(controller)
                    : Text(responseText)),
            Expanded(
                flex: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton(
                      onPressed: () async {
                        var response = await ThetaBase.get('info');
                        setState(() {
                          responseText = response;
                        });
                        print(response);
                      },
                      child: const Text('info'),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          controller.close();
                          controller = StreamController();
                          Preview.getLivePreview(
                              frames: 100, controller: controller);
                          videoRunning = true;
                        });
                      },
                      child: const Text('stream'),
                    ),
                    OutlinedButton(
                        onPressed: () {
                          Preview.stopPreview();
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
