// Copyright 2017, Google Inc.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library tinyasync.src.runtime.js;

import 'package:js/js.dart';

/// Implementation of `print` in the JS runtime.
void nativePrint(String message) => _console.log(message);

@JS('console')
external _Console get _console;

@JS()
@anonymous
abstract class _Console {
  void log(String message);
}

/// Implementation of `scheduleMicrotask` in the JS runtime.
void nativeScheduleMicrotask(void Function() fn) {
  _Promise.resolve(0).then(allowInterop((_) => fn()));
}

@JS('Promise')
abstract class _Promise<T> {
  external static _Promise<T> resolve<T>(T any);

  _Promise<T> then(void Function(T result) fn);
}