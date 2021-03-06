// Copyright 2017, Google Inc.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import '../_common.dart';

/// Tests the size of using [Future.value] from `dart:async`.
void main() {
  benchAsync('Future.value', (onDone) {
    new Future.value(1).then((_) => onDone());
  });
}
