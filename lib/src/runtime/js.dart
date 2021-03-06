// Copyright 2017, Google Inc.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Normally the SDK has access to "special" low-level/platform features.
///
/// We don't at the 'package: ...' level, so instead we _emulate_ the features
/// the best we can with JS-interop. In practice, this shouldn't be much worse
/// than how it is implemented in DDC or Dart2JS today.
@JS()
library tinyasync.src.runtime.js;

import 'package:js/js.dart';
import 'package:js/js_util.dart';

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

/// Implementation of `_rethrow` in the JS runtime.
void nativeRethrow(Object error, StackTrace trace) {
  setProperty(error, 'stack', trace.toString());
  // ignore: only_throw_errors
  throw error;
}

@JS('Promise')
abstract class _Promise<T> {
  external static _Promise<T> resolve<T>(T any);

  _Promise<T> then(void Function(T result) fn);
}

int setTimeout(void Function() fn, int delayMs) {
  return _setTimeout(allowInterop(fn), delayMs);
}

@JS('setTimeout')
external int _setTimeout(void Function() fn, int delayMs);

@JS('clearTimeout')
external void clearTimeout(int timeoutId);

int setInterval(void Function() fn, int delayMs) {
  return _setInterval(allowInterop(fn), delayMs);
}

@JS('setInterval')
external int _setInterval(void Function() fn, int delayMs);

@JS('clearInterval')
external void clearInterval(int timeoutId);
