# Code Review & Team Collaboration Automation Rules

**Type**: Auto  
**Description**: Automated code review processes, team collaboration standards, and knowledge sharing mechanisms for enterprise messaging app development

## Automated Code Review System

### Pre-Review Validation
```dart
class AutomatedCodeReview {
  static const Map<String, ReviewCriteria> reviewCriteria = {
    'architecture_compliance': ReviewCriteria(
      weight: 0.25,
      validator: ArchitectureValidator.validate,
      autoFix: false,
      blockingLevel: BlockingLevel.error,
    ),
    'performance_impact': ReviewCriteria(
      weight: 0.20,
      validator: PerformanceValidator.validate,
      autoFix: false,
      blockingLevel: BlockingLevel.warning,
    ),
    'security_vulnerabilities': ReviewCriteria(
      weight: 0.20,
      validator: SecurityValidator.validate,
      autoFix: false,
      blockingLevel: BlockingLevel.error,
    ),
    'test_coverage': ReviewCriteria(
      weight: 0.15,
      validator: TestCoverageValidator.validate,
      autoFix: false,
      blockingLevel: BlockingLevel.error,
    ),
    'code_quality': ReviewCriteria(
      weight: 0.10,
      validator: CodeQualityValidator.validate,
      autoFix: true,
      blockingLevel: BlockingLevel.warning,
    ),
    'documentation': ReviewCriteria(
      weight: 0.10,
      validator: DocumentationValidator.validate,
      autoFix: true,
      blockingLevel: BlockingLevel.info,
    ),
  };
  
  static Future<ReviewResult> performAutomatedReview(
    PullRequest pullRequest,
  ) async {
    final results = <String, ValidationResult>{};
    final autoFixApplied = <String>[];
    
    print('🔍 Starting automated review for PR #${pullRequest.number}');
    
    for (final entry in reviewCriteria.entries) {
      final criteriaName = entry.key;
      final criteria = entry.value;
      
      print('  📋 Validating $criteriaName...');
      
      try {
        final result = await criteria.validator(pullRequest);
        results[criteriaName] = result;
        
        // Apply auto-fixes if available and needed
        if (!result.passed && criteria.autoFix) {
          await _applyAutoFix(criteriaName, pullRequest);
          autoFixApplied.add(criteriaName);
        }
        
        print('    ${result.passed ? '✅' : '❌'} $criteriaName: ${result.message}');
        
      } catch (e) {
        print('    ⚠️ Error validating $criteriaName: $e');
        results[criteriaName] = ValidationResult.error(e.toString());
      }
    }
    
    final overallScore = _calculateOverallScore(results);
    final recommendation = _generateRecommendation(results, overallScore);
    
    return ReviewResult(
      pullRequest: pullRequest,
      score: overallScore,
      results: results,
      recommendation: recommendation,
      autoFixesApplied: autoFixApplied,
      timestamp: DateTime.now(),
    );
  }
  
  static double _calculateOverallScore(Map<String, ValidationResult> results) {
    double totalScore = 0;
    double totalWeight = 0;
    
    for (final entry in reviewCriteria.entries) {
      final result = results[entry.key];
      if (result != null && !result.isError) {
        totalScore += (result.passed ? 1.0 : 0.0) * entry.value.weight;
        totalWeight += entry.value.weight;
      }
    }
    
    return totalWeight > 0 ? totalScore / totalWeight : 0;
  }
}
```

### Architecture Compliance Validation
```dart
class ArchitectureValidator {
  static Future<ValidationResult> validate(PullRequest pr) async {
    final violations = <ArchitectureViolation>[];
    
    // Check Clean Architecture compliance
    violations.addAll(await _checkCleanArchitecture(pr.changedFiles));
    
    // Check dependency injection patterns
    violations.addAll(await _checkDependencyInjection(pr.changedFiles));
    
    // Check BLoC pattern compliance
    violations.addAll(await _checkBlocPatterns(pr.changedFiles));
    
    // Check API integration patterns
    violations.addAll(await _checkApiIntegration(pr.changedFiles));
    
    if (violations.isEmpty) {
      return ValidationResult.success('Architecture compliance verified');
    }
    
    return ValidationResult.failure(
      'Architecture violations found',
      details: violations.map((v) => v.description).toList(),
    );
  }
  
  static Future<List<ArchitectureViolation>> _checkCleanArchitecture(
    List<ChangedFile> files,
  ) async {
    final violations = <ArchitectureViolation>[];
    
    for (final file in files) {
      // Check layer separation
      if (file.path.contains('domain/') && _hasUIImports(file.content)) {
        violations.add(ArchitectureViolation(
          type: ViolationType.layerViolation,
          file: file.path,
          line: _findUIImportLine(file.content),
          description: 'Domain layer should not import UI dependencies',
          severity: Severity.error,
        ));
      }
      
      // Check dependency flow
      if (file.path.contains('data/') && _hasDirectUIAccess(file.content)) {
        violations.add(ArchitectureViolation(
          type: ViolationType.dependencyViolation,
          file: file.path,
          line: _findDirectUIAccessLine(file.content),
          description: 'Data layer should not directly access UI layer',
          severity: Severity.error,
        ));
      }
      
      // Check use case patterns
      if (file.path.contains('usecases/') && !_followsUseCasePattern(file.content)) {
        violations.add(ArchitectureViolation(
          type: ViolationType.patternViolation,
          file: file.path,
          description: 'Use case should follow standard pattern with call() method',
          severity: Severity.warning,
        ));
      }
    }
    
    return violations;
  }
}
```

### Performance Impact Analysis
```dart
class PerformanceValidator {
  static Future<ValidationResult> validate(PullRequest pr) async {
    final impacts = <PerformanceImpact>[];
    
    // Analyze memory impact
    impacts.addAll(await _analyzeMemoryImpact(pr.changedFiles));
    
    // Analyze CPU impact
    impacts.addAll(await _analyzeCPUImpact(pr.changedFiles));
    
    // Analyze network impact
    impacts.addAll(await _analyzeNetworkImpact(pr.changedFiles));
    
    // Analyze UI performance impact
    impacts.addAll(await _analyzeUIPerformanceImpact(pr.changedFiles));
    
    final criticalImpacts = impacts.where((i) => i.severity == Severity.critical).toList();
    
    if (criticalImpacts.isNotEmpty) {
      return ValidationResult.failure(
        'Critical performance impacts detected',
        details: criticalImpacts.map((i) => i.description).toList(),
      );
    }
    
    final highImpacts = impacts.where((i) => i.severity == Severity.high).toList();
    if (highImpacts.isNotEmpty) {
      return ValidationResult.warning(
        'High performance impacts detected',
        details: highImpacts.map((i) => i.description).toList(),
      );
    }
    
    return ValidationResult.success('No significant performance impacts detected');
  }
  
  static Future<List<PerformanceImpact>> _analyzeMemoryImpact(
    List<ChangedFile> files,
  ) async {
    final impacts = <PerformanceImpact>[];
    
    for (final file in files) {
      // Check for memory leaks
      if (_hasStreamControllerWithoutDispose(file.content)) {
        impacts.add(PerformanceImpact(
          type: ImpactType.memoryLeak,
          file: file.path,
          description: 'StreamController created without proper disposal',
          severity: Severity.high,
          estimatedImpact: 'Potential memory leak',
        ));
      }
      
      // Check for large object creation
      if (_hasLargeObjectCreation(file.content)) {
        impacts.add(PerformanceImpact(
          type: ImpactType.memoryUsage,
          file: file.path,
          description: 'Large object creation detected',
          severity: Severity.medium,
          estimatedImpact: 'Increased memory usage',
        ));
      }
      
      // Check for inefficient collections
      if (_hasInefficientCollectionUsage(file.content)) {
        impacts.add(PerformanceImpact(
          type: ImpactType.memoryUsage,
          file: file.path,
          description: 'Inefficient collection usage',
          severity: Severity.medium,
          estimatedImpact: 'Higher memory consumption',
        ));
      }
    }
    
    return impacts;
  }
}
```

## Team Collaboration Standards

### Code Review Assignment
```dart
class ReviewAssignmentManager {
  static const Map<String, ReviewerExpertise> teamExpertise = {
    'senior_architect': ReviewerExpertise(
      areas: ['architecture', 'performance', 'security'],
      maxReviews: 5,
      priority: 1,
    ),
    'flutter_expert': ReviewerExpertise(
      areas: ['ui', 'widgets', 'animations'],
      maxReviews: 8,
      priority: 2,
    ),
    'backend_expert': ReviewerExpertise(
      areas: ['api', 'database', 'integration'],
      maxReviews: 6,
      priority: 2,
    ),
    'testing_expert': ReviewerExpertise(
      areas: ['testing', 'quality_assurance'],
      maxReviews: 10,
      priority: 3,
    ),
  };
  
  static Future<List<String>> assignReviewers(PullRequest pr) async {
    final requiredAreas = await _analyzeRequiredExpertise(pr);
    final availableReviewers = await _getAvailableReviewers();
    
    final assignments = <String>[];
    
    // Always assign senior architect for architecture changes
    if (requiredAreas.contains('architecture')) {
      assignments.add('senior_architect');
    }
    
    // Assign specialists based on changed areas
    for (final area in requiredAreas) {
      final specialist = _findBestSpecialist(area, availableReviewers);
      if (specialist != null && !assignments.contains(specialist)) {
        assignments.add(specialist);
      }
    }
    
    // Ensure minimum 2 reviewers
    while (assignments.length < 2 && availableReviewers.isNotEmpty) {
      final reviewer = availableReviewers.removeAt(0);
      if (!assignments.contains(reviewer)) {
        assignments.add(reviewer);
      }
    }
    
    return assignments;
  }
  
  static Future<List<String>> _analyzeRequiredExpertise(PullRequest pr) async {
    final areas = <String>{};
    
    for (final file in pr.changedFiles) {
      if (file.path.contains('domain/') || file.path.contains('data/')) {
        areas.add('architecture');
      }
      if (file.path.contains('presentation/') || file.path.contains('widgets/')) {
        areas.add('ui');
      }
      if (file.path.contains('api/') || file.path.contains('datasources/')) {
        areas.add('api');
      }
      if (file.path.contains('test/')) {
        areas.add('testing');
      }
      if (_hasPerformanceCriticalChanges(file.content)) {
        areas.add('performance');
      }
      if (_hasSecurityImplications(file.content)) {
        areas.add('security');
      }
    }
    
    return areas.toList();
  }
}
```

### Knowledge Sharing Automation
```dart
class KnowledgeSharingManager {
  static Future<void> generateKnowledgeArtifacts(PullRequest pr) async {
    // Generate architecture decision records
    if (await _hasArchitecturalChanges(pr)) {
      await _generateADR(pr);
    }
    
    // Update team documentation
    if (await _hasNewPatterns(pr)) {
      await _updatePatternDocumentation(pr);
    }
    
    // Create learning materials
    if (await _hasComplexImplementation(pr)) {
      await _createLearningMaterial(pr);
    }
    
    // Schedule knowledge sharing session
    if (await _requiresTeamDiscussion(pr)) {
      await _scheduleKnowledgeSession(pr);
    }
  }
  
  static Future<void> _generateADR(PullRequest pr) async {
    final adr = ArchitectureDecisionRecord(
      title: 'ADR-${DateTime.now().millisecondsSinceEpoch}: ${pr.title}',
      status: ADRStatus.proposed,
      context: await _extractContext(pr),
      decision: await _extractDecision(pr),
      consequences: await _analyzeConsequences(pr),
      alternatives: await _identifyAlternatives(pr),
    );
    
    await ADRStorage.store(adr);
    await _notifyTeamOfNewADR(adr);
  }
  
  static Future<void> _updatePatternDocumentation(PullRequest pr) async {
    final patterns = await _extractNewPatterns(pr);
    
    for (final pattern in patterns) {
      final documentation = PatternDocumentation(
        name: pattern.name,
        description: pattern.description,
        implementation: pattern.codeExample,
        useCases: pattern.useCases,
        bestPractices: pattern.bestPractices,
        antiPatterns: pattern.antiPatterns,
      );
      
      await PatternRegistry.register(documentation);
    }
  }
}
```

## Automated Quality Gates

### Quality Gate Configuration
```yaml
# .augment/config/quality-gates.yml
quality_gates:
  pre_merge:
    - name: "Architecture Compliance"
      threshold: 100
      blocking: true
      
    - name: "Test Coverage"
      threshold: 90
      blocking: true
      
    - name: "Performance Benchmarks"
      threshold: 95
      blocking: true
      
    - name: "Security Scan"
      threshold: 100
      blocking: true
      
    - name: "Code Quality"
      threshold: 85
      blocking: false
      
  post_merge:
    - name: "Integration Tests"
      threshold: 100
      blocking: false
      
    - name: "Performance Monitoring"
      threshold: 90
      blocking: false
      
    - name: "User Acceptance"
      threshold: 80
      blocking: false
```

### Automated Feedback System
```dart
class FeedbackSystem {
  static Future<void> provideFeedback(
    PullRequest pr,
    ReviewResult result,
  ) async {
    // Generate detailed feedback
    final feedback = await _generateDetailedFeedback(result);
    
    // Post review comments
    await _postReviewComments(pr, feedback);
    
    // Update PR status
    await _updatePRStatus(pr, result);
    
    // Notify team if needed
    if (result.score < 0.7) {
      await _notifyTeamLead(pr, result);
    }
    
    // Schedule follow-up if needed
    if (result.hasBlockingIssues) {
      await _scheduleFollowUp(pr, result);
    }
  }
  
  static Future<ReviewFeedback> _generateDetailedFeedback(
    ReviewResult result,
  ) async {
    final suggestions = <Suggestion>[];
    final compliments = <String>[];
    
    // Generate specific suggestions
    for (final entry in result.results.entries) {
      if (!entry.value.passed) {
        suggestions.addAll(await _generateSuggestions(entry.key, entry.value));
      } else {
        compliments.add('Great work on ${entry.key}!');
      }
    }
    
    return ReviewFeedback(
      overallScore: result.score,
      suggestions: suggestions,
      compliments: compliments,
      nextSteps: await _generateNextSteps(result),
    );
  }
}
```

## Continuous Improvement

### Review Analytics
```dart
class ReviewAnalytics {
  static Future<void> trackReviewMetrics() async {
    final metrics = await _collectReviewMetrics();
    
    // Track review effectiveness
    await _trackReviewEffectiveness(metrics);
    
    // Identify improvement opportunities
    await _identifyImprovementOpportunities(metrics);
    
    // Generate team insights
    await _generateTeamInsights(metrics);
    
    // Update review processes
    await _updateReviewProcesses(metrics);
  }
  
  static Future<ReviewMetrics> _collectReviewMetrics() async {
    final recentReviews = await ReviewStorage.getRecentReviews(
      Duration(days: 30),
    );
    
    return ReviewMetrics(
      totalReviews: recentReviews.length,
      averageReviewTime: _calculateAverageReviewTime(recentReviews),
      averageScore: _calculateAverageScore(recentReviews),
      commonIssues: _identifyCommonIssues(recentReviews),
      reviewerPerformance: _analyzeReviewerPerformance(recentReviews),
      improvementTrends: _analyzeImprovementTrends(recentReviews),
    );
  }
}
```
