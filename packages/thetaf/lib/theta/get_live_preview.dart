import 'dart:async';

import 'package:dio/dio.dart';
import 'command.dart';

class Preview {
  static bool keepRunning = false;

  static void stopPreview() {
    keepRunning = false;
  }

  /// initiate connection to camera and get the stream
  /// this is different for Z1/V and SC2
  static void getLivePreview(
      {int frames = 5,
      frameDelay = 34,
      required StreamController controller}) async {
    Map<String, dynamic> additionalHeaders = {
      'Accept': 'multipart/x-mixed-replace'
    };

    var response = await command('getLivePreview',
        responseType: ResponseType.stream,
        additionalHeaders: additionalHeaders);

    Stream dataStream = response.data.stream;
    if (!keepRunning) {
      keepRunning = true;

      getFrames(
          dataStream: dataStream,
          frames: frames,
          frameDelay: frameDelay,
          controller: controller);
    }
  }

  /// receive a data stream from the camera
  /// parse the individual JPEG frames
  /// add each stream to the controller stream
  static void getFrames(
      {required int frames,
      required int frameDelay,
      required Stream dataStream,
      required StreamController controller}) {
    List<int> buffer = [];
    int startIndex = -1;
    int endIndex = -1;
    int frameCount = 0;

    // frame delay useful for testing SC2. milliseconds
    Stopwatch frameTimer = Stopwatch();
    frameTimer.start();
    StreamSubscription? subscription;

    subscription = dataStream.listen((chunkOfStream) {
      if (frameCount > frames && frames != -1 && keepRunning) {
        if (subscription != null) {
          subscription.cancel();
          controller.close();
        }
      }
      if (keepRunning) {
        buffer.addAll(chunkOfStream);
        // print('current chunk of stream is ${chunkOfStream.length} bytes long');

        for (var i = 1; i < chunkOfStream.length; i++) {
          if (chunkOfStream[i - 1] == 0xff && chunkOfStream[i] == 0xd8) {
            startIndex = i - 1;
          }
          if (chunkOfStream[i - 1] == 0xff && chunkOfStream[i] == 0xd9) {
            endIndex = buffer.length;
          }

          if (startIndex != -1 && endIndex != -1) {
            var frame = buffer.sublist(startIndex, endIndex);
            if (frameTimer.elapsedMilliseconds > frameDelay) {
              if (frameCount > 0) {
                if (keepRunning) {
                  controller.add(frame);
                  print('framecount $frameCount, keepRunning: $keepRunning');
                }
                frameTimer.reset();
              }

              frameCount++;
            }
            // print(frame);
            startIndex = -1;
            endIndex = -1;
            buffer = [];
          }
        }
      } // end keepRunning
    });
  }
}
