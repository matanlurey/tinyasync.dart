// Copyright 2017, Google Inc.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
@TestOn('browser')
library tinyasyc.test.js_runtime_test;

import 'dart:async';
import 'dart:html';

import 'package:js/js.dart';
import 'package:js/js_util.dart' as js;
import 'package:tinyasync/src/runtime/js.dart';
import 'package:test/test.dart';

void main() {
  final logs = <String>[];
  Object jsConsole;

  // Monkey-patch console.log in order to capture for tests.
  setUpAll(() {
    jsConsole = js.getProperty(window, 'console');

    js.setProperty(
      window,
      'console',
      new FakeConsole(log: allowInterop(logs.add)),
    );
  });

  // Restore console.log.
  tearDownAll(() {
    js.setProperty(window, 'console', jsConsole);
  });

  test('should log on nativePrint', () {
    nativePrint('Hello World');
    expect(logs, ['Hello World']);
  });

  test('should schedule a native microtask', () async {
    // Can't use nativeScheduleMicrotask(expectAsync0) because it triggers a:
    // > "Can't add or remove outstanding callbacks outside of test body".
    //
    // This is due to the Promise calling back outside of pkg/test's zone?
    final completer = new Completer<Null>();
    nativeScheduleMicrotask(completer.complete);
    await completer.future;
  });
}

@JS()
@anonymous
class FakeConsole {
  external factory FakeConsole({void Function(String) log});
}
