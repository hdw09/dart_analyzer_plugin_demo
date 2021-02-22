import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:test/test.dart';
import 'package:test_plugin/cli/cli_utils.dart';

void main() {
  test('Check with real files', () async {
    final files = ['${Directory.current.path}/assets_test/test1.dart'];
    final analysisContextCollection = AnalysisContextCollection(
      includedPaths: files,
      resourceProvider: PhysicalResourceProvider.INSTANCE,
    );
    final errors =
        await collectAnalyzerErrors(analysisContextCollection, files);
    print(errors);
  });
}
