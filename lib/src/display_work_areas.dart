import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:nativeapi/nativeapi.dart' as nativeapi;

/// A detached snapshot of a display's usable area, in logical pixels.
///
/// Unlike a native [nativeapi.Display] handle, this value contains no native
/// resources and can safely be stored for later window-placement calculations.
@immutable
final class DisplayWorkArea {
  const DisplayWorkArea({
    required this.bounds,
    required this.scaleFactor,
  });

  /// Work area in the global logical coordinate system, excluding taskbars,
  /// docks, and panels.
  final Rect bounds;

  /// Physical pixels per logical pixel for this display.
  final double scaleFactor;
}

/// Reads just the usable rectangles and scale factors of connected displays.
///
/// Window-position validation often does not need monitor names, IDs, sizes,
/// or refresh rates. This avoids those additional native property calls and
/// temporary strings. The native display handles are always released before
/// returning, even if reading any property throws.
///
/// Returns an empty list when there are no connected displays.
List<DisplayWorkArea> getDisplayWorkAreas() {
  return snapshotDisplayWorkAreas(nativeapi.DisplayManager.instance.getAll());
}

/// Snapshots and disposes a batch of native handles.
///
/// Kept separate from enumeration to test both the minimal set of native
/// getters and resource cleanup without needing a physical desktop.
@visibleForTesting
List<DisplayWorkArea> snapshotDisplayWorkAreas(
  List<nativeapi.Display> displays,
) {
  try {
    final result = <DisplayWorkArea>[];
    for (final display in displays) {
      final workArea = display.workArea;
      result.add(
        DisplayWorkArea(
          bounds: Rect.fromLTWH(
            workArea.x,
            workArea.y,
            workArea.width,
            workArea.height,
          ),
          scaleFactor: display.scaleFactor,
        ),
      );
    }
    return result;
  } finally {
    for (final display in displays) {
      display.dispose();
    }
  }
}
