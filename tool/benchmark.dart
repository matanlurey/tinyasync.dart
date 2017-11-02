// Copyright 2017, Google Inc.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:kilobyte/kilobyte.dart';
import 'package:io/io.dart';
import 'package:node_preamble/preamble.dart';

Future<Null> main() async {
  final benchmark = new Directory('build/benchmark');
  if (!benchmark.existsSync()) {
    stderr.writeln('Run "pub build" before executing');
    return;
  }
  final manager = new ProcessManager();
  for (final file in benchmark.listSync()) {
    if (file is File && file.path.endsWith('.js')) {
      final size = new Size(bytes: file.statSync().size);
      print('${file.path}: ${size.inKilobytes}Kb');
      final patch = new File(file.path.replaceAll('.dart.js', '.dart-node.js'));
      final preamble = getPreamble();
      patch.writeAsStringSync(
        '$preamble ${file.readAsStringSync()}',
      );
      final process = await manager.spawn('node', [patch.path]);
      await process.exitCode;
      patch.deleteSync();
    }
  }
  exit(0);
}
