// Copyright 2017, Google Inc.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:tinyasync/tinyasync.dart';

void main() {
  test('should set zoneValues on runZoned', () {
    expect(Zone.current['value'], isNull);
    runZoned(() {
      runZoned(() {
        runZoned(() {
          expect(Zone.current['value'], 3);
        }, zoneValues: {'value': (Zone.current['value'] as int) + 1});
        expect(Zone.current['value'], 2);
      }, zoneValues: {'value': (Zone.current['value'] as int) + 1});
      expect(Zone.current['value'], 1);
    }, zoneValues: {'value': 1});
    expect(Zone.current['value'], isNull);
  });

  test('should set current zone on run', () {
    final root = Zone.root;
    final child = root.fork();
    expect(Zone.current, root);
    child.run(() {
      expect(Zone.current, child);
    });
    expect(Zone.current, root);
  });

  test('should catch errors on runGuarded', () {
    final errors = <Object>[];
    final root = Zone.root;
    final child = root.fork(
      specification: new ZoneSpecification(
        handleUncaughtError: (_, e, __) => errors.add(e),
      ),
    );
    expect(Zone.current, root);
    child.runGuarded(() {
      expect(Zone.current, child);
      throw new IntentionalException();
    });
    expect(errors, hasLength(1));
  });

  test('should set current zone on bindCallback', () {
    final child = Zone.root.fork();
    final callback = child.bindCallback(() => Zone.current);
    expect(callback(), child);
  });
}

class IntentionalException implements Exception {}
