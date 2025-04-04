import 'dart:io';
import 'dart:convert';

/// Script để chạy tests và tính toán coverage
void main(List<String> args) async {
  print('====== FLUTTER TEST COVERAGE GENERATOR ======');
  
  // Kiểm tra flutter version
  await _runCommand('flutter', ['--version']);
  
  // Kiểm tra các dependencies cần thiết
  await _checkDependencies();
  
  // Xóa dữ liệu coverage cũ
  await _cleanCoverage();
  
  // Chạy tests và generate coverage
  await _runTestsWithCoverage();
  
  // Format coverage data
  await _formatCoverage();
  
  // Tính toán và hiển thị kết quả
  await _calculateCoverage();
  
  print('====== TEST COVERAGE COMPLETE ======');
}

/// Kiểm tra công cụ cần thiết đã được cài đặt
Future<void> _checkDependencies() async {
  print('\n📦 Checking dependencies...');
  
  // Kiểm tra lcov
  final lcovResult = await Process.run('which', ['lcov']);
  if (lcovResult.exitCode != 0) {
    print('⚠️ lcov not found. Installing...');
    if (Platform.isLinux || Platform.isMacOS) {
      await _runCommand('brew', ['install', 'lcov']);
    } else if (Platform.isWindows) {
      print('⚠️ Please install lcov manually on Windows. See: http://ltp.sourceforge.net/coverage/lcov.php');
    }
  } else {
    print('✅ lcov is installed');
  }
  
  // Kiểm tra và cài đặt flutter coverage packages
  final devDependenciesResult = await Process.run(
    'flutter', ['pub', 'deps'], 
    workingDirectory: Directory.current.path
  );
  
  if (devDependenciesResult.stdout.toString().contains('test_coverage') == false) {
    print('⚠️ test_coverage package not found. Installing...');
    await _runCommand(
      'flutter', 
      ['pub', 'add', 'test_coverage', '--dev']
    );
  } else {
    print('✅ test_coverage is installed');
  }
}

/// Xóa dữ liệu coverage cũ
Future<void> _cleanCoverage() async {
  print('\n🧹 Cleaning old coverage data...');
  
  final coverageDir = Directory('coverage');
  if (await coverageDir.exists()) {
    await coverageDir.delete(recursive: true);
    print('✅ Removed old coverage directory');
  }
  
  final testReportDir = Directory('test-results');
  if (await testReportDir.exists()) {
    await testReportDir.delete(recursive: true);
    print('✅ Removed old test-results directory');
  }
  
  // Tạo thư mục mới
  await coverageDir.create();
  await testReportDir.create();
  print('✅ Created new directories');
}

/// Chạy tests với coverage
Future<void> _runTestsWithCoverage() async {
  print('\n🧪 Running tests with coverage...');
  
  // Chạy các unit tests
  await _runCommand(
    'flutter', 
    ['test', '--coverage', '--coverage-path=coverage/lcov.info']
  );
  
  print('✅ Tests completed');
}

/// Format coverage data into more readable formats
Future<void> _formatCoverage() async {
  print('\n📊 Formatting coverage data...');
  
  // Tạo HTML report từ lcov data
  await _runCommand(
    'genhtml', 
    [
      'coverage/lcov.info',
      '-o', 'coverage/html',
      '--no-function-coverage',
      '--no-branch-coverage',
    ]
  );
  
  print('✅ Created HTML report at coverage/html/index.html');
  
  // Tạo text report
  await _runCommand(
    'lcov', 
    [
      '--summary', 'coverage/lcov.info',
      '--output-file', 'coverage/coverage_summary.txt'
    ]
  );
  
  print('✅ Created summary at coverage/coverage_summary.txt');
}

/// Tính toán và hiển thị kết quả coverage
Future<void> _calculateCoverage() async {
  print('\n📈 Calculating coverage metrics...');
  
  // Đọc lcov.info để phân tích
  final lcovFile = File('coverage/lcov.info');
  if (!await lcovFile.exists()) {
    print('⚠️ lcov.info not found. Cannot calculate coverage.');
    return;
  }
  
  final lcovContent = await lcovFile.readAsString();
  final lines = lcovContent.split('\n');
  
  // Phân tích coverage
  Map<String, Map<String, int>> fileCoverage = {};
  String currentFile = '';
  
  int totalLines = 0;
  int coveredLines = 0;
  
  for (final line in lines) {
    if (line.startsWith('SF:')) {
      currentFile = line.substring(3);
      fileCoverage[currentFile] = {
        'total': 0,
        'covered': 0
      };
    } else if (line.startsWith('DA:')) {
      fileCoverage[currentFile]?['total'] = (fileCoverage[currentFile]?['total'] ?? 0) + 1;
      
      final parts = line.split(',');
      if (parts.length > 1 && int.parse(parts[1]) > 0) {
        fileCoverage[currentFile]?['covered'] = (fileCoverage[currentFile]?['covered'] ?? 0) + 1;
      }
    }
  }
  
  // Tính tổng coverage
  for (final file in fileCoverage.keys) {
    totalLines += fileCoverage[file]!['total']!;
    coveredLines += fileCoverage[file]!['covered']!;
  }
  
  final overallCoverage = totalLines > 0 ? (coveredLines / totalLines * 100).toStringAsFixed(2) : '0.00';
  
  // Báo cáo các file có coverage thấp
  print('\n📊 Overall coverage: $overallCoverage% ($coveredLines/$totalLines lines)');
  print('\n🔍 Files with low coverage (<50%):');
  
  List<MapEntry<String, double>> filesCoveragePercentage = [];
  
  for (final file in fileCoverage.keys) {
    final total = fileCoverage[file]!['total']!;
    final covered = fileCoverage[file]!['covered']!;
    
    if (total > 0) {
      final percentage = covered / total * 100;
      filesCoveragePercentage.add(MapEntry(file, percentage));
      
      if (percentage < 50) {
        print('   ⚠️ ${file}: ${percentage.toStringAsFixed(2)}% ($covered/$total)');
      }
    }
  }
  
  // Hiển thị top 5 file có coverage tốt nhất
  filesCoveragePercentage.sort((a, b) => b.value.compareTo(a.value));
  
  print('\n🏆 Top 5 files with highest coverage:');
  for (int i = 0; i < 5 && i < filesCoveragePercentage.length; i++) {
    final entry = filesCoveragePercentage[i];
    final total = fileCoverage[entry.key]!['total']!;
    final covered = fileCoverage[entry.key]!['covered']!;
    print('   ✅ ${entry.key}: ${entry.value.toStringAsFixed(2)}% ($covered/$total)');
  }
  
  // Tạo JSON report
  final jsonReport = {
    'timestamp': DateTime.now().toIso8601String(),
    'overall_coverage': double.parse(overallCoverage),
    'total_lines': totalLines,
    'covered_lines': coveredLines,
    'files': fileCoverage.entries.map((entry) {
      final total = entry.value['total']!;
      final covered = entry.value['covered']!;
      return {
        'name': entry.key,
        'total_lines': total,
        'covered_lines': covered,
        'coverage_percent': total > 0 ? (covered / total * 100) : 0,
      };
    }).toList()
  };
  
  // Save JSON report
  final jsonReportFile = File('coverage/coverage_report.json');
  await jsonReportFile.writeAsString(jsonEncode(jsonReport));
  
  print('\n✅ JSON report created at coverage/coverage_report.json');
  
  // Ghi thêm vào history
  await _updateCoverageHistory(double.parse(overallCoverage));
}

/// Cập nhật lịch sử coverage
Future<void> _updateCoverageHistory(double currentCoverage) async {
  final historyFile = File('coverage/coverage_history.json');
  List<Map<String, dynamic>> history = [];
  
  if (await historyFile.exists()) {
    final content = await historyFile.readAsString();
    history = List<Map<String, dynamic>>.from(jsonDecode(content));
  }
  
  history.add({
    'date': DateTime.now().toIso8601String(),
    'coverage': currentCoverage,
  });
  
  await historyFile.writeAsString(jsonEncode(history));
  print('✅ Updated coverage history at coverage/coverage_history.json');
  
  // Hiển thị xu hướng coverage
  if (history.length > 1) {
    final previousCoverage = history[history.length - 2]['coverage'] as double;
    final diff = currentCoverage - previousCoverage;
    final trend = diff >= 0 ? '📈 +${diff.toStringAsFixed(2)}%' : '📉 ${diff.toStringAsFixed(2)}%';
    print('\n📊 Coverage trend: $trend compared to previous run');
  }
}

/// Tiện ích chạy lệnh và hiển thị output
Future<void> _runCommand(String command, List<String> args, {String? workingDirectory}) async {
  print('🔧 Running: $command ${args.join(' ')}');
  
  final result = await Process.run(
    command, 
    args,
    workingDirectory: workingDirectory ?? Directory.current.path,
    runInShell: true
  );
  
  if (result.exitCode != 0) {
    print('⚠️ Command failed with exit code ${result.exitCode}');
    print(result.stderr);
  }
  
  // Hiển thị output cho debugging
  // print(result.stdout);
} 