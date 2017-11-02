// Copyright 2017, Google Inc.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:tinyasync/tinyasync.dart';

import 'common.dart';

void main() {
  test('should schedule a timer', () async {
    final logs = <int>[];
    Timer.run(() => logs.add(1));
    Timer.run(() => logs.add(2));
    Timer.run(() => logs.add(3));
    await nextNativeEventLoop();
    expect(logs, [1, 2, 3]);
  });
}
