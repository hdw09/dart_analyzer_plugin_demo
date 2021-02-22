import 'dart:isolate';
import 'package:test_plugin/starter.dart'; // !! 别忘记修改pubspec.yaml中地址哦，不会找不到test_plugin的

void main(List<String> args, SendPort sendPort) {
  print("start");
  start(args, sendPort);
}
