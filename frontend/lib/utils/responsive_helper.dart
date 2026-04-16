/// Responsive layout helper utilities
/// Provides breakpoints and responsive sizing for mobile and desktop layouts

class ResponsiveHelper {
  /// Mobile breakpoint: 320px - 768px
  static const double mobileMaxWidth = 768.0;
  
  /// Desktop max content width for centered layout
  static const double desktopMaxContentWidth = 1200.0;
  
  /// Check if current screen is mobile
  static bool isMobile(double width) {
    return width <= mobileMaxWidth;
  }
  
  /// Check if current screen is desktop
  static bool isDesktop(double width) {
    return width > mobileMaxWidth;
  }
  
  /// Get appropriate padding based on screen size
  static double getPadding(double width) {
    return isMobile(width) ? 16.0 : 24.0;
  }
  
  /// Get appropriate button height based on screen size
  static double getButtonHeight(double width) {
    return isMobile(width) ? 56.0 : 48.0;
  }
  
  /// Get appropriate font size multiplier based on screen size
  static double getFontSizeMultiplier(double width) {
    return isMobile(width) ? 1.1 : 1.0;
  }
  
  /// Get appropriate spacing based on screen size
  static double getSpacing(double width) {
    return isMobile(width) ? 16.0 : 24.0;
  }
  
  /// Get appropriate card elevation based on screen size
  static double getCardElevation(double width) {
    return isMobile(width) ? 2.0 : 4.0;
  }
  
  /// Get appropriate icon size based on screen size
  static double getIconSize(double width) {
    return isMobile(width) ? 32.0 : 24.0;
  }
}
