// Copyright 2017, Google Inc.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:tinyasync/tinyasync.dart';

import '../_common.dart';

/// Tests the size of using [Timer.run] from `package:tinyasync`.
void main() {
  benchAsync('Zone.current.fork().createTuner', (onDone) {
    Zone.current.fork().createTimer(Duration.ZERO, onDone);
  });
}
