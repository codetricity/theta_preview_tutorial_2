import 'dart:async';
import 'dart:convert';
import 'get_live_preview.dart';

import 'package:http/http.dart' as http;

/// The SC2 has problems with dio, which is used for HTTP connections
/// this class uses the http package instead of dio.
/// there is a known problem with an error message when closing
/// the stream, but the application appears to work.
class Sc2Preview extends Preview {
  static http.Client client = http.Client();
  static bool keepRunning = false;

  static void stopPreview() {
    keepRunning = false;
    Future.delayed(Duration(seconds: 1), () => client.close());
  }

  static void getLivePreview(
      {int frames = 5,
      frameDelay = 34,
      required StreamController controller}) async {
    // Future<void> getLivePreview({int frames = 5, int frameDelay = 67}) async {
    Map<String, String> header = {
      'Content-Type': 'application/json; charset=utf-8',
      'X-XSRF-Protected': '1',
      'Accept': 'multipart/x-mixed-replace'
    };
    Map<String, dynamic> body = {'name': 'camera.getLivePreview'};
    Uri url = Uri.parse('http://192.168.1.1/osc/commands/execute');

    var request = http.Request('POST', url);
    request.body = jsonEncode(body);
    client.head(url, headers: header);

    http.StreamedResponse response = await client.send(request);
    Stream dataStream = response.stream;
    if (!keepRunning) {
      keepRunning = true;
    }
    getFrames(
        dataStream: dataStream,
        frames: frames,
        frameDelay: frameDelay,
        controller: controller);
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
          stopPreview();
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
                controller.add(frame);

                print('framecount $frameCount');
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
