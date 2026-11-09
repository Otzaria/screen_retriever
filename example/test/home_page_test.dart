// Exercises the sample UI with a fake display backend.
// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_retriever/legacy.dart';
import 'package:screen_retriever_example/main.dart';

class _TestPlatform extends ScreenRetrieverPlatform {
  final events = StreamController<Map<Object?, Object?>>.broadcast();

  final displays = <Display>[
    const Display(id: '1', name: 'Primary screen', size: Size(1920, 1080)),
  ];

  Completer<Display>? pendingPrimary;
  bool fail = false;
  int primaryReads = 0;

  @override
  Stream<Map<Object?, Object?>> get onScreenEventReceiver => events.stream;

  @override
  Future<Offset> getCursorScreenPoint() async => Offset.zero;

  @override
  Future<Display> getPrimaryDisplay() {
    primaryReads++;
    if (fail) return Future.error(StateError('temporarily unavailable'));
    final completer = pendingPrimary;
    if (completer != null) return completer.future;
    return Future.value(displays.first);
  }

  @override
  Future<List<Display>> getAllDisplays() async => List.of(displays);
}

void main() {
  late _TestPlatform platform;

  setUp(() {
    platform = _TestPlatform();
    ScreenRetrieverPlatform.instance = platform;
  });

  tearDown(() async {
    await platform.events.close();
  });

  testWidgets('the example shows the primary display', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Primary screen'), findsWidgets);
    expect(platform.primaryReads, 1);
  });

  testWidgets('monitor event bursts trigger only one refresh', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    platform.events.add({'type': 'display-added'});
    platform.events.add({'type': 'display-changed'});
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump();

    expect(platform.primaryReads, 2);
  });

  testWidgets('pending results are ignored after the page is disposed',
      (tester) async {
    platform.pendingPrimary = Completer<Display>();
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    await tester.pumpWidget(const SizedBox.shrink());
    platform.pendingPrimary!.complete(
      const Display(id: '1', size: Size(1920, 1080)),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('temporary native failures are reported without crashing',
      (tester) async {
    platform.fail = true;
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('temporarily unavailable'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
