enum AppLayoutSize { compact, medium, expanded }

class AppLayout {
  static AppLayoutSize fromWidth(double width) {
    if (width >= 1100) {
      return AppLayoutSize.expanded;
    }
    if (width >= 700) {
      return AppLayoutSize.medium;
    }
    return AppLayoutSize.compact;
  }

  static bool isTablet(double width) => width >= 700;

  static bool useSplitView(double width) => width >= 1100;

  static double horizontalPadding(double width) {
    if (width >= 1100) {
      return 28;
    }
    if (width >= 700) {
      return 20;
    }
    return 16;
  }
}
