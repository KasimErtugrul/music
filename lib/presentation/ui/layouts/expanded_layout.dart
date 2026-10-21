import 'package:flutter/material.dart';
import 'package:resonance/presentation/ui/widgets/mini_player.dart';
import 'package:resonance/presentation/ui/widgets/player_panel.dart';

class ExpandedLayout extends StatelessWidget {
  const ExpandedLayout({
    super.key,
    required this.body,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.isExtended,
  });

  final Widget body;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;
  final bool isExtended;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: isExtended,
            selectedIndex: currentIndex,
            onDestinationSelected: onDestinationSelected,
            labelType: isExtended
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            destinations: destinations.map((d) {
              return NavigationRailDestination(
                icon: d.icon,
                selectedIcon: d.selectedIcon,
                label: Text(d.label),
              );
            }).toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                Expanded(child: body),
                // Medium ekranlarda alt kısımda mini player görünür
                if (!isExtended) const MiniPlayer(),
              ],
            ),
          ),
          // Geniş ekranlarda (Expanded) sağ tarafta kalıcı oynatıcı paneli
          if (isExtended) ...[
            const VerticalDivider(width: 1),
            const SizedBox(
              width: 400,
              child: PlayerPanel(),
            ),
          ],
        ],
      ),
    );
  }
}