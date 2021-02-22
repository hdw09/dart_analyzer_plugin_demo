import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;
import 'package:test_plugin/logger/log.dart';

class MirrorChecker {
  final CompilationUnit _compilationUnit;
  String unitPath;

  MirrorChecker(this._compilationUnit) {
    unitPath = this._compilationUnit.declaredElement.source.fullName;
    mirrorLog.info("checker $unitPath");
  }

  Iterable<MirrorCheckerIssue> enumToStringErrors() {
    final visitor = _MirrorVisitor();
    visitor.unitPath = unitPath;
    _compilationUnit.accept(visitor);
    return visitor.issues;
  }
}

class _MirrorVisitor extends RecursiveAstVisitor<void> {
  String unitPath;
  final _issues = <MirrorCheckerIssue>[];

  Iterable<MirrorCheckerIssue> get issues => _issues;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    node.visitChildren(this);
    if (node.declaredElement.displayName.contains('ViewModle') &&
        !node.declaredElement.displayName.startsWith('HDW')) {
      _issues.add(
        MirrorCheckerIssue(
          plugin.AnalysisErrorSeverity.ERROR,
          plugin.AnalysisErrorType.LINT,
          node.offset,
          node.length,
          '您的模型类未添加HDW前缀',
          '可以改为HDW${node.declaredElement.displayName}',
        ),
      );
    }
  }
}

class MirrorCheckerIssue {
  final plugin.AnalysisErrorSeverity analysisErrorSeverity;
  final plugin.AnalysisErrorType analysisErrorType;
  final int offset;
  final int length;
  final String message;
  final String code;

  MirrorCheckerIssue(
    this.analysisErrorSeverity,
    this.analysisErrorType,
    this.offset,
    this.length,
    this.message,
    this.code,
  );
}
