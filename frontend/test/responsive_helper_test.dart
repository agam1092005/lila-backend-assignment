import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/utils/responsive_helper.dart';

void main() {
  group('ResponsiveHelper', () {
    test('isMobile returns true for widths <= 768', () {
      expect(ResponsiveHelper.isMobile(320), true);
      expect(ResponsiveHelper.isMobile(480), true);
      expect(ResponsiveHelper.isMobile(768), true);
    });

    test('isMobile returns false for widths > 768', () {
      expect(ResponsiveHelper.isMobile(769), false);
      expect(ResponsiveHelper.isMobile(1024), false);
      expect(ResponsiveHelper.isMobile(1920), false);
    });

    test('isDesktop returns true for widths > 768', () {
      expect(ResponsiveHelper.isDesktop(769), true);
      expect(ResponsiveHelper.isDesktop(1024), true);
      expect(ResponsiveHelper.isDesktop(1920), true);
    });

    test('isDesktop returns false for widths <= 768', () {
      expect(ResponsiveHelper.isDesktop(320), false);
      expect(ResponsiveHelper.isDesktop(480), false);
      expect(ResponsiveHelper.isDesktop(768), false);
    });

    test('getPadding returns larger padding for mobile', () {
      final mobilePadding = ResponsiveHelper.getPadding(480);
      final desktopPadding = ResponsiveHelper.getPadding(1024);
      
      expect(mobilePadding, 16.0);
      expect(desktopPadding, 24.0);
    });

    test('getButtonHeight returns larger height for mobile', () {
      final mobileHeight = ResponsiveHelper.getButtonHeight(480);
      final desktopHeight = ResponsiveHelper.getButtonHeight(1024);
      
      expect(mobileHeight, 56.0);
      expect(desktopHeight, 48.0);
    });

    test('getFontSizeMultiplier returns larger multiplier for mobile', () {
      final mobileMultiplier = ResponsiveHelper.getFontSizeMultiplier(480);
      final desktopMultiplier = ResponsiveHelper.getFontSizeMultiplier(1024);
      
      expect(mobileMultiplier, 1.1);
      expect(desktopMultiplier, 1.0);
    });

    test('getSpacing returns larger spacing for mobile', () {
      final mobileSpacing = ResponsiveHelper.getSpacing(480);
      final desktopSpacing = ResponsiveHelper.getSpacing(1024);
      
      expect(mobileSpacing, 16.0);
      expect(desktopSpacing, 24.0);
    });

    test('getCardElevation returns smaller elevation for mobile', () {
      final mobileElevation = ResponsiveHelper.getCardElevation(480);
      final desktopElevation = ResponsiveHelper.getCardElevation(1024);
      
      expect(mobileElevation, 2.0);
      expect(desktopElevation, 4.0);
    });

    test('getIconSize returns larger icons for mobile', () {
      final mobileIconSize = ResponsiveHelper.getIconSize(480);
      final desktopIconSize = ResponsiveHelper.getIconSize(1024);
      
      expect(mobileIconSize, 32.0);
      expect(desktopIconSize, 24.0);
    });

    test('mobile breakpoint is 768px', () {
      expect(ResponsiveHelper.mobileMaxWidth, 768.0);
    });

    test('desktop max content width is 1200px', () {
      expect(ResponsiveHelper.desktopMaxContentWidth, 1200.0);
    });
  });
}
