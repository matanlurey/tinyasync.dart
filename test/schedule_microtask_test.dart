// Copyright 2017, Google Inc.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:tinyasync/tinyasync.dart';

import 'common.dart';

void main() {
  test('should schedule a microtask', () async {
    final logs = <int>[];
    scheduleMicrotask(() => logs.add(1));
    scheduleMicrotask(() => logs.add(2));
    scheduleMicrotask(() => logs.add(3));
    await nextNativeMicrotask();
    expect(logs, [1, 2, 3]);
  });
}
