import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer/src/context/context_root.dart' as analyzer;
import 'package:analyzer/dart/analysis/results.dart';
import 'package:pub_semver/pub_semver.dart';
import 'dart:async';
import 'package:analyzer_plugin/protocol/protocol_constants.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;

import 'package:test_plugin/mirror_visitor.dart';
import 'package:test_plugin/utils/map_utils.dart';

import 'logger/log.dart';

class MirrorPlugin extends ServerPlugin {
  MirrorPlugin(ResourceProvider provider) : super(provider);

  static const excludedFolders = ['.dart_tool/**'];

  var _filesFromSetPriorityFilesRequest = <String>[];

  @override
  List<String> get fileGlobsToAnalyze => <String>['**/*.dart'];

  @override
  String get name => 'Mirror Plugin';

  @override
  String get version => '0.0.6';

  @override
  bool isCompatibleWith(Version serverVersion) => true;

  @override
  void contentChanged(String path) {
    mirrorLog.info("contentChanged$path");
    AnalysisDriverGeneric driver = super.driverForPath(path);
    driver.addFile(path);
  }

  @override
  AnalysisDriverGeneric createAnalysisDriver(plugin.ContextRoot contextRoot) {
    final analysisRoot = analyzer.ContextRoot(
        contextRoot.root, contextRoot.exclude,
        pathContext: resourceProvider.pathContext)
      ..optionsFilePath = contextRoot.optionsFile;

    final contextBuilder = ContextBuilder(resourceProvider, sdkManager, null)
      ..analysisDriverScheduler = analysisDriverScheduler
      ..byteStore = byteStore
      ..performanceLog = performanceLog
      ..fileContentOverlay = fileContentOverlay;

    final dartDriver = contextBuilder.buildDriver(analysisRoot);
    runZonedGuarded(() {
      dartDriver.results.listen((analysisResult) {
        _processResult(dartDriver, analysisResult);
      });
    }, (e, stackTrace) {
      channel.sendNotification(
          plugin.PluginErrorParams(false, e.toString(), stackTrace.toString())
              .toNotification());
    });
    return dartDriver;
  }

  @override
  Future<plugin.AnalysisSetPriorityFilesResult> handleAnalysisSetPriorityFiles(
      plugin.AnalysisSetPriorityFilesParams parameters) async {
    _filesFromSetPriorityFilesRequest = parameters.files;
    _updatePriorityFiles();
    return plugin.AnalysisSetPriorityFilesResult();
  }

  void _updatePriorityFiles() {
    final filesToFullyResolve = {
      ..._filesFromSetPriorityFilesRequest,
      for (final driver2 in driverMap.values)
        ...(driver2 as AnalysisDriver).addedFiles,
    };
    final filesByDriver = <AnalysisDriverGeneric, List<String>>{};
    for (final file in filesToFullyResolve) {
      final contextRoot = contextRootContaining(file);
      if (contextRoot != null) {
        final driver = driverMap[contextRoot];
        filesByDriver.putIfAbsent(driver, () => <String>[]).add(file);
      }
    }
    filesByDriver.forEach((driver, files) => driver.priorityFiles = files);
  }

  void _processResult(
      AnalysisDriver driver, ResolvedUnitResult analysisResult) {
    try {
      if (analysisResult.unit != null &&
          analysisResult.libraryElement != null) {
        final mirrorChecker = MirrorChecker(analysisResult.unit);
        final issues = mirrorChecker.enumToStringErrors();
        mirrorLog.info("MirrorCheckerissues: $issues");
        if (issues.isNotEmpty) {
          channel.sendNotification(
            plugin.AnalysisErrorsParams(
              analysisResult.path,
              issues
                  .map((issue) => analysisErrorFor(
                      analysisResult.path, issue, analysisResult.unit))
                  .toList(),
            ).toNotification(),
          );
        } else {
          channel.sendNotification(
              plugin.AnalysisErrorsParams(analysisResult.path, [])
                  .toNotification());
        }
      } else {
        channel.sendNotification(
            plugin.AnalysisErrorsParams(analysisResult.path, [])
                .toNotification());
      }
    } on Exception catch (e, stackTrace) {
      channel.sendNotification(
          plugin.PluginErrorParams(false, e.toString(), stackTrace.toString())
              .toNotification());
    }
  }
}
