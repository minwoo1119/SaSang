import 'dart:io';

const _baselinePath = 'tool/design_style_baseline.txt';
const _exceptionMarker = 'sasang-design-exception:';
const _tokenDefinitionFiles = {'lib/core/theme/sasang_theme.dart'};

final _rules = <_Rule>[
  _Rule('raw-color', RegExp(r'\bColor\(0x[0-9A-Fa-f]{8}\)')),
  _Rule(
    'named-color',
    RegExp(r'\b(?:Colors|CupertinoColors)\.[A-Za-z][A-Za-z0-9_]*'),
  ),
  _Rule(
    'literal-radius',
    RegExp(
      r'\b(?:BorderRadius|Radius)\.circular\(\s*-?(?:\d+(?:\.\d+)?|\.\d+)',
    ),
  ),
  _Rule('inline-shadow', RegExp(r'\bBoxShadow\s*\(')),
  _Rule(
    'literal-font-size',
    RegExp(r'\bfontSize:\s*-?(?:\d+(?:\.\d+)?|\.\d+)'),
  ),
  _Rule(
    'literal-gap',
    RegExp(
      r'\bSizedBox\([\s\S]{0,120}?(?:height|width):\s*-?(?:\d+(?:\.\d+)?|\.\d+)',
    ),
  ),
  _Rule(
    'literal-inset',
    RegExp(r'\bEdgeInsets\.(?:all|only|symmetric|fromLTRB)\([\s\S]{0,240}?\)'),
    predicate: (value) =>
        RegExp(r'(^|[^A-Za-z_])(?:\d+(?:\.\d+)?|\.\d+)').hasMatch(value),
  ),
  _Rule('literal-motion', RegExp(r'\bDuration\(milliseconds:\s*\d+\)')),
];

void main(List<String> arguments) {
  final updateBaseline = arguments.contains('--update-baseline');
  final findings = _collectFindings();
  final entries = findings.map((finding) => finding.entry).toList()..sort();

  if (updateBaseline) {
    _writeBaseline(entries);
    stdout.writeln(
      'Updated $_baselinePath with ${entries.length} existing style findings.',
    );
    return;
  }

  final baselineFile = File(_baselinePath);
  if (!baselineFile.existsSync()) {
    stderr.writeln(
      'Missing $_baselinePath. Run '
      '`dart run tool/check_design_style.dart --update-baseline` and review it.',
    );
    exitCode = 2;
    return;
  }

  final baseline = baselineFile
      .readAsLinesSync()
      .where((line) => line.isNotEmpty && !line.startsWith('#'))
      .toList();
  final remainingBaseline = <String, int>{};
  for (final entry in baseline) {
    remainingBaseline.update(entry, (count) => count + 1, ifAbsent: () => 1);
  }

  final newFindings = <_Finding>[];
  for (final finding in findings) {
    final count = remainingBaseline[finding.entry] ?? 0;
    if (count == 0) {
      newFindings.add(finding);
    } else if (count == 1) {
      remainingBaseline.remove(finding.entry);
    } else {
      remainingBaseline[finding.entry] = count - 1;
    }
  }

  if (newFindings.isEmpty) {
    stdout.writeln(
      'Design style guard passed. ${entries.length} legacy findings remain '
      'within the reviewed baseline.',
    );
    return;
  }

  stderr.writeln(
    'Design style guard found ${newFindings.length} new raw style(s):',
  );
  for (final finding in newFindings) {
    stderr.writeln(
      '  ${finding.path}:${finding.line} [${finding.rule}] ${finding.preview}',
    );
  }
  stderr.writeln('Use an existing SasangSemantic* token or shared component.');
  stderr.writeln(
    'For a justified exception, add `// $_exceptionMarker <reason>` on the '
    'same or immediately preceding line.',
  );
  stderr.writeln(
    'Only update the baseline when the PR explicitly reviews a new legacy '
    'baseline; do not update it merely to make CI pass.',
  );
  exitCode = 1;
}

List<_Finding> _collectFindings() {
  final files =
      Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList()
        ..sort((left, right) => left.path.compareTo(right.path));
  final findings = <_Finding>[];

  for (final file in files) {
    final path = file.path.replaceAll('\\', '/');
    if (_tokenDefinitionFiles.contains(path) || path.endsWith('.g.dart')) {
      continue;
    }
    final source = file.readAsStringSync();
    final lineStarts = <int>[0];
    for (var index = 0; index < source.length; index += 1) {
      if (source.codeUnitAt(index) == 10) lineStarts.add(index + 1);
    }
    final lines = source.split('\n');

    for (final rule in _rules) {
      for (final match in rule.pattern.allMatches(source)) {
        final value = match.group(0)!;
        if (!rule.accepts(value)) continue;
        final lineIndex = _lineIndexFor(match.start, lineStarts);
        if (_hasValidException(lines, lineIndex)) continue;
        final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
        findings.add(
          _Finding(
            path: path,
            line: lineIndex + 1,
            rule: rule.name,
            normalized: normalized,
          ),
        );
      }
    }
  }
  return findings;
}

int _lineIndexFor(int offset, List<int> lineStarts) {
  var low = 0;
  var high = lineStarts.length - 1;
  while (low <= high) {
    final middle = (low + high) >> 1;
    if (lineStarts[middle] <= offset) {
      low = middle + 1;
    } else {
      high = middle - 1;
    }
  }
  return high;
}

bool _hasValidException(List<String> lines, int lineIndex) {
  for (final index in [lineIndex, lineIndex - 1]) {
    if (index < 0 || index >= lines.length) continue;
    final markerIndex = lines[index].indexOf(_exceptionMarker);
    if (markerIndex < 0) continue;
    final reason = lines[index]
        .substring(markerIndex + _exceptionMarker.length)
        .trim();
    if (reason.length < 8) {
      stderr.writeln(
        'Invalid design exception at line ${index + 1}: add a concrete reason.',
      );
      exitCode = 1;
      return false;
    }
    return true;
  }
  return false;
}

void _writeBaseline(List<String> entries) {
  final file = File(_baselinePath)..parent.createSync(recursive: true);
  file.writeAsStringSync(
    '# Sasang design style legacy baseline.\n'
    '# Generated by tool/check_design_style.dart.\n'
    '# Removing entries is encouraged. Adding entries requires explicit UI review.\n'
    '${entries.join('\n')}\n',
  );
}

class _Rule {
  const _Rule(this.name, this.pattern, {this.predicate});

  final String name;
  final RegExp pattern;
  final bool Function(String value)? predicate;

  bool accepts(String value) => predicate?.call(value) ?? true;
}

class _Finding {
  const _Finding({
    required this.path,
    required this.line,
    required this.rule,
    required this.normalized,
  });

  final String path;
  final int line;
  final String rule;
  final String normalized;

  String get entry => '$path|$rule|$normalized';
  String get preview => normalized.length <= 100
      ? normalized
      : '${normalized.substring(0, 97)}...';
}
