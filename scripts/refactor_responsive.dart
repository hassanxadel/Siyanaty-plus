#!/usr/bin/env dart

/// Automated refactoring script for making Flutter UI responsive
/// This script helps identify and suggest fixes for common responsiveness issues
/// 
/// Usage: dart scripts/refactor_responsive.dart

import 'dart:io';

void main() {
  print('🔍 Scanning for responsiveness issues...\n');
  
  final libDir = Directory('lib/presentation');
  if (!libDir.existsSync()) {
    print('❌ Error: lib/presentation directory not found');
    exit(1);
  }
  
  final issues = <String, List<ResponsivenessIssue>>{};
  
  // Scan all Dart files
  libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .forEach((file) {
    final fileIssues = scanFile(file);
    if (fileIssues.isNotEmpty) {
      issues[file.path] = fileIssues;
    }
  });
  
  // Print summary
  print('\n📊 Summary:');
  print('=' * 80);
  print('Files with issues: ${issues.length}');
  
  int totalIssues = 0;
  final issueTypes = <String, int>{};
  
  for (final fileIssues in issues.values) {
    totalIssues += fileIssues.length;
    for (final issue in fileIssues) {
      issueTypes[issue.type] = (issueTypes[issue.type] ?? 0) + 1;
    }
  }
  
  print('Total issues: $totalIssues');
  print('\nIssue breakdown:');
  issueTypes.forEach((type, count) {
    print('  - $type: $count');
  });
  
  // Print detailed issues
  print('\n📝 Detailed Issues:');
  print('=' * 80);
  
  issues.forEach((filePath, fileIssues) {
    final relativePath = filePath.replaceAll(RegExp(r'^.*lib/'), 'lib/');
    print('\n📄 $relativePath (${fileIssues.length} issues)');
    
    for (final issue in fileIssues) {
      print('  Line ${issue.lineNumber}: ${issue.type}');
      print('    Found: ${issue.originalCode.trim()}');
      if (issue.suggestion != null) {
        print('    Suggest: ${issue.suggestion}');
      }
    }
  });
  
  // Generate refactoring guide
  print('\n\n💡 Refactoring Recommendations:');
  print('=' * 80);
  print('''
1. Import responsive utilities in each file:
   import '../../../shared/utils/responsive_utils.dart';

2. Replace fixed SizedBox heights:
   Before: const Expanded(child: Expanded(child: SizedBox(height: 20)
   After:  Expanded(child: Expanded(child: SizedBox(height: context.responsiveSpacing(20))

3. Replace fixed Container dimensions:
   Before: Container(height: 200, width: 300, ...)
   After:  Container(
             height: context.isSmallDevice ? 150 : 200,
             width: double.infinity,
             ...
           )

4. Wrap non-scrollable Columns in SingleChildScrollView:
   Before: Column(children: [...])
   After:  SingleChildScrollView(
             child: Column(
               mainAxisSize: MainAxisSize.min,
               children: [...]
             )
           )

5. Use Flexible/Expanded in Rows and Columns:
   Before: Container(width: 200, ...)
   After:  Flexible(child: Container(...))

6. Add text overflow handling:
   Before: Text('Long text')
   After:  Text(
             'Long text',
             maxLines: 2,
             overflow: TextOverflow.ellipsis,
           )
''');
}

List<ResponsivenessIssue> scanFile(File file) {
  final issues = <ResponsivenessIssue>[];
  final lines = file.readAsLinesSync();
  
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final lineNumber = i + 1;
    
    // Check for fixed SizedBox heights
    if (line.contains(RegExp(r'SizedBox\s*\(\s*height:\s*\d+'))) {
      issues.add(ResponsivenessIssue(
        type: 'Fixed SizedBox height',
        lineNumber: lineNumber,
        originalCode: line,
        suggestion: 'Use context.responsiveSpacing()',
      ));
    }
    
    // Check for fixed Container heights
    if (line.contains(RegExp(r'height:\s*\d+[,\)]')) && 
        !line.contains('SizedBox')) {
      issues.add(ResponsivenessIssue(
        type: 'Fixed Container height',
        lineNumber: lineNumber,
        originalCode: line,
        suggestion: 'Use responsive height or remove fixed height',
      ));
    }
    
    // Check for fixed widths
    if (line.contains(RegExp(r'width:\s*\d+[,\)]'))) {
      issues.add(ResponsivenessIssue(
        type: 'Fixed width',
        lineNumber: lineNumber,
        originalCode: line,
        suggestion: 'Use double.infinity or Flexible/Expanded',
      ));
    }
    
    // Check for fixed font sizes
    if (line.contains(RegExp(r'fontSize:\s*\d+'))) {
      issues.add(ResponsivenessIssue(
        type: 'Fixed font size',
        lineNumber: lineNumber,
        originalCode: line,
        suggestion: 'Use context.responsiveFontSize()',
      ));
    }
    
    // Check for Text without overflow handling
    if (line.contains(RegExp(r'Text\s*\(')) && 
        !line.contains('overflow:') &&
        !line.contains('maxLines:')) {
      // Look ahead a few lines to see if overflow is defined
      bool hasOverflow = false;
      for (var j = i; j < i + 5 && j < lines.length; j++) {
        if (lines[j].contains('overflow:') || lines[j].contains('maxLines:')) {
          hasOverflow = true;
          break;
        }
        if (lines[j].contains(');')) break;
      }
      
      if (!hasOverflow && line.contains("'") && line.split("'").length > 2) {
        final text = line.split("'")[1];
        if (text.length > 20) {
          issues.add(ResponsivenessIssue(
            type: 'Text without overflow handling',
            lineNumber: lineNumber,
            originalCode: line,
            suggestion: 'Add maxLines and overflow properties',
          ));
        }
      }
    }
    
    // Check for EdgeInsets with fixed values
    if (line.contains(RegExp(r'EdgeInsets\.(all|symmetric|only)\s*\('))) {
      issues.add(ResponsivenessIssue(
        type: 'Fixed EdgeInsets',
        lineNumber: lineNumber,
        originalCode: line,
        suggestion: 'Use ResponsiveUtils.responsivePadding()',
      ));
    }
  }
  
  return issues;
}

class ResponsivenessIssue {
  final String type;
  final int lineNumber;
  final String originalCode;
  final String? suggestion;
  
  ResponsivenessIssue({
    required this.type,
    required this.lineNumber,
    required this.originalCode,
    this.suggestion,
  });
}
