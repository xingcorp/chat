---
title: Flutter Best Practices & Performance
inclusion: conditional
fileMatchPattern: "flutter_chat_app/**/*.dart"
priority: medium
---

# Flutter Best Practices & Performance Optimization

## 🎯 Critical Architecture Rules

### Logging - ALWAYS Use AppLogger
```dart
// ❌ NEVER use Logger directly
import 'package:logger/logger.dart';
final Logger _logger = Logger();

// ✅ ALWAYS use AppLogger via DI
import 'package:flutter_chat_app/core/utils/logger.dart';

@injectable
class MyService {
  final AppLogger _logger;
  
  MyService({required AppLogger logger}) : _logger = logger;
  
  void doSomething() {
    _logger.info('Operation started');
    _logger.debug('Debug info');
    _logger.warning('Warning message');
    _logger.error('Error occurred', error);
  }
}
```

### Widgets - ALWAYS Use BaseStatefulWidget
```dart
// ❌ NEVER use StatefulWidget directly
class MyPage extends StatefulWidget {
  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  void updateData() {
    setState(() {}); // Can crash if disposed!
  }
}

// ✅ ALWAYS use BaseStatefulWidget
import 'package:flutter_chat_app/core/base/base_widget.dart';

class MyPage extends BaseStatefulWidget {
  const MyPage({super.key});
  
  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends BaseState<MyPage> {
  // Automatic lifecycle logging
  // Automatic WidgetsBindingObserver
  
  void updateData() {
    safeSetState(() {}); // Safe - won't crash!
  }
  
  @override
  void onAppResumed() {
    // Handle app resume
  }
  
  @override
  void onAppPaused() {
    // Handle app pause
  }
}
```

**Benefits:**
- ✅ AppLogger: Consistent logging, structured context, performance tracking
- ✅ BaseStatefulWidget: Safe setState, automatic lifecycle logging, memory leak prevention

## Performance Optimization

### Widget Optimization
```dart
// ✅ Use const constructors
const Text('Hello');
const SizedBox(height: 16);
const Padding(padding: EdgeInsets.all(8));

// ✅ Use RepaintBoundary for complex widgets
RepaintBoundary(
  child: ComplexAnimatedWidget(),
)

// ✅ Use ListView.builder for long lists
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)

// ❌ Don't use ListView with all items
ListView(
  children: items.map((item) => ItemWidget(item)).toList(),
)

// ✅ Use keys for list items
ListView.builder(
  itemBuilder: (context, index) => ItemWidget(
    key: ValueKey(items[index].id),
    item: items[index],
  ),
)
```

### Image Optimization
```dart
// ✅ Use CachedNetworkImage
CachedNetworkImage(
  imageUrl: url,
  placeholder: (context, url) => const ShimmerLoading(),
  errorWidget: (context, url, error) => const Icon(Icons.error),
  memCacheWidth: 400, // Resize in memory
  maxWidthDiskCache: 800, // Resize on disk
)

// ✅ Precache important images
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  precacheImage(const AssetImage('assets/logo.png'), context);
}

// ✅ Use appropriate image formats
// - PNG for images with transparency
// - JPEG for photos
// - WebP for better compression
// - SVG for icons and logos
```

### Memory Management
```dart
// ✅ Dispose controllers
@override
void dispose() {
  _controller.dispose();
  _scrollController.dispose();
  _focusNode.dispose();
  _subscription.cancel();
  super.dispose();
}

// ✅ Use AutomaticKeepAliveClientMixin for tabs
class MyTab extends StatefulWidget {
  @override
  State<MyTab> createState() => _MyTabState();
}

class _MyTabState extends State<MyTab> 
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  
  @override
  Widget build(BuildContext context) {
    super.build(context); // Don't forget this!
    return Container();
  }
}
```

### Build Optimization
```dart
// ✅ Extract widgets to reduce rebuilds
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _Header(), // Extracted, won't rebuild
        _Content(), // Only this rebuilds
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();
  
  @override
  Widget build(BuildContext context) => AppBar(title: const Text('Title'));
}

// ✅ Use builder methods sparingly
// Only when you need context or need to pass parameters
Widget _buildHeader(String title) {
  return AppBar(title: Text(title));
}
```

## Async & Isolates

### Async Best Practices
```dart
// ✅ Use async/await properly
Future<void> loadData() async {
  try {
    final data = await repository.getData();
    setState(() => _data = data);
  } catch (e) {
    logger.e('Error loading data', error: e);
  }
}

// ✅ Use Future.wait for parallel operations
Future<void> loadMultipleData() async {
  final results = await Future.wait([
    repository.getUsers(),
    repository.getMessages(),
    repository.getSettings(),
  ]);
  
  final users = results[0] as List<User>;
  final messages = results[1] as List<Message>;
  final settings = results[2] as Settings;
}

// ✅ Use compute for heavy computations
Future<List<Photo>> processPhotos(List<Photo> photos) async {
  return compute(_processPhotosIsolate, photos);
}

static List<Photo> _processPhotosIsolate(List<Photo> photos) {
  // Heavy processing here
  return photos.map((photo) => photo.resize()).toList();
}
```

### Stream Best Practices
```dart
// ✅ Cancel stream subscriptions
late final StreamSubscription _subscription;

@override
void initState() {
  super.initState();
  _subscription = stream.listen(_onData);
}

@override
void dispose() {
  _subscription.cancel();
  super.dispose();
}

// ✅ Use StreamBuilder for UI
StreamBuilder<Message>(
  stream: messageStream,
  builder: (context, snapshot) {
    if (snapshot.hasError) {
      return ErrorWidget(snapshot.error);
    }
    
    if (!snapshot.hasData) {
      return const LoadingIndicator();
    }
    
    return MessageWidget(snapshot.data!);
  },
)
```

## Navigation

### GoRouter Best Practices
```dart
// ✅ Define routes with type safety
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/chat/:id',
      builder: (context, state) {
        final chatId = state.pathParameters['id']!;
        return ChatPage(chatId: chatId);
      },
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfilePage(),
      routes: [
        GoRoute(
          path: 'settings',
          builder: (context, state) => const SettingsPage(),
        ),
      ],
    ),
  ],
);

// ✅ Navigate with type safety
context.go('/chat/123');
context.push('/profile/settings');
context.pop();

// ✅ Pass complex objects via extra
context.push(
  '/chat/123',
  extra: ChatPageArgs(
    chatId: '123',
    initialMessage: message,
  ),
);
```

## Responsive Design

### Layout Best Practices
```dart
// ✅ Use LayoutBuilder for responsive layouts
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth > 600) {
      return DesktopLayout();
    } else {
      return MobileLayout();
    }
  },
)

// ✅ Use MediaQuery for screen info
final size = MediaQuery.of(context).size;
final padding = MediaQuery.of(context).padding;
final isLandscape = size.width > size.height;

// ✅ Use Flexible and Expanded properly
Row(
  children: [
    Flexible(
      flex: 1,
      child: Container(), // Takes 1/3 of space
    ),
    Flexible(
      flex: 2,
      child: Container(), // Takes 2/3 of space
    ),
  ],
)
```

## Accessibility

### A11y Best Practices
```dart
// ✅ Add semantic labels
Semantics(
  label: 'Send message button',
  child: IconButton(
    icon: const Icon(Icons.send),
    onPressed: _sendMessage,
  ),
)

// ✅ Use proper contrast ratios
// Text: 4.5:1 minimum
// Large text: 3:1 minimum

// ✅ Support screen readers
ExcludeSemantics(
  child: DecorativeImage(),
)

// ✅ Make touch targets at least 48x48
SizedBox(
  width: 48,
  height: 48,
  child: IconButton(
    icon: const Icon(Icons.close),
    onPressed: _close,
  ),
)
```

## Security

### Security Best Practices
```dart
// ✅ Use flutter_secure_storage for sensitive data
final storage = FlutterSecureStorage();
await storage.write(key: 'token', value: token);
final token = await storage.read(key: 'token');

// ✅ Validate user input
String? validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return 'Email is required';
  }
  
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  if (!emailRegex.hasMatch(value)) {
    return 'Invalid email format';
  }
  
  return null;
}

// ✅ Use HTTPS only
final dio = Dio(BaseOptions(
  baseUrl: 'https://api.example.com',
  validateStatus: (status) => status! < 500,
));

// ✅ Implement certificate pinning (production)
// See: https://pub.dev/packages/dio_http_certificate_pinning
```

## Common Pitfalls

### Avoid These Mistakes
```dart
// ❌ Don't use setState directly - use safeSetState from BaseState
setState(() => _data = data); // Can crash if disposed!

// ✅ Use safeSetState from BaseState
safeSetState(() => _data = data); // Safe!

// ❌ Don't call setState after dispose (if not using BaseState)
if (mounted) {
  setState(() => _data = data);
}

// ❌ Don't use Logger directly - use AppLogger
final Logger _logger = Logger();

// ✅ Use AppLogger via DI
final AppLogger _logger;
MyClass({required AppLogger logger}) : _logger = logger;

// ❌ Don't use BuildContext across async gaps
// BAD:
Future<void> loadData() async {
  await Future.delayed(Duration(seconds: 1));
  Navigator.of(context).push(...); // Context might be invalid!
}

// GOOD:
Future<void> loadData() async {
  await Future.delayed(Duration(seconds: 1));
  if (mounted) {
    Navigator.of(context).push(...);
  }
}

// ❌ Don't create functions in build method
Widget build(BuildContext context) {
  // BAD: Creates new function every build
  return ElevatedButton(
    onPressed: () => print('Pressed'),
    child: const Text('Press'),
  );
}

// GOOD: Use method reference
Widget build(BuildContext context) {
  return ElevatedButton(
    onPressed: _onPressed,
    child: const Text('Press'),
  );
}

void _onPressed() {
  print('Pressed');
}

// ❌ Don't use GlobalKey unnecessarily
// Use only when you need to access widget state from outside

// ❌ Don't ignore errors
try {
  await operation();
} catch (e) {
  // Don't leave empty!
  logger.e('Operation failed', error: e);
}
```

## Performance Monitoring

### Track Performance
```dart
// ✅ Use Firebase Performance
final trace = FirebasePerformance.instance.newTrace('load_messages');
await trace.start();

try {
  final messages = await repository.getMessages();
  trace.setMetric('message_count', messages.length);
} finally {
  await trace.stop();
}

// ✅ Use Timeline for profiling
Timeline.startSync('expensive_operation');
try {
  // Expensive operation
} finally {
  Timeline.finishSync();
}

// ✅ Monitor frame rendering
WidgetsBinding.instance.addTimingsCallback((timings) {
  for (final timing in timings) {
    if (timing.totalSpan.inMilliseconds > 16) {
      logger.w('Frame took ${timing.totalSpan.inMilliseconds}ms');
    }
  }
});
```

---

**Remember**: Premature optimization is the root of all evil. Profile first, then optimize!


## 📝 Documentation Rules

### CRITICAL: Minimize Documentation Creation

**Rule**: Do NOT create markdown documentation files after every fix unless explicitly requested by the user.

**Why**:
- Creates noise in the repository
- Wastes time and resources
- Makes git history cluttered
- User can see the work in code changes

**When to Create Documentation**:
- ✅ User explicitly requests documentation
- ✅ Major architectural changes that need explanation
- ✅ Complex features that need usage guide
- ✅ API documentation for public interfaces

**When NOT to Create Documentation**:
- ❌ After every bug fix
- ❌ After every refactoring
- ❌ After every error fix
- ❌ For routine maintenance work

**What to Do Instead**:
- ✅ Write clear commit messages
- ✅ Add inline code comments
- ✅ Update existing documentation if needed
- ✅ Provide verbal summary to user

**Example**:
```
❌ BAD: Create INJECTABLE_FIXES_COMPLETE.md after fixing 2 files
✅ GOOD: Fix the files, commit with clear message, tell user verbally

❌ BAD: Create PHASE_3_COMPLETE.md after fixing BLoC errors
✅ GOOD: Fix errors, commit, summarize in chat

✅ GOOD: Create ARCHITECTURE.md when user asks "document the architecture"
✅ GOOD: Update README.md when adding new features
```

**Commit Message Format** (instead of docs):
```
fix: Brief description of what was fixed

- Detailed point 1
- Detailed point 2
- Impact/results

Technical details if needed.
```

This keeps the repository clean and focuses on code quality over documentation quantity.
