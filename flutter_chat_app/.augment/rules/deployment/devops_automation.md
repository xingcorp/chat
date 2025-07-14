# DevOps & Deployment Automation Rules - Enterprise Messaging Platform

**Type**: Auto  
**Description**: Comprehensive DevOps automation with blue-green deployment, monitoring, and enterprise-scale infrastructure management

## Deployment Architecture

### Multi-Environment Strategy
```yaml
# .augment/config/environments.yml
environments:
  development:
    flutter_channel: "stable"
    build_mode: "debug"
    api_endpoint: "https://dev-api.chatapp.com"
    websocket_endpoint: "wss://dev-ws.chatapp.com"
    monitoring_enabled: false
    
  staging:
    flutter_channel: "stable"
    build_mode: "profile"
    api_endpoint: "https://staging-api.chatapp.com"
    websocket_endpoint: "wss://staging-ws.chatapp.com"
    monitoring_enabled: true
    performance_testing: true
    
  production:
    flutter_channel: "stable"
    build_mode: "release"
    api_endpoint: "https://api.chatapp.com"
    websocket_endpoint: "wss://ws.chatapp.com"
    monitoring_enabled: true
    performance_testing: true
    security_scanning: true
    compliance_checks: true
```

### Blue-Green Deployment Strategy
```dart
class BlueGreenDeploymentManager {
  static const Duration healthCheckTimeout = Duration(minutes: 5);
  static const Duration rollbackTimeout = Duration(minutes: 2);
  
  static Future<DeploymentResult> deployToProduction(
    String buildVersion,
    DeploymentEnvironment targetSlot,
  ) async {
    try {
      // 1. Pre-deployment validation
      await _validateDeploymentReadiness(buildVersion);
      
      // 2. Deploy to inactive slot (green)
      await _deployToSlot(buildVersion, targetSlot);
      
      // 3. Run health checks
      final healthCheckResult = await _runHealthChecks(targetSlot);
      if (!healthCheckResult.isHealthy) {
        throw DeploymentException('Health checks failed: ${healthCheckResult.errors}');
      }
      
      // 4. Run smoke tests
      final smokeTestResult = await _runSmokeTests(targetSlot);
      if (!smokeTestResult.passed) {
        throw DeploymentException('Smoke tests failed: ${smokeTestResult.failures}');
      }
      
      // 5. Switch traffic to new slot
      await _switchTraffic(targetSlot);
      
      // 6. Monitor for issues
      final monitoringResult = await _monitorDeployment(Duration(minutes: 10));
      if (!monitoringResult.isStable) {
        // Auto-rollback if issues detected
        await _rollbackDeployment();
        throw DeploymentException('Deployment unstable, rolled back');
      }
      
      // 7. Mark old slot as inactive
      await _deactivateOldSlot();
      
      return DeploymentResult.success(
        version: buildVersion,
        deployedAt: DateTime.now(),
        slot: targetSlot,
      );
      
    } catch (e) {
      await _handleDeploymentFailure(e, buildVersion);
      rethrow;
    }
  }
  
  static Future<void> _runHealthChecks(DeploymentEnvironment slot) async {
    final checks = [
      _checkAPIHealth(slot),
      _checkWebSocketHealth(slot),
      _checkDatabaseConnectivity(slot),
      _checkRedisConnectivity(slot),
      _checkExternalServicesHealth(slot),
    ];
    
    final results = await Future.wait(checks);
    final failures = results.where((r) => !r.isHealthy).toList();
    
    if (failures.isNotEmpty) {
      throw HealthCheckException('Health checks failed: $failures');
    }
  }
}
```

### Container Orchestration
```yaml
# .augment/k8s/deployment.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flutter-chat-app
  namespace: messaging
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: flutter-chat-app
  template:
    metadata:
      labels:
        app: flutter-chat-app
        version: "{{BUILD_VERSION}}"
    spec:
      containers:
      - name: flutter-chat-app
        image: "registry.chatapp.com/flutter-chat-app:{{BUILD_VERSION}}"
        ports:
        - containerPort: 8080
        env:
        - name: ENVIRONMENT
          value: "{{ENVIRONMENT}}"
        - name: API_ENDPOINT
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: api-endpoint
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
```

## CI/CD Pipeline Automation

### Advanced Pipeline Configuration
```yaml
# .augment/ci/pipeline.yml
name: Flutter Chat App CI/CD

on:
  push:
    branches: [main, develop, 'release/*']
  pull_request:
    branches: [main, develop]

env:
  FLUTTER_VERSION: "3.16.0"
  JAVA_VERSION: "17"
  NODE_VERSION: "18"

jobs:
  code-quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          
      - name: Install dependencies
        run: flutter pub get
        
      - name: Code formatting check
        run: dart format --set-exit-if-changed lib/ test/
        
      - name: Static analysis
        run: flutter analyze --fatal-infos
        
      - name: Security scan
        run: |
          dart pub global activate security_scan
          dart pub global run security_scan
          
  testing:
    needs: code-quality
    runs-on: ubuntu-latest
    strategy:
      matrix:
        test-type: [unit, widget, integration]
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        
      - name: Run ${{ matrix.test-type }} tests
        run: |
          case "${{ matrix.test-type }}" in
            "unit")
              flutter test --coverage test/unit/
              ;;
            "widget")
              flutter test --coverage test/widget/
              ;;
            "integration")
              flutter test integration_test/
              ;;
          esac
          
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: coverage/lcov.info
          
  performance-testing:
    needs: testing
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        
      - name: Build performance test app
        run: flutter build apk --profile
        
      - name: Run performance benchmarks
        run: |
          flutter test integration_test/performance_test.dart
          dart run performance_analyzer --generate-report
          
      - name: Validate performance metrics
        run: |
          dart run performance_validator \
            --startup-time-limit 2000 \
            --memory-limit 157286400 \
            --message-delivery-limit 100
            
  build:
    needs: [testing, performance-testing]
    runs-on: ubuntu-latest
    strategy:
      matrix:
        platform: [android, ios, web]
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        
      - name: Build ${{ matrix.platform }}
        run: |
          case "${{ matrix.platform }}" in
            "android")
              flutter build apk --release
              flutter build appbundle --release
              ;;
            "ios")
              flutter build ios --release --no-codesign
              ;;
            "web")
              flutter build web --release
              ;;
          esac
          
      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: ${{ matrix.platform }}-build
          path: build/
          
  deploy-staging:
    if: github.ref == 'refs/heads/develop'
    needs: build
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - name: Deploy to staging
        run: |
          echo "🚀 Deploying to staging environment"
          # Deployment logic here
          
      - name: Run E2E tests
        run: |
          npm install -g @playwright/test
          npx playwright test e2e/
          
      - name: Performance monitoring
        run: |
          dart run performance_monitor --environment staging
          
  deploy-production:
    if: github.ref == 'refs/heads/main'
    needs: build
    runs-on: ubuntu-latest
    environment: production
    steps:
      - name: Blue-Green deployment
        run: |
          dart run deployment_manager \
            --strategy blue-green \
            --environment production \
            --version ${{ github.sha }}
            
      - name: Post-deployment verification
        run: |
          dart run deployment_verifier \
            --environment production \
            --timeout 300
```

## Infrastructure as Code

### Terraform Configuration
```hcl
# .augment/terraform/main.tf
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

# EKS Cluster for Flutter Chat App
resource "aws_eks_cluster" "flutter_chat_cluster" {
  name     = "flutter-chat-${var.environment}"
  role_arn = aws_iam_role.cluster_role.arn
  version  = "1.28"

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = var.allowed_cidrs
  }

  encryption_config {
    provider {
      key_arn = aws_kms_key.cluster_encryption.arn
    }
    resources = ["secrets"]
  }

  enabled_cluster_log_types = [
    "api", "audit", "authenticator", "controllerManager", "scheduler"
  ]

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
    aws_iam_role_policy_attachment.service_policy,
  ]
}

# Auto Scaling Group for worker nodes
resource "aws_eks_node_group" "flutter_chat_nodes" {
  cluster_name    = aws_eks_cluster.flutter_chat_cluster.name
  node_group_name = "flutter-chat-nodes"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = var.private_subnet_ids

  instance_types = ["t3.medium", "t3.large"]
  capacity_type  = "ON_DEMAND"

  scaling_config {
    desired_size = 3
    max_size     = 10
    min_size     = 2
  }

  update_config {
    max_unavailable_percentage = 25
  }

  # Ensure proper ordering of resource creation
  depends_on = [
    aws_iam_role_policy_attachment.node_policy,
    aws_iam_role_policy_attachment.cni_policy,
    aws_iam_role_policy_attachment.registry_policy,
  ]
}

# Application Load Balancer
resource "aws_lb" "flutter_chat_alb" {
  name               = "flutter-chat-alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = var.environment == "production"

  access_logs {
    bucket  = aws_s3_bucket.alb_logs.bucket
    prefix  = "flutter-chat-alb"
    enabled = true
  }
}

# RDS for application data
resource "aws_rds_cluster" "flutter_chat_db" {
  cluster_identifier      = "flutter-chat-db-${var.environment}"
  engine                  = "aurora-postgresql"
  engine_version          = "14.9"
  database_name           = "flutter_chat"
  master_username         = var.db_username
  master_password         = var.db_password
  backup_retention_period = var.environment == "production" ? 30 : 7
  preferred_backup_window = "07:00-09:00"
  
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.flutter_chat_subnet_group.name
  
  storage_encrypted = true
  kms_key_id       = aws_kms_key.rds_encryption.arn
  
  skip_final_snapshot = var.environment != "production"
  
  enabled_cloudwatch_logs_exports = ["postgresql"]
}

# ElastiCache for Redis
resource "aws_elasticache_replication_group" "flutter_chat_redis" {
  replication_group_id       = "flutter-chat-redis-${var.environment}"
  description                = "Redis cluster for Flutter Chat App"
  
  node_type                  = "cache.t3.micro"
  port                       = 6379
  parameter_group_name       = "default.redis7"
  
  num_cache_clusters         = 2
  automatic_failover_enabled = true
  multi_az_enabled          = true
  
  subnet_group_name = aws_elasticache_subnet_group.flutter_chat_cache_subnet.name
  security_group_ids = [aws_security_group.redis_sg.id]
  
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = var.redis_auth_token
}
```

## Monitoring & Observability

### Comprehensive Monitoring Setup
```dart
class MonitoringManager {
  static Future<void> initializeMonitoring() async {
    // 1. Application Performance Monitoring
    await _initializeAPM();
    
    // 2. Infrastructure monitoring
    await _initializeInfrastructureMonitoring();
    
    // 3. Business metrics monitoring
    await _initializeBusinessMetrics();
    
    // 4. Security monitoring
    await _initializeSecurityMonitoring();
  }
  
  static Future<void> _initializeAPM() async {
    // Configure Datadog/New Relic/AppDynamics
    await APMService.configure(
      serviceName: 'flutter-chat-app',
      environment: Environment.current,
      sampleRate: 0.1, // 10% sampling in production
      enableRUM: true, // Real User Monitoring
      enableSynthetics: true,
    );
    
    // Custom metrics
    APMService.registerCustomMetrics([
      'message_delivery_time',
      'websocket_connection_duration',
      'offline_sync_queue_size',
      'memory_usage_per_conversation',
      'crash_rate',
      'user_session_duration',
    ]);
  }
  
  static Future<void> trackPerformanceMetric(
    String metricName,
    double value,
    Map<String, String> tags,
  ) async {
    await APMService.recordMetric(
      name: metricName,
      value: value,
      tags: tags,
      timestamp: DateTime.now(),
    );
    
    // Alert if metric exceeds threshold
    await _checkMetricThresholds(metricName, value);
  }
  
  static Future<void> _checkMetricThresholds(
    String metricName,
    double value,
  ) async {
    final thresholds = {
      'message_delivery_time': 100.0, // 100ms
      'memory_usage_per_conversation': 150.0 * 1024 * 1024, // 150MB
      'crash_rate': 0.001, // 0.1%
      'websocket_reconnection_rate': 0.05, // 5%
    };
    
    final threshold = thresholds[metricName];
    if (threshold != null && value > threshold) {
      await AlertManager.sendAlert(
        severity: AlertSeverity.warning,
        message: 'Metric $metricName exceeded threshold: $value > $threshold',
        tags: {'metric': metricName, 'value': value.toString()},
      );
    }
  }
}
```

### Alerting & Incident Response
```dart
class AlertManager {
  static const Map<AlertSeverity, Duration> escalationTimeouts = {
    AlertSeverity.critical: Duration(minutes: 5),
    AlertSeverity.high: Duration(minutes: 15),
    AlertSeverity.medium: Duration(hours: 1),
    AlertSeverity.low: Duration(hours: 4),
  };
  
  static Future<void> sendAlert(
    AlertSeverity severity,
    String message,
    Map<String, String> tags,
  ) async {
    final alert = Alert(
      id: _generateAlertId(),
      severity: severity,
      message: message,
      tags: tags,
      timestamp: DateTime.now(),
      status: AlertStatus.open,
    );
    
    // Store alert
    await _alertStorage.store(alert);
    
    // Send notifications
    await _sendNotifications(alert);
    
    // Schedule escalation
    await _scheduleEscalation(alert);
  }
  
  static Future<void> _sendNotifications(Alert alert) async {
    switch (alert.severity) {
      case AlertSeverity.critical:
        await _sendPagerDutyAlert(alert);
        await _sendSlackAlert(alert, '#critical-alerts');
        await _sendEmailAlert(alert, 'oncall@chatapp.com');
        break;
      case AlertSeverity.high:
        await _sendSlackAlert(alert, '#alerts');
        await _sendEmailAlert(alert, 'team@chatapp.com');
        break;
      case AlertSeverity.medium:
        await _sendSlackAlert(alert, '#monitoring');
        break;
      case AlertSeverity.low:
        await _logAlert(alert);
        break;
    }
  }
}
```
