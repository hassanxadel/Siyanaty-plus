/// Script to help identify and fix hardcoded sizing values in Flutter files
/// 
/// This script provides guidelines for converting hardcoded values to responsive ones
/// 
/// Usage:
/// 1. Run this script to see examples of what to look for
/// 2. Use the patterns below to search and replace in your codebase
/// 
/// Common patterns to fix:
/// 
/// 1. FONT SIZES
///    Before: fontSize: 16
///    After:  fontSize: context.responsiveFontSize(16)
///    Or:     style: context.responsiveTextStyle(fontSize: 16, ...)
/// 
/// 2. PADDING & MARGINS
///    Before: padding: EdgeInsets.all(16)
///    After:  padding: EdgeInsets.all(context.r(16))
///    
///    Before: padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10)
///    After:  padding: EdgeInsets.symmetric(horizontal: context.r(20), vertical: context.r(10))
///    Or:     padding: context.responsivePadding(horizontal: 20, vertical: 10)
///    
///    Before: padding: EdgeInsets.only(left: 16, top: 8, right: 16, bottom: 8)
///    After:  padding: context.responsivePaddingAll(left: 16, top: 8, right: 16, bottom: 8)
/// 
/// 3. SIZEDBOX
///    Before: SizedBox(height: 20)
///    After:  SizedBox(height: context.r(20))
///    
///    Before: SizedBox(width: 100, height: 50)
///    After:  SizedBox(width: context.r(100), height: context.r(50))
/// 
/// 4. CONTAINER SIZES
///    Before: Container(width: 200, height: 100, ...)
///    After:  Container(width: context.r(200), height: context.r(100), ...)
/// 
/// 5. ICON SIZES
///    Before: Icon(Icons.home, size: 24)
///    After:  Icon(Icons.home, size: context.responsiveIconSize(24))
/// 
/// 6. BORDER RADIUS
///    Before: borderRadius: BorderRadius.circular(12)
///    After:  borderRadius: BorderRadius.circular(context.responsiveBorderRadius(12))
/// 
/// 7. BUTTON HEIGHTS
///    Before: height: 48
///    After:  height: context.responsiveButtonHeight(48)
/// 
/// 8. TEXT WIDGETS
///    Before: Text('Hello', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
///    After:  Text('Hello', style: context.responsiveTextStyle(fontSize: 16, fontWeight: FontWeight.bold))
/// 
/// 9. SPACING BETWEEN WIDGETS
///    Before: SizedBox(height: 16)
///    After:  SizedBox(height: context.responsiveSpacing(16))
/// 
/// SEARCH PATTERNS TO FIND HARDCODED VALUES:
/// 
/// Search for these patterns in your code:
/// - fontSize:\s*\d+           (finds fontSize: 16, fontSize: 20, etc.)
/// - size:\s*\d+               (finds size: 24, size: 32, etc.)
/// - height:\s*\d+             (finds height: 100, height: 50, etc.)
/// - width:\s*\d+              (finds width: 200, width: 150, etc.)
/// - EdgeInsets\.all\(\d+\)    (finds EdgeInsets.all(16), etc.)
/// - EdgeInsets\.symmetric     (finds EdgeInsets.symmetric patterns)
/// - EdgeInsets\.only          (finds EdgeInsets.only patterns)
/// - BorderRadius\.circular\(\d+\) (finds BorderRadius.circular(12), etc.)
/// 
/// FILES TO CHECK (in order of priority):
/// 1. lib/presentation/screens/**/*.dart (all screen files)
/// 2. lib/presentation/widgets/**/*.dart (all widget files)
/// 3. lib/presentation/providers/**/*.dart (provider files)
/// 
/// IMPORTANT NOTES:
/// - Always import: import '../../shared/utils/responsive_utils.dart';
/// - The context.r(value) method is a shorthand for context.responsiveSize(value)
/// - Use responsiveFontSize for fonts, responsiveIconSize for icons
/// - Use responsiveSpacing for spacing between widgets
/// - Use responsiveBorderRadius for border radius values
/// - Use responsiveButtonHeight for button heights
/// - The responsive system uses a base width of 375px (iPhone 11 Pro)
/// - All values scale proportionally based on actual device width
/// - Text scale factor is clamped between 0.8 and 1.3 to prevent overflow
/// 
/// TESTING:
/// After making changes, test on:
/// - Small devices (< 340px width)
/// - Medium devices (375px width - iPhone 11 Pro)
/// - Large devices (414px width - iPhone 11 Pro Max)
/// - Tablets (600px+ width)
/// 
/// You can check device size in debug mode using:
/// print('Device category: ${context.deviceCategory}');
/// print('Scale factor: ${context.scaleFactor}');
/// print('Screen width: ${context.screenWidth}');
library;

void main() {
  print('Responsive Sizing Fix Script');
  print('============================\n');
  print('This script provides guidelines for fixing hardcoded sizing values.');
  print('See the comments in this file for detailed instructions.\n');
  print('Key methods to use:');
  print('  - context.r(value) - for any size value');
  print('  - context.responsiveFontSize(value) - for font sizes');
  print('  - context.responsiveIconSize(value) - for icon sizes');
  print('  - context.responsiveSpacing(value) - for spacing');
  print('  - context.responsiveBorderRadius(value) - for border radius');
  print('  - context.responsiveButtonHeight(value) - for button heights');
  print('  - context.responsiveTextStyle(...) - for text styles');
  print('  - context.responsivePadding(...) - for padding');
  print('\nImport required:');
  print("  import '../../shared/utils/responsive_utils.dart';");
}
