import 'package:flutter/material.dart';
import 'package:resonance/core/utils/responsive.dart';
import 'package:resonance/presentation/ui/layouts/compact_layout.dart';
import 'package:resonance/presentation/ui/layouts/expanded_layout.dart';

class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    required this.body,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final Widget body;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final windowSize = Responsive.of(context);

    if (windowSize == WindowSize.compact) {
      return CompactLayout(
        body: body,
        currentIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations,
      );
    }

    return ExpandedLayout(
      body: body,
      currentIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: destinations,
      isExtended: windowSize == WindowSize.expanded,
    );
  }
}