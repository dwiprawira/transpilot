import 'package:flutter_test/flutter_test.dart';
import 'package:transpilot/core/utils/layout.dart';

void main() {
  test(
    'uses explicit adaptive breakpoints for compact, medium, and expanded layouts',
    () {
      expect(AppLayout.fromWidth(390), AppLayoutSize.compact);
      expect(AppLayout.fromWidth(800), AppLayoutSize.medium);
      expect(AppLayout.fromWidth(1200), AppLayoutSize.expanded);
      expect(AppLayout.useSplitView(1200), isTrue);
      expect(AppLayout.isTablet(800), isTrue);
    },
  );
}
