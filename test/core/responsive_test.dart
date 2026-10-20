import 'package:flutter_test/flutter_test.dart';
import 'package:resonance/core/utils/responsive.dart';

void main() {
  group('Responsive.fromWidth', () {
    test('Compact: 600 dp altı', () {
      expect(Responsive.fromWidth(0), WindowSize.compact);
      expect(Responsive.fromWidth(360), WindowSize.compact);
      expect(Responsive.fromWidth(599.9), WindowSize.compact);
    });

    test('Medium: 600 dp dahil, 840 dp hariç', () {
      expect(Responsive.fromWidth(600), WindowSize.medium);
      expect(Responsive.fromWidth(720), WindowSize.medium);
      expect(Responsive.fromWidth(839.9), WindowSize.medium);
    });

    test('Expanded: 840 dp ve üstü', () {
      expect(Responsive.fromWidth(840), WindowSize.expanded);
      expect(Responsive.fromWidth(1280), WindowSize.expanded);
    });
  });
}
