# Git Workflow Automation Rules - Enterprise Messaging App

**Type**: Always  
**Description**: Automated git workflow with standardized commit patterns, team collaboration protocols, and CI/CD integration for Flutter messaging app

## Commit Message Standards

### Conventional Commits Format
```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Messaging App Specific Types
```bash
# Feature Development
feat(messaging): implement real-time message delivery optimization
feat(ui): add message status indicators with read receipts
feat(offline): implement offline message queue with sync strategy
feat(auth): add JWT token refresh mechanism
feat(media): optimize image compression for mobile networks

# Bug Fixes
fix(websocket): resolve connection drops during network switching
fix(memory): prevent memory leaks in message list scrolling
fix(sync): fix duplicate messages during offline sync
fix(ui): resolve keyboard overlap in message input
fix(performance): optimize BLoC state updates for large conversations

# Performance Improvements
perf(messaging): reduce message delivery latency to <100ms
perf(ui): implement virtual scrolling for 10k+ messages
perf(memory): optimize message caching strategy
perf(network): implement request batching for API calls
perf(startup): reduce app startup time to <2s

# Refactoring
refactor(architecture): migrate to Clean Architecture pattern
refactor(state): consolidate duplicate BLoC implementations
refactor(api): standardize error handling across data sources
refactor(testing): improve test coverage to >90%

# Documentation
docs(api): update GraphQL schema documentation
docs(architecture): document messaging flow patterns
docs(deployment): update CI/CD pipeline documentation

# CI/CD and DevOps
ci(testing): add automated performance benchmarks
ci(deployment): implement blue-green deployment strategy
ci(monitoring): add comprehensive logging and metrics
```

### Scope Guidelines
```bash
# Core Features
messaging, chat, user, auth, offline, sync, media, notifications

# Technical Areas
api, websocket, database, cache, performance, security, testing

# UI Components
ui, widgets, screens, navigation, animations, themes

# Infrastructure
ci, deployment, monitoring, logging, analytics
```

## Automated Commit Triggers

### Feature Completion Triggers
```dart
class GitWorkflowAutomation {
  static const List<String> autoCommitTriggers = [
    'feature_complete',
    'tests_passed',
    'code_review_approved',
    'performance_benchmarks_met',
    'security_scan_passed',
  ];
  
  static Future<void> handleFeatureCompletion(
    String featureName,
    String featureType,
    List<String> modifiedFiles,
  ) async {
    // 1. Run pre-commit checks
    await _runPreCommitChecks();
    
    // 2. Generate commit message
    final commitMessage = _generateCommitMessage(
      featureName,
      featureType,
      modifiedFiles,
    );
    
    // 3. Stage and commit changes
    await _stageAndCommit(commitMessage);
    
    // 4. Run post-commit actions
    await _runPostCommitActions();
    
    // 5. Push to remote if all checks pass
    await _pushToRemote();
  }
  
  static String _generateCommitMessage(
    String featureName,
    String featureType,
    List<String> modifiedFiles,
  ) {
    final scope = _determineScope(modifiedFiles);
    final type = _mapFeatureTypeToCommitType(featureType);
    
    return '''$type($scope): $featureName

Modified files:
${modifiedFiles.map((f) => '- $f').join('\n')}

Performance impact: ${_analyzePerformanceImpact(modifiedFiles)}
Test coverage: ${_calculateTestCoverage()}
Breaking changes: ${_checkBreakingChanges(modifiedFiles)}

Co-authored-by: Augment AI <ai@augmentcode.com>''';
  }
}
```

### Pre-commit Validation
```bash
#!/bin/bash
# .augment/scripts/pre-commit-validation.sh

echo "🔍 Running pre-commit validation..."

# 1. Code formatting
echo "📝 Checking code formatting..."
dart format --set-exit-if-changed lib/ test/
if [ $? -ne 0 ]; then
    echo "❌ Code formatting failed. Run 'dart format lib/ test/' to fix."
    exit 1
fi

# 2. Static analysis
echo "🔍 Running static analysis..."
dart analyze --fatal-infos
if [ $? -ne 0 ]; then
    echo "❌ Static analysis failed. Fix issues before committing."
    exit 1
fi

# 3. Unit tests
echo "🧪 Running unit tests..."
flutter test --coverage
if [ $? -ne 0 ]; then
    echo "❌ Unit tests failed. Fix failing tests before committing."
    exit 1
fi

# 4. Test coverage check
echo "📊 Checking test coverage..."
COVERAGE=$(lcov --summary coverage/lcov.info | grep "lines" | awk '{print $2}' | sed 's/%//')
if (( $(echo "$COVERAGE < 90" | bc -l) )); then
    echo "❌ Test coverage ($COVERAGE%) is below 90% threshold."
    exit 1
fi

# 5. Performance benchmarks
echo "⚡ Running performance benchmarks..."
flutter test integration_test/performance_test.dart
if [ $? -ne 0 ]; then
    echo "❌ Performance benchmarks failed."
    exit 1
fi

# 6. Security scan
echo "🔒 Running security scan..."
dart pub deps --json | dart run security_scan
if [ $? -ne 0 ]; then
    echo "❌ Security vulnerabilities detected."
    exit 1
fi

# 5. File length validation
echo "📏 Checking file length compliance..."
.augment/scripts/file-length-validator.sh
if [ $? -ne 0 ]; then
    echo "❌ File length violations detected."
    echo "Please refactor large files before committing."
    echo "See .augment/rules/core/file_length_management.md for guidelines."
    exit 1
fi

echo "✅ All pre-commit checks passed!"
```

## Team Collaboration Patterns

### Branch Naming Convention
```bash
# Feature branches
feature/messaging-real-time-optimization
feature/ui-message-status-indicators
feature/offline-sync-improvements
feature/auth-jwt-refresh

# Bug fix branches
fix/websocket-connection-drops
fix/memory-leak-message-list
fix/duplicate-messages-sync

# Performance branches
perf/message-delivery-latency
perf/virtual-scrolling-implementation
perf/startup-time-optimization

# Refactoring branches
refactor/clean-architecture-migration
refactor/bloc-consolidation
refactor/error-handling-standardization
```

### Pull Request Automation
```yaml
# .augment/workflows/pr-automation.yml
name: Pull Request Automation

on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  automated-review:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
        
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        
      - name: Run automated checks
        run: |
          .augment/scripts/pre-commit-validation.sh
          
      - name: Performance benchmarks
        run: |
          flutter test integration_test/performance_test.dart
          
      - name: Generate performance report
        run: |
          dart run performance_analyzer --generate-report
          
      - name: Auto-approve if criteria met
        if: success()
        run: |
          gh pr review --approve --body "✅ Automated review passed all criteria"
          
      - name: Auto-merge if approved
        if: success()
        run: |
          gh pr merge --squash --delete-branch
```

## Error Handling Scenarios

### Merge Conflict Resolution
```dart
class MergeConflictHandler {
  static Future<void> handleMergeConflict(
    String branchName,
    List<String> conflictedFiles,
  ) async {
    print('🔄 Merge conflict detected in branch: $branchName');
    print('📁 Conflicted files: ${conflictedFiles.join(', ')}');
    
    // 1. Analyze conflict complexity
    final conflictComplexity = await _analyzeConflictComplexity(conflictedFiles);
    
    if (conflictComplexity == ConflictComplexity.simple) {
      // Auto-resolve simple conflicts
      await _autoResolveSimpleConflicts(conflictedFiles);
    } else {
      // Create detailed conflict report for manual resolution
      await _createConflictReport(branchName, conflictedFiles);
      await _notifyTeamLead(branchName, conflictedFiles);
    }
  }
  
  static Future<void> _autoResolveSimpleConflicts(
    List<String> conflictedFiles,
  ) async {
    for (final file in conflictedFiles) {
      if (file.endsWith('.dart')) {
        await _resolveDartFileConflict(file);
      } else if (file.endsWith('.yaml') || file.endsWith('.yml')) {
        await _resolveYamlFileConflict(file);
      }
    }
    
    // Commit resolved conflicts
    await Process.run('git', ['add', '.']);
    await Process.run('git', [
      'commit',
      '-m',
      'resolve: auto-resolve merge conflicts\n\nFiles resolved:\n${conflictedFiles.map((f) => '- $f').join('\n')}'
    ]);
  }
}
```

### Push Failure Recovery
```dart
class PushFailureHandler {
  static Future<void> handlePushFailure(
    String error,
    String branchName,
  ) async {
    if (error.contains('rejected')) {
      // Handle rejected push (usually due to remote changes)
      await _handleRejectedPush(branchName);
    } else if (error.contains('network')) {
      // Handle network issues
      await _handleNetworkFailure(branchName);
    } else if (error.contains('authentication')) {
      // Handle authentication issues
      await _handleAuthFailure();
    } else {
      // Handle unknown errors
      await _handleUnknownError(error, branchName);
    }
  }
  
  static Future<void> _handleRejectedPush(String branchName) async {
    print('🔄 Push rejected, attempting to rebase...');
    
    // Fetch latest changes
    await Process.run('git', ['fetch', 'origin']);
    
    // Rebase current branch
    final rebaseResult = await Process.run('git', [
      'rebase',
      'origin/main',
    ]);
    
    if (rebaseResult.exitCode == 0) {
      // Rebase successful, try push again
      await Process.run('git', ['push', 'origin', branchName]);
      print('✅ Push successful after rebase');
    } else {
      // Rebase failed, handle conflicts
      await MergeConflictHandler.handleMergeConflict(
        branchName,
        await _getConflictedFiles(),
      );
    }
  }
}
```

## CI/CD Pipeline Integration

### Automated Deployment Triggers
```yaml
# .augment/workflows/deployment.yml
name: Automated Deployment

on:
  push:
    branches: [main, develop]
    paths:
      - 'lib/**'
      - 'test/**'
      - 'pubspec.yaml'

jobs:
  deploy:
    if: contains(github.event.head_commit.message, 'feat(') || contains(github.event.head_commit.message, 'fix(')
    runs-on: ubuntu-latest
    
    steps:
      - name: Extract commit info
        id: commit_info
        run: |
          echo "type=$(echo '${{ github.event.head_commit.message }}' | grep -oP '^[^(]+' | head -1)" >> $GITHUB_OUTPUT
          echo "scope=$(echo '${{ github.event.head_commit.message }}' | grep -oP '\(\K[^)]+' | head -1)" >> $GITHUB_OUTPUT
          
      - name: Deploy to staging
        if: steps.commit_info.outputs.type == 'feat'
        run: |
          echo "🚀 Deploying feature to staging environment"
          # Deploy to staging logic here
          
      - name: Deploy hotfix to production
        if: steps.commit_info.outputs.type == 'fix' && steps.commit_info.outputs.scope == 'critical'
        run: |
          echo "🔥 Deploying critical fix to production"
          # Deploy to production logic here
          
      - name: Update performance metrics
        run: |
          dart run performance_tracker --update-metrics
          
      - name: Notify team
        run: |
          curl -X POST $SLACK_WEBHOOK \
            -H 'Content-type: application/json' \
            --data '{"text":"✅ Deployment completed: ${{ github.event.head_commit.message }}"}'
```

### Quality Gates
```dart
class QualityGateValidator {
  static Future<bool> validateQualityGates() async {
    final results = await Future.wait([
      _checkTestCoverage(),
      _checkPerformanceBenchmarks(),
      _checkSecurityScan(),
      _checkCodeQuality(),
      _checkDocumentation(),
    ]);
    
    return results.every((result) => result);
  }
  
  static Future<bool> _checkPerformanceBenchmarks() async {
    final benchmarks = await PerformanceBenchmark.run();
    
    return benchmarks.startupTime < Duration(seconds: 2) &&
           benchmarks.messageDeliveryTime < Duration(milliseconds: 100) &&
           benchmarks.memoryUsage < 150 * 1024 * 1024; // 150MB
  }
  
  static Future<bool> _checkTestCoverage() async {
    final coverage = await TestCoverageAnalyzer.analyze();
    return coverage.overall >= 0.90; // 90% minimum
  }
}
```

## Integration với Development Workflow

### IDE Integration
```json
{
  "augment.rules.git": {
    "autoCommitOnFeatureComplete": true,
    "enforceConventionalCommits": true,
    "runPreCommitChecks": true,
    "autoGenerateCommitMessages": true,
    "integrateCIPipeline": true
  },
  "augment.git.hooks": {
    "pre-commit": ".augment/scripts/pre-commit-validation.sh",
    "commit-msg": ".augment/scripts/validate-commit-message.sh",
    "post-commit": ".augment/scripts/post-commit-actions.sh"
  }
}
```

### Team Notification System
```dart
class TeamNotificationService {
  static Future<void> notifyFeatureCompletion(
    String featureName,
    String developer,
    String commitHash,
  ) async {
    final message = '''
🎉 Feature completed: $featureName
👨‍💻 Developer: $developer
📝 Commit: $commitHash
🔗 View changes: ${_generateCommitUrl(commitHash)}
📊 Performance impact: ${await _getPerformanceImpact(commitHash)}
🧪 Test coverage: ${await _getTestCoverage(commitHash)}
    ''';
    
    await _sendSlackNotification(message);
    await _updateJiraTicket(featureName, 'completed');
    await _triggerCodeReview(commitHash);
  }
}
```
