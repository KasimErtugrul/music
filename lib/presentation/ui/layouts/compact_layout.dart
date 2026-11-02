import 'package:flutter/material.dart';
import 'package:resonance/presentation/ui/widgets/mini_player.dart';

class CompactLayout extends StatelessWidget {
  const CompactLayout({
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
    return Scaffold(
      body: body,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          // Bulgu 8: M3 varsayılanı 80dp olan gezinme çubuğu 66dp'ye
          // indirildi; içeriğe ~14dp daha fazla dikey alan kalır.
          NavigationBar(
            height: 66,
            selectedIndex: currentIndex,
            onDestinationSelected: onDestinationSelected,
            destinations: destinations,
          ),
        ],
      ),
    );
  }
}