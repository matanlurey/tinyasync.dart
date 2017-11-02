// Copyright 2017, Google Inc.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../tinyasync.dart';

/// An environment that remains stable across asynchronous calls.
class Zone {
  /// Zone that is currently active.
  static Zone get current => _current;

  /// Root zone.
  static Zone root = const _RootZone();

  // ignore: prefer_final_fields
  static Zone _current = root;

  /// Values bound to the zone (via [runZoned]).
  final Map<Object, Object> _map;
  final ZoneSpecification _spec;

  /// Parent zone, if any.
  final Zone parent;

  // Prevent inheritance or instantiation.
  const Zone._(this._map, this._spec, this.parent);

  /// Returns a new [Zone] with [zoneValues] set.
  Zone fork({
    ZoneSpecification specification: const ZoneSpecification(),
    Map<Object, Object> zoneValues: const {},
  }) {
    assert(zoneValues != null);
    assert(zoneValues.keys.every((o) => o != null));
    return new Zone._(zoneValues, specification, this);
  }

  /// Returns [callback] wrapped to execute in this zone when invoked.
  R Function() bindCallback<R>(R Function() callback) {
    return () => run(callback);
  }

  /// Creates a [Timer] bound to this zone.
  Timer createTimer(Duration duration, void Function() callback) {
    return _spec.createTimer(parent, duration, bindCallback(callback));
  }

  /// Creates a periodic [Timer] bound to this zone.
  Timer createPeriodicTimer(Duration duration, void Function() callback) {
    return _spec.createPeriodicTimer(parent, duration, bindCallback(callback));
  }

  /// Executes [body] with [Zone.current] set to _this_ [Zone].
  R run<R>(R Function() body) {
    final restore = _current;
    R result;
    try {
      _current = this;
      result = body();
      return result;
    } finally {
      _current = restore;
    }
  }

  /// Prints the given [line].
  void print(String line) => _spec.print(parent, line);

  /// Runs [callback] asynchronously in this zone.
  void scheduleMicrotask(void Function() callback) {
    _spec.scheduleMicrotask(parent, bindCallback(callback));
  }

  /// Returns the result of looking up [key] in `zoneValues`.
  ///
  /// A miss checks [parent].
  Object operator [](Object key) => _map[key] ?? parent[key];
}

/// Executes a function [body] in a new zone.
R runZoned<R>(R Function() body, {Map<Object, Object> zoneValues}) {
  final zone = Zone.current.fork(zoneValues: zoneValues);
  return zone.run(body);
}

const Zone _rootZone = const _RootZone();

// This is faster than using a LinkedList in most JS VMs.
List<void Function()> _microtaskQueue;

void _scheduleMicrotaskLoop() {
  runtime.nativeScheduleMicrotask(_startMicrotaskLoop);
}

void _startMicrotaskLoop() {
  while (_microtaskQueue.isNotEmpty) {
    _microtaskQueue.removeAt(0)();
  }
  _microtaskQueue = null;
}

class _RootZone extends Zone {
  const _RootZone() : super._(const {}, null, null);

  @override
  Timer createTimer(Duration duration, void Function() callback) {
    return new _JsTimer(duration, callback);
  }

  @override
  Timer createPeriodicTimer(Duration duration, void Function() callback) {
    return new _JsPeriodicTimer(duration, callback);
  }

  @override
  void print(String line) => runtime.nativePrint(line);

  @override
  void scheduleMicrotask(void Function() body) {
    body = bindCallback(body);
    if (_microtaskQueue == null) {
      _microtaskQueue = <void Function()>[body];
      _scheduleMicrotaskLoop();
    } else {
      _microtaskQueue.add(body);
    }
  }

  @override
  Object operator [](Object key) => null;
}

/// Provides a specification for a forked zone.
class ZoneSpecification {
  static Timer _createTimer(Zone zone, Duration duration, void Function() fn) {
    return zone.createTimer(duration, fn);
  }

  static Timer _createPeriodicTimer(
    Zone zone,
    Duration duration,
    void Function() fn,
  ) {
    return zone.createPeriodicTimer(duration, fn);
  }

  static void _print(Zone zone, String message) {
    zone.print(message);
  }

  static void _scheduleMicrotask(Zone zone, void Function() body) {
    zone.scheduleMicrotask(body);
  }

  final Timer Function(Zone, Duration, void Function()) createTimer;
  final Timer Function(Zone, Duration, void Function()) createPeriodicTimer;
  final void Function(Zone, String) print;
  final void Function(Zone, void Function()) scheduleMicrotask;

  const ZoneSpecification({
    this.createTimer: _createTimer,
    this.createPeriodicTimer: _createPeriodicTimer,
    this.print: _print,
    this.scheduleMicrotask: _scheduleMicrotask,
  });
}
