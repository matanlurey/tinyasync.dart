// Copyright 2017, Google Inc.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../tinyasync.dart';

/// A countdown timer that can be configured to fire once or repeatedly.
abstract class Timer {
  factory Timer(Duration duration, void Function() callback) {
    return Zone.current.createTimer(duration, callback);
  }

  factory Timer.periodic(Duration duration, void Function() callback) {
    return Zone.current.createPeriodicTimer(duration, callback);
  }

  static Timer run(void Function() callback) {
    return new Timer(Duration.ZERO, callback);
  }

  /// Cancels the timer.
  void cancel();

  /// Returns whether the timer will still fire.
  bool get isActive;
}

class _JsTimer implements Timer {
  final void Function() _callback;
  int _jsRuntimeId;

  _JsTimer(Duration duration, this._callback) {
    _jsRuntimeId = runtime.setTimeout(() {
      isActive = false;
      _callback();
    }, duration.inMilliseconds);
  }

  @override
  bool isActive = true;

  @override
  void cancel() {
    isActive = false;
    runtime.clearTimeout(_jsRuntimeId);
  }
}

class _JsPeriodicTimer implements Timer {
  final void Function() _callback;
  int _jsRuntimeId;

  _JsPeriodicTimer(Duration duration, this._callback) {
    _jsRuntimeId = runtime.setInterval(_callback, duration.inMilliseconds);
  }

  @override
  bool isActive = true;

  @override
  void cancel() {
    isActive = false;
    runtime.clearInterval(_jsRuntimeId);
  }
}
