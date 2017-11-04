// Copyright 2017, Google Inc.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:glob/glob.dart';
import 'package:kilobyte/kilobyte.dart';
import 'package:io/ansi.dart' as ansi;
import 'package:io/io.dart';
import 'package:path/path.dart' as p;
import 'package:node_preamble/preamble.dart';

Future<Null> main(List<String> args) async {
  final results = _parser.parse(args);
  if (results.rest.contains('help')) {
    stdout.writeln(_parser.usage);
    exitCode = 0;
    return;
  }
  final profile = results['profile'] as bool;
  final excludes = (results['exclude'] as List<String>).map((i) => new Glob(i));
  final inputs = (results['input'] as List<String>)
      .map((i) => new Glob(i))
      .map((g) => g.listSync())
      .expand((e) => e)
      .where((f) => !excludes.any((g) => g.matches(f.path)))
      .toList();
  if (inputs.isEmpty) {
    stderr.writeln('No inputs found. Did you run "pub build benchmark"?');
    exitCode = 1;
    return;
  }
  final manager = new ProcessManager();
  for (final File file in inputs) {
    final size = new Size(bytes: file.statSync().size);
    final name = p.basenameWithoutExtension(file.path);
    final dump = new File(_addExtension(file.path, '.info.json'));
    final out = new StringBuffer('$name');
    out.write(' ' * (40 - name.length));
    out.writeln(size);
    if (dump.existsSync()) {
      final libs = _librariesInDumpInfo(
        JSON.decode(dump.readAsStringSync()) as Map<String, Object>,
      );
      final sources = _collapsePackageUrls(
        _librariesToSources(libs),
        size.inBytes,
      )
          .toList();
      sources.sort();
      const tiny = const Size(kilobytes: 1);
      for (final source in sources.reversed.where((s) => s.size >= tiny)) {
        if (source.url.contains('async')) {
          out.write(ansi.wrapWith(' -> ${source.url}', [ansi.yellow]));
        } else if (source.url.contains('isolate')) {
          out.write(ansi.wrapWith(' -> ${source.url}', [ansi.red]));
        } else {
          out.write(' -> ${source.url}');
        }
        out.write(' ' * (40 - source.url.length - 4));
        out.writeln(source.size);
      }
    }
    final patch = _patchForNode(file);
    Process process;
    if (profile) {
      process = await manager.spawnBackground(
        'node',
        ['--inspect', patch.path],
      );
      await sharedStdIn.nextLine();
      process.kill();
    } else {
      process = await manager.spawn('node', [patch.path]);
      await process.exitCode;
    }
    patch.deleteSync();
    stdout.writeln(out);
  }
  ProcessManager.terminateStdIn();
}

final _parser = new ArgParser()
  ..addFlag(
    'profile',
    abbr: 'p',
    defaultsTo: false,
    help: 'Pause benchmarks in order to use the V8/Node profiler.',
  )
  ..addFlag(
    'dump',
    abbr: 'd',
    defaultsTo: true,
    help: 'Emits what libraries from .info.json contributed code size.',
  )
  ..addOption(
    'input',
    abbr: 'i',
    defaultsTo: 'build/benchmark/*/**.dart.js',
    allowMultiple: true,
    help: 'What pattern(s) to use to find .dart.js files.',
  )
  ..addOption(
    'exclude',
    abbr: 'e',
    defaultsTo: 'build/benchmark/packages/**',
    allowMultiple: true,
    help: 'What pattern(s) to exclude when finding .dart.js files.',
  );

final _tmpDir = Directory.systemTemp.createTempSync();

String _addExtension(String path, String addExtension) {
  return '$path$addExtension';
}

/// Returns a copy of [file] patched with a "node.js" preamble.
File _patchForNode(File file) {
  final contents = '${getPreamble()}${file.readAsStringSync()}';
  return new File(
    p.join(
      _tmpDir.path,
      '${p.basenameWithoutExtension(file.path)}.js',
    ),
  )..writeAsStringSync(contents);
}

/// Returns a map of all libraries in the dump info file, sorted by size.
Map<String, int> _librariesInDumpInfo(Map<String, dynamic> json) {
  final Map<String, Map<String, Object>> libs = json['elements']['library'];
  final results = <String, int>{};
  libs.forEach((_, Map<String, Object> info) {
    results[info['canonicalUri'] as String] = info['size'] as int;
  });
  return results;
}

Iterable<_JsSource> _librariesToSources(Map<String, int> libs) sync* {
  for (final url in libs.keys) {
    final size = libs[url];
    yield new _JsSource(size, url);
  }
}

class _JsSource implements Comparable<_JsSource> {
  final Size size;
  final String url;

  /// Creates and canonicalizes a source of Dart2JS output.
  factory _JsSource(int size, String url) {
    final uri = Uri.parse(url);
    // Replace file://....../benchmark/dir/name.dart -> name.dart (readability).
    if (uri.scheme == 'file') {
      url = p.basename(uri.path);
    }
    return new _JsSource._(new Size(bytes: size), url);
  }

  const _JsSource._(this.size, this.url);

  @override
  int compareTo(_JsSource o) => size.compareTo(o.size);

  @override
  bool operator ==(Object o) => o is _JsSource && o.url == url;

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() => '$url: $size';
}

Iterable<_JsSource> _collapsePackageUrls(
  Iterable<_JsSource> sources,
  int totalSize,
) sync* {
  var accountableSize = 0;
  final collapse = <String, List<_JsSource>>{};
  for (final source in sources) {
    accountableSize += source.size.inBytes;
    if (source.url.startsWith('package:')) {
      final uri = Uri.parse(source.url);
      collapse.putIfAbsent(uri.pathSegments.first, () => []).add(source);
    } else {
      yield source;
    }
  }
  for (final package in collapse.keys) {
    final sources = collapse[package];
    yield new _JsSource(
      sources.map((s) => s.size.inBytes).fold(0, (a, b) => a + b),
      'package:$package',
    );
  }
  // Add a synthetic "remaining" for compiler-only size (not from a library).
  yield new _JsSource(
    totalSize - accountableSize,
    'compiler:dart2js',
  );
}
