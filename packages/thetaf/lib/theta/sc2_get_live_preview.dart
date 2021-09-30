import 'dart:async';
import 'dart:convert';
import 'get_live_preview.dart';

import 'package:http/http.dart' as http;

/// The SC2 has problems with dio, which is used for HTTP connections
/// this class uses the http package instead of dio.
/// there is a known problem with an error message when closing
/// the stream, but the application appears to work.
class Sc2Preview extends Preview {
  Sc2Preview(StreamController controller) : super(controller);
  http.Client client = http.Client();

  @override
  void stopPreview() {
    super.stopPreview();
    Future.delayed(Duration(seconds: 1), () => client.close());
  }

  @override
  Future<void> getLivePreview({int frames = 5, frameDelay = 34}) async {
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
    getFrames(dataStream: dataStream, frames: frames, frameDelay: frameDelay);
  }
}
