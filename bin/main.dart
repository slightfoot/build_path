// @dart=2.9
import 'dart:io' show Platform;

import 'package:code_builder/code_builder.dart';
import 'package:path_parsing/path_parsing.dart';

void main(List<String> arguments) {
  if (arguments.length != 2) {
    print('Usage: ${Platform.script} <path>');
    return;
  }
  final name = arguments[0];
  final data = arguments[1];

  final builder = _PathBuilderProxy(name);
  final parser = SvgPathStringSource(data);
  final normalizer = SvgPathNormalizer();
  for (PathSegmentData seg in parser.parseSegments()) {
    normalizer.emitSegment(seg, builder);
  }
  print(builder.build().accept(DartEmitter()).toString());
}

class _PathBuilderProxy extends PathProxy {
  final String name;
  final _code = <Code>[];
  String _path;

  _PathBuilderProxy(this.name) {
    _path = '__\$$name';
    _code.addAll([
      Code('if($_path == null) {'),
      Code('$_path = Path();'),
    ]);
  }

  @override
  void moveTo(double x, double y) {
    _code.add(Code('$_path!.moveTo($x, $y);'));
  }

  @override
  void lineTo(double x, double y) {
    _code.add(Code('$_path!.lineTo($x, $y);'));
  }

  @override
  void cubicTo(
      double x1, double y1, double x2, double y2, double x3, double y3) {
    _code.add(Code('$_path!.cubicTo($x1, $y1, $x2, $y2, $x3, $y3);'));
  }

  @override
  void close() {
    _code.add(Code('$_path!.close();'));
  }

  Library build() {
    _code.addAll([
      Code('}'),
      Code('return $_path!;'),
    ]);
    return Library((b) {
      b
        ..body.addAll([
          Field((b) {
            b
              ..type = Reference('Path?')
              ..name = '$_path';
          }),
          Method((b) {
            b
              ..name = '_\$$name'
              ..body = Block((b) => b..statements.addAll(_code))
              ..returns = Reference('Path');
          }),
        ]);
    });
  }
}
