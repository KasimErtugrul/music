import 'package:flutter/widgets.dart';

/// Material 3 pencere sınıfları.
enum WindowSize { compact, medium, expanded }

/// Pencere sınıfı yardımcıları.
///
/// `Get.width` KULLANILMAZ; `MediaQuery.sizeOf` veya `LayoutBuilder` kullanılır.
abstract final class Responsive {
  /// Compact: genişlik < 600 dp.
  static const double mediumBreakpoint = 600;

  /// Medium: 600 dp <= genişlik < 840 dp. Expanded: genişlik >= 840 dp.
  static const double expandedBreakpoint = 840;

  static WindowSize fromWidth(double width) {
    if (width < mediumBreakpoint) return WindowSize.compact;
    if (width < expandedBreakpoint) return WindowSize.medium;
    return WindowSize.expanded;
  }

  static WindowSize of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);
}
