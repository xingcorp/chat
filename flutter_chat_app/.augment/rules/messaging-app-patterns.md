# Messaging App Patterns Rules
**Type:** Always  
**Description:** Specific patterns for enterprise messaging applications

## Real-time Communication
- Use WebSocket for real-time messaging
- Implement connection state management
- Handle reconnection with exponential backoff
- Support offline message queuing
- Optimize for <100ms message delivery

## Message Handling
- Implement optimistic UI updates
- Store messages locally first
- Sync with server in background
- Handle message status updates
- Support message retry mechanisms

## Performance Targets
- App startup: <2s cold start
- Message delivery: <100ms latency
- Memory usage: <150MB peak
- UI rendering: 60fps consistent
- Connection recovery: <5s

## Offline-First Strategy
- Cache messages locally
- Queue outgoing messages when offline
- Sync when connection restored
- Show offline indicators
- Handle conflicts gracefully

## Data Synchronization
- Use incremental sync
- Implement conflict resolution
- Handle concurrent updates
- Support pagination for large datasets
- Cache frequently accessed data

## Security Patterns
- Encrypt sensitive data locally
- Use secure WebSocket connections
- Implement proper authentication
- Validate all user inputs
- Handle token refresh automatically

## User Experience
- Show typing indicators
- Display read receipts
- Support message search
- Implement push notifications
- Handle deep links properly

## Scalability Patterns
- Use virtual scrolling for message lists
- Implement message pagination
- Cache user profiles
- Optimize image loading
- Support background sync

## Error Recovery
- Retry failed operations
- Show meaningful error messages
- Provide manual retry options
- Log errors for debugging
- Graceful degradation when possible
