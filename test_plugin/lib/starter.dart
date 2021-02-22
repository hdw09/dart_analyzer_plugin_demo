import 'dart:isolate';

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer_plugin/starter.dart';
import './mirror_plugin.dart';
import 'logger/log.dart';

void start(List<String> args, SendPort sendPort) {
  mirrorLog.info('-----------restarted-------------');
  ServerPluginStarter(MirrorPlugin(PhysicalResourceProvider.INSTANCE))
      .start(sendPort);
}
