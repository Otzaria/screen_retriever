import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:nativeapi/nativeapi.dart' as nativeapi;
import 'package:screen_retriever/src/display_work_areas.dart';

class _FakeDisplay extends Fake implements nativeapi.Display {
  _FakeDisplay(this.geometry, this.factor, {this.failOnRead = false});

  final nativeapi.Rectangle geometry;
  final double factor;
  final bool failOnRead;
  int workAreaReads = 0;
  int scaleFactorReads = 0;
  int disposeCalls = 0;

  @override
  nativeapi.Rectangle get workArea {
    workAreaReads++;
    if (failOnRead) throw StateError('monitor disconnected');
    return geometry;
  }

  @override
  double get scaleFactor {
    scaleFactorReads++;
    return factor;
  }

  @override
  void dispose() {
    disposeCalls++;
  }
}

void main() {
  test('snapshots only work areas and scale factors', () {
    final left = _FakeDisplay(
      const nativeapi.Rectangle(
        x: -1279.5,
        y: 0,
        width: 1279.5,
        height: 900,
      ),
      1.25,
    );
    final primary = _FakeDisplay(
      const nativeapi.Rectangle(
        x: 0,
        y: 28,
        width: 1920,
        height: 1052,
      ),
      1.0,
    );

    final areas = snapshotDisplayWorkAreas([left, primary]);

    expect(areas, hasLength(2));
    expect(areas[0].bounds, const Rect.fromLTWH(-1279.5, 0, 1279.5, 900));
    expect(areas[0].scaleFactor, 1.25);
    expect(areas[1].bounds, const Rect.fromLTWH(0, 28, 1920, 1052));
    expect(areas[1].scaleFactor, 1);
    for (final display in [left, primary]) {
      expect(display.workAreaReads, 1);
      expect(display.scaleFactorReads, 1);
      expect(display.disposeCalls, 1);
    }
  });

  test('all handles are disposed if one display becomes unavailable', () {
    final first = _FakeDisplay(
      const nativeapi.Rectangle(x: 0, y: 0, width: 800, height: 600),
      1.0,
    );
    final failing = _FakeDisplay(
      const nativeapi.Rectangle(x: 0, y: 0, width: 800, height: 600),
      1.0,
      failOnRead: true,
    );
    final last = _FakeDisplay(
      const nativeapi.Rectangle(x: 0, y: 0, width: 800, height: 600),
      1.0,
    );

    expect(
      () => snapshotDisplayWorkAreas([first, failing, last]),
      throwsStateError,
    );
    expect(first.disposeCalls, 1);
    expect(failing.disposeCalls, 1);
    expect(last.disposeCalls, 1);
  });

  test('empty display lists are allowed', () {
    expect(snapshotDisplayWorkAreas([]), isEmpty);
  });
}
