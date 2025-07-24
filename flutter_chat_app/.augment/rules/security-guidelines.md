# Security Guidelines Rules
**Type:** Always  
**Description:** Security best practices for Flutter messaging applications

## Data Protection
- Encrypt sensitive data at rest
- Use secure storage for credentials
- Never store passwords in plain text
- Implement proper key management
- Clear sensitive data from memory

## Network Security
- Use HTTPS/WSS for all communications
- Implement certificate pinning
- Validate SSL certificates
- Use secure WebSocket connections
- Encrypt message content end-to-end

## Authentication
- Implement proper token management
- Use secure token storage
- Handle token refresh automatically
- Implement session timeout
- Use strong authentication methods

## Input Validation
- Validate all user inputs
- Sanitize data before processing
- Prevent injection attacks
- Use parameterized queries
- Implement rate limiting

## API Security
- Use API keys securely
- Implement proper authorization
- Validate API responses
- Handle API errors securely
- Log security events

## Local Storage
- Use encrypted databases
- Secure shared preferences
- Clear cache on logout
- Implement data retention policies
- Handle storage permissions properly

## Code Security
- Obfuscate release builds
- Remove debug information
- Use ProGuard/R8 for Android
- Implement root/jailbreak detection
- Protect against reverse engineering

## Privacy
- Implement data minimization
- Handle user consent properly
- Provide data deletion options
- Implement privacy controls
- Follow GDPR/privacy regulations

## Vulnerability Management
- Keep dependencies updated
- Scan for security vulnerabilities
- Implement security testing
- Handle security incidents
- Monitor for threats

## Secure Development
- Follow secure coding practices
- Conduct security code reviews
- Use static analysis tools
- Implement security testing
- Train developers on security
