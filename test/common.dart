// Copyright 2017, Google Inc.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:tinyasync/src/runtime/js.dart';

Future<Null> nextNativeMicrotask() {
  final completer = new Completer<Null>.sync();
  nativeScheduleMicrotask(completer.complete);
  return completer.future;
}
