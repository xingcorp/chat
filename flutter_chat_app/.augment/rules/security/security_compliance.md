# Security & Compliance Rules - Enterprise Messaging App

**Type**: Always  
**Description**: Comprehensive security standards and compliance requirements for enterprise messaging platform with end-to-end encryption and data protection

## Security Architecture Overview

### Data Protection Standards
```dart
// GDPR/CCPA Compliance Requirements
class DataProtectionStandards {
  static const Map<String, DataClassification> dataClassifications = {
    'user_messages': DataClassification.confidential,
    'user_profiles': DataClassification.personal,
    'conversation_metadata': DataClassification.internal,
    'system_logs': DataClassification.internal,
    'analytics_data': DataClassification.anonymized,
  };
  
  static const Duration dataRetentionPeriod = Duration(days: 2555); // 7 years
  static const Duration userDataDeletionWindow = Duration(days: 30);
  
  static Future<void> enforceDataRetention() async {
    // Implement automatic data purging
    await _purgeExpiredMessages();
    await _anonymizeOldAnalytics();
    await _cleanupDeletedUserData();
  }
}
```

### End-to-End Encryption Implementation
```dart
class E2EEncryptionManager {
  static const String encryptionAlgorithm = 'AES-256-GCM';
  static const String keyExchangeProtocol = 'X3DH'; // Extended Triple Diffie-Hellman
  static const String signatureAlgorithm = 'Ed25519';
  
  // Message encryption before sending
  static Future<EncryptedMessage> encryptMessage(
    String plaintext,
    String conversationId,
    String recipientPublicKey,
  ) async {
    // 1. Generate ephemeral key pair
    final ephemeralKeyPair = await _generateEphemeralKeyPair();
    
    // 2. Perform key agreement
    final sharedSecret = await _performKeyAgreement(
      ephemeralKeyPair.privateKey,
      recipientPublicKey,
    );
    
    // 3. Derive encryption key
    final encryptionKey = await _deriveEncryptionKey(
      sharedSecret,
      conversationId,
    );
    
    // 4. Encrypt message
    final encryptedData = await _encryptWithAES256GCM(
      plaintext,
      encryptionKey,
    );
    
    // 5. Sign encrypted message
    final signature = await _signMessage(
      encryptedData,
      ephemeralKeyPair.privateKey,
    );
    
    return EncryptedMessage(
      ciphertext: encryptedData.ciphertext,
      nonce: encryptedData.nonce,
      ephemeralPublicKey: ephemeralKeyPair.publicKey,
      signature: signature,
      timestamp: DateTime.now(),
    );
  }
  
  // Message decryption after receiving
  static Future<String> decryptMessage(
    EncryptedMessage encryptedMessage,
    String privateKey,
  ) async {
    // 1. Verify signature
    final isValidSignature = await _verifySignature(
      encryptedMessage.ciphertext,
      encryptedMessage.signature,
      encryptedMessage.ephemeralPublicKey,
    );
    
    if (!isValidSignature) {
      throw SecurityException('Invalid message signature');
    }
    
    // 2. Perform key agreement
    final sharedSecret = await _performKeyAgreement(
      privateKey,
      encryptedMessage.ephemeralPublicKey,
    );
    
    // 3. Derive decryption key
    final decryptionKey = await _deriveEncryptionKey(
      sharedSecret,
      conversationId,
    );
    
    // 4. Decrypt message
    return await _decryptWithAES256GCM(
      encryptedMessage.ciphertext,
      encryptedMessage.nonce,
      decryptionKey,
    );
  }
}
```

## Authentication & Authorization

### Multi-Factor Authentication (MFA)
```dart
class MFAManager {
  static const List<MFAMethod> supportedMethods = [
    MFAMethod.totp,        // Time-based OTP
    MFAMethod.sms,         // SMS verification
    MFAMethod.email,       // Email verification
    MFAMethod.biometric,   // Fingerprint/Face ID
    MFAMethod.hardware,    // Hardware security keys
  ];
  
  static Future<bool> verifyMFA(
    String userId,
    MFAMethod method,
    String token,
  ) async {
    switch (method) {
      case MFAMethod.totp:
        return await _verifyTOTP(userId, token);
      case MFAMethod.biometric:
        return await _verifyBiometric(userId);
      case MFAMethod.hardware:
        return await _verifyHardwareKey(userId, token);
      default:
        throw UnsupportedError('MFA method not supported: $method');
    }
  }
  
  static Future<void> enforceMFAPolicy(String userId) async {
    final userRole = await _getUserRole(userId);
    final requiredMethods = _getMFARequirements(userRole);
    
    for (final method in requiredMethods) {
      final isConfigured = await _isMFAConfigured(userId, method);
      if (!isConfigured) {
        throw SecurityException('MFA method required: $method');
      }
    }
  }
}
```

### Role-Based Access Control (RBAC)
```dart
enum UserRole {
  admin,
  moderator,
  user,
  guest,
  service,
}

enum Permission {
  // Message permissions
  sendMessage,
  editMessage,
  deleteMessage,
  forwardMessage,
  
  // Conversation permissions
  createConversation,
  addParticipants,
  removeParticipants,
  deleteConversation,
  
  // Administrative permissions
  viewAnalytics,
  manageUsers,
  configureSettings,
  accessLogs,
}

class RBACManager {
  static const Map<UserRole, Set<Permission>> rolePermissions = {
    UserRole.admin: {
      Permission.sendMessage,
      Permission.editMessage,
      Permission.deleteMessage,
      Permission.createConversation,
      Permission.addParticipants,
      Permission.removeParticipants,
      Permission.deleteConversation,
      Permission.viewAnalytics,
      Permission.manageUsers,
      Permission.configureSettings,
      Permission.accessLogs,
    },
    UserRole.moderator: {
      Permission.sendMessage,
      Permission.editMessage,
      Permission.deleteMessage,
      Permission.createConversation,
      Permission.addParticipants,
      Permission.removeParticipants,
      Permission.viewAnalytics,
    },
    UserRole.user: {
      Permission.sendMessage,
      Permission.editMessage,
      Permission.createConversation,
      Permission.addParticipants,
    },
    UserRole.guest: {
      Permission.sendMessage,
    },
  };
  
  static Future<bool> hasPermission(
    String userId,
    Permission permission,
  ) async {
    final userRole = await _getUserRole(userId);
    return rolePermissions[userRole]?.contains(permission) ?? false;
  }
  
  static Future<void> enforcePermission(
    String userId,
    Permission permission,
  ) async {
    final hasAccess = await hasPermission(userId, permission);
    if (!hasAccess) {
      throw UnauthorizedException(
        'User $userId lacks permission: $permission',
      );
    }
  }
}
```

## Input Validation & Sanitization

### Message Content Validation
```dart
class MessageValidator {
  static const int maxMessageLength = 4096;
  static const int maxFileSize = 50 * 1024 * 1024; // 50MB
  static const Set<String> allowedFileTypes = {
    'image/jpeg', 'image/png', 'image/gif', 'image/webp',
    'video/mp4', 'video/webm',
    'audio/mp3', 'audio/wav', 'audio/ogg',
    'application/pdf',
    'text/plain',
  };
  
  static ValidationResult validateMessage(MessageInput input) {
    final errors = <String>[];
    
    // Content validation
    if (input.content.isEmpty && input.attachments.isEmpty) {
      errors.add('Message cannot be empty');
    }
    
    if (input.content.length > maxMessageLength) {
      errors.add('Message exceeds maximum length');
    }
    
    // XSS prevention
    if (_containsXSSPatterns(input.content)) {
      errors.add('Message contains potentially malicious content');
    }
    
    // File validation
    for (final attachment in input.attachments) {
      if (attachment.size > maxFileSize) {
        errors.add('File size exceeds limit: ${attachment.name}');
      }
      
      if (!allowedFileTypes.contains(attachment.mimeType)) {
        errors.add('File type not allowed: ${attachment.mimeType}');
      }
      
      if (_containsMalware(attachment)) {
        errors.add('File contains malware: ${attachment.name}');
      }
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
  
  static String sanitizeContent(String content) {
    // Remove potentially dangerous HTML/script tags
    content = content.replaceAll(RegExp(r'<script[^>]*>.*?</script>', 
        caseSensitive: false, multiLine: true), '');
    
    // Escape HTML entities
    content = content
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
    
    return content;
  }
}
```

## Secure Storage & Key Management

### Local Data Encryption
```dart
class SecureStorageManager {
  static const String keyAlias = 'flutter_chat_master_key';
  
  static Future<void> storeSecurely(String key, String value) async {
    // 1. Get or generate master key
    final masterKey = await _getMasterKey();
    
    // 2. Encrypt value
    final encryptedValue = await _encryptWithMasterKey(value, masterKey);
    
    // 3. Store in secure storage
    await _secureStorage.write(key: key, value: encryptedValue);
  }
  
  static Future<String?> retrieveSecurely(String key) async {
    // 1. Get encrypted value
    final encryptedValue = await _secureStorage.read(key: key);
    if (encryptedValue == null) return null;
    
    // 2. Get master key
    final masterKey = await _getMasterKey();
    
    // 3. Decrypt and return
    return await _decryptWithMasterKey(encryptedValue, masterKey);
  }
  
  static Future<void> clearAllSecureData() async {
    await _secureStorage.deleteAll();
    await _keystore.deleteKey(keyAlias);
  }
}
```

### Key Rotation Strategy
```dart
class KeyRotationManager {
  static const Duration keyRotationInterval = Duration(days: 90);
  
  static Future<void> rotateEncryptionKeys() async {
    final conversations = await _getAllActiveConversations();
    
    for (final conversation in conversations) {
      // 1. Generate new key pair
      final newKeyPair = await _generateKeyPair();
      
      // 2. Re-encrypt recent messages with new key
      await _reEncryptRecentMessages(conversation.id, newKeyPair);
      
      // 3. Update key in secure storage
      await _updateConversationKey(conversation.id, newKeyPair);
      
      // 4. Notify participants of key rotation
      await _notifyKeyRotation(conversation.id, newKeyPair.publicKey);
    }
  }
  
  static Future<void> scheduleKeyRotation() async {
    Timer.periodic(keyRotationInterval, (_) async {
      await rotateEncryptionKeys();
    });
  }
}
```

## Compliance & Auditing

### Audit Logging
```dart
class SecurityAuditLogger {
  static Future<void> logSecurityEvent(SecurityEvent event) async {
    final auditEntry = AuditEntry(
      timestamp: DateTime.now(),
      eventType: event.type,
      userId: event.userId,
      action: event.action,
      resource: event.resource,
      outcome: event.outcome,
      ipAddress: event.ipAddress,
      userAgent: event.userAgent,
      additionalData: event.metadata,
    );
    
    // Store in secure audit log
    await _auditStorage.store(auditEntry);
    
    // Send to SIEM system if critical
    if (event.severity == SecuritySeverity.critical) {
      await _siemIntegration.sendAlert(auditEntry);
    }
  }
  
  static Future<List<AuditEntry>> getAuditTrail(
    String userId,
    DateTimeRange dateRange,
  ) async {
    return await _auditStorage.query(
      userId: userId,
      startDate: dateRange.start,
      endDate: dateRange.end,
    );
  }
}
```

### Compliance Monitoring
```dart
class ComplianceMonitor {
  static Future<ComplianceReport> generateComplianceReport() async {
    return ComplianceReport(
      gdprCompliance: await _checkGDPRCompliance(),
      hipaaCompliance: await _checkHIPAACompliance(),
      sox404Compliance: await _checkSOX404Compliance(),
      encryptionStatus: await _checkEncryptionStatus(),
      accessControlStatus: await _checkAccessControlStatus(),
      auditLogIntegrity: await _checkAuditLogIntegrity(),
      generatedAt: DateTime.now(),
    );
  }
  
  static Future<void> enforceDataResidency() async {
    final userLocations = await _getUserLocations();
    
    for (final user in userLocations) {
      final requiredRegion = _getRequiredDataRegion(user.location);
      final currentRegion = await _getCurrentDataRegion(user.id);
      
      if (requiredRegion != currentRegion) {
        await _migrateUserData(user.id, requiredRegion);
      }
    }
  }
}
```
