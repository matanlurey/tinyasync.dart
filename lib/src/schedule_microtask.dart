// Copyright 2017, Google Inc.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../tinyasync.dart';

/// Runs a function asynchronously.
void scheduleMicrotask(void Function() callback) {
  Zone.current.scheduleMicrotask(callback);
}
