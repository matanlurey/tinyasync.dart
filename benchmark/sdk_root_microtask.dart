// Copyright 2017, Google Inc.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/// Tests the size of using [scheduleMicrotask] from `dart:async`.
void main() {
  scheduleMicrotask(() {});
}
