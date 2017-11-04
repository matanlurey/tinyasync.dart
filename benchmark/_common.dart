// Copyright 2017, Google Inc.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Do not use dart:async in this library, it is compiled to JS.
@JS()
library tinyasync.benchmark.common;

import 'package:js/js.dart';

@JS('console.profile')
external void _profile(String name);

@JS('console.profileEnd')
external void _profileEnd(String name);

/// Runs the provided callback [run] [times].
///
/// The provided callback to [run] should be invoked when the action is done:
/// ```dart
/// benchAsync((onDone) {
///   doAsyncThing(() => onDone());
/// });
/// ```
void benchAsync(
  String name,
  void Function(void Function() onDone) run, {
  int times: 1000,
}) {
  void Function() onDone;
  onDone = () {
    if (times-- > 0) {
      run(onDone);
    } else {
      _profileEnd(name);
      // TODO: Pause the program.
    }
  };
  _profile(name);
  run(onDone);
}
