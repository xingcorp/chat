---
type: "agent_requested"
description: "Example description"
---
# Performance Optimization Rules
**Type:** Always  
**Description:** Performance optimization for enterprise Flutter messaging apps

## Performance Targets
- App startup: <2s cold start
- Message delivery: <100ms latency
- Memory usage: <150MB peak
- UI rendering: 60fps (16ms frames)
- Connection recovery: <5s

## Memory Management
- Always dispose StreamSubscriptions
- Close StreamControllers properly
- Cancel Timers in dispose methods
- Use weak references when appropriate
- Monitor memory usage in development

## Widget Optimization
- Use `const` constructors everywhere possible
- Implement `RepaintBoundary` for expensive widgets
- Use `AutomaticKeepAliveClientMixin` sparingly
- Prefer `StatelessWidget` over `StatefulWidget`
- Extract build methods into separate widgets

## List Performance
- Use `ListView.builder` for large lists
- Implement virtual scrolling
- Use `itemExtent` when items have fixed height
- Cache list item heights
- Implement pagination for large datasets

## Image Optimization
- Use `CachedNetworkImage` for network images
- Implement proper image caching
- Resize images appropriately
- Use WebP format when possible
- Lazy load images in lists

## Network Optimization
- Implement request batching
- Use connection pooling
- Cache API responses
- Implement offline-first strategy
- Compress request/response data

## Database Optimization
- Use indexed queries
- Implement proper pagination
- Use batch operations for multiple inserts
- Cache frequently accessed data
- Clean up old data regularly

## Background Processing
- Use isolates for heavy computations
- Implement proper background sync
- Handle app lifecycle changes
- Use WorkManager for scheduled tasks
- Minimize background processing

## Build Optimization
- Use `flutter build --release` for production
- Enable code splitting
- Remove debug code in release builds
- Optimize asset sizes
- Use tree shaking to remove unused code

## Monitoring
- Track app startup time
- Monitor memory usage
- Measure frame rendering time
- Track network request latency
- Use performance profiling tools
