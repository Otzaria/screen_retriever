// The example shows the deprecated 0.2.x compatible API on purpose.
// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:screen_retriever/legacy.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: BotToastInit(),
      navigatorObservers: [BotToastNavigatorObserver()],
      home: const HomePage(),
    );
  }
}

class _ListSection extends StatelessWidget {
  const _ListSection({required this.title, required this.children});

  final Widget title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 12, bottom: 6),
          child: DefaultTextStyle(
            style: Theme.of(context).textTheme.titleMedium ?? const TextStyle(),
            child: title,
          ),
        ),
        ...children,
      ],
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with ScreenListener {
  Display? _primaryDisplay;
  List<Display> _displayList = [];
  String? _loadError;
  Timer? _refreshTimer;
  int _refreshGeneration = 0;

  @override
  void initState() {
    super.initState();
    screenRetriever.addListener(this);
    unawaited(_getDisplays());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    // Ignore results from any in-flight native query after widget teardown.
    _refreshGeneration++;
    screenRetriever.removeListener(this);
    super.dispose();
  }

  @override
  void onScreenEvent(String eventName) {
    BotToast.showText(text: 'onScreenEvent: $eventName');
    // Hot-plugging may emit added, removed and changed events in a burst.
    // Coalesce them instead of starting overlapping native reads.
    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(milliseconds: 100), () {
      unawaited(_getDisplays());
    });
  }

  Future<void> _getDisplays() async {
    final generation = ++_refreshGeneration;
    try {
      final primary = await screenRetriever.getPrimaryDisplay();
      final displays = await screenRetriever.getAllDisplays();
      if (!mounted || generation != _refreshGeneration) return;
      setState(() {
        _primaryDisplay = primary;
        _displayList = displays;
        _loadError = null;
      });
    } catch (error) {
      // A primary display can temporarily disappear while unplugging a
      // monitor. Keep the example usable and show the failure.
      if (!mounted || generation != _refreshGeneration) return;
      setState(() {
        _primaryDisplay = null;
        _displayList = [];
        _loadError = error.toString();
      });
    }
  }

  Future<void> _handleGetCursorScreenPoint() async {
    try {
      final point = await screenRetriever.getCursorScreenPoint();
      if (mounted) BotToast.showText(text: 'cursorScreenPoint: $point');
    } catch (error) {
      if (mounted) BotToast.showText(text: 'Cursor unavailable: $error');
    }
  }

  Widget _buildPrimaryDisplay(BuildContext context) {
    if (_primaryDisplay != null) {
      return _ListSection(
        title: const Text('Primary Display'),
        children: [DisplayCard(_primaryDisplay!)],
      );
    }
    return const SizedBox();
  }

  Widget _buildAllDisplays(BuildContext context) {
    if (_displayList.isNotEmpty) {
      return _ListSection(
        title: const Text('All Displays'),
        children: [for (var display in _displayList) DisplayCard(display)],
      );
    }
    return const SizedBox();
  }

  Widget _buildMethods(BuildContext context) {
    return _ListSection(
      title: const Text('Methods'),
      children: [
        Card(
          child: ListTile(
            title: const Text('getCursorScreenPoint'),
            onTap: _handleGetCursorScreenPoint,
          ),
        ),
        Card(
          child: ListTile(
            title: const Text('getPrimaryDisplay'),
            onTap: () async {
              await _getDisplays();
              final primary = _primaryDisplay;
              if (mounted && primary != null) {
                BotToast.showText(text: 'primaryDisplay: ${primary.toJson()}');
              }
            },
          ),
        ),
        Card(
          child: ListTile(
            title: const Text('getAllDisplays'),
            onTap: () async {
              await _getDisplays();
              if (mounted) {
                BotToast.showText(
                  text:
                      'allDisplays:\n${_displayList.map((e) => e.toJson()).join('\n')}',
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        if (_loadError != null)
          Text('Could not read displays: $_loadError'),
        _buildPrimaryDisplay(context),
        _buildAllDisplays(context),
        _buildMethods(context),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Screen Retriever Example')),
      body: _buildBody(context),
    );
  }
}

class DisplayCard extends StatelessWidget {
  const DisplayCard(this.display, {super.key});

  final Display display;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text('${display.name}'),
        subtitle: Text(
          [
            'id: ${display.id}',
            'size: ${display.size}',
            'visiblePosition: ${display.visiblePosition}',
            'visibleSize: ${display.visibleSize}',
            'scaleFactor: ${display.scaleFactor}',
          ].join('\n'),
        ),
        onTap: () {
          BotToast.showText(text: '${display.toJson()}');
        },
      ),
    );
  }
}
