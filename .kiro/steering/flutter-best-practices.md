---
inclusion: fileMatch
fileMatchPattern: ['flutter_chat_app/**/*.dart']
---

# Flutter Best Practices

## MANDATORY Base Classes

### 1. Logging: Use AppLogger (NOT Logger)
```dart
// ❌ FORBIDDEN
import 'package:logger/logger.dart';
final Logger _logger = Logger();

// ✅ REQUIRED
import 'package:flutter_chat_app/core/utils/logger.dart';

@injectable
class MyService {
  final AppLogger _logger;
  
  MyService({required AppLogger logger}) : _logger = logger;
  
  void doSomething() {
    _logger.info('Operation started');
    _logger.error('Error occurred', error);
  }
}
```

### 2. StatefulWidget: Use BaseStatefulWidget
```dart
// ❌ FORBIDDEN
class MyPage extends StatefulWidget { }
class _MyPageState extends State<MyPage> {
  void update() => setState(() {}); // Can crash!
}

// ✅ REQUIRED
import 'package:flutter_chat_app/core/base/base_widget.dart';

class MyPage extends BaseStatefulWidget {
  const MyPage({super.key});
  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends BaseState<MyPage> {
  void update() => safeSetState(() {}); // Safe!
  
  @override
  void onAppResumed() { /* Handle resume */ }
  
  @override
  void onAppPaused() { /* Handle pause */ }
}
```

**Why**: BaseState provides safe setState, lifecycle logging, memory leak prevention

## Performance Rules

### Widget Performance
```dart
// ✅ ALWAYS use const constructors
const Text('Hello');
const SizedBox(height: 16);

// ✅ Use ListView.builder for long lists (NOT ListView)
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(
    key: ValueKey(items[index].id), // Always use keys
    item: items[index],
  ),
)

// ✅ Extract widgets to prevent unnecessary rebuilds
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _Header(), // Won't rebuild
        _Content(), // Only this rebuilds
      ],
    );
  }
}

// ✅ Use RepaintBoundary for complex animations
RepaintBoundary(child: ComplexAnimatedWidget())
```

### Memory Management
```dart
// ✅ ALWAYS dispose resources
@override
void dispose() {
  _controller.dispose();
  _scrollController.dispose();
  _subscription.cancel();
  super.dispose();
}

// ✅ Use CachedNetworkImage for network images
CachedNetworkImage(
  imageUrl: url,
  memCacheWidth: 400,
  maxWidthDiskCache: 800,
)
```

## Async & Streams

### Async Patterns
```dart
// ✅ Use async/await with proper error handling
Future<void> loadData() async {
  try {
    final data = await repository.getData();
    safeSetState(() => _data = data);
  } catch (e) {
    _logger.error('Error loading data', e);
  }
}

// ✅ Use Future.wait for parallel operations
final results = await Future.wait([
  repository.getUsers(),
  repository.getMessages(),
]);

// ✅ Use compute for heavy computations
Future<List<Photo>> processPhotos(List<Photo> photos) async {
  return compute(_processPhotosIsolate, photos);
}

static List<Photo> _processPhotosIsolate(List<Photo> photos) {
  return photos.map((p) => p.resize()).toList();
}
```

### Stream Patterns
```dart
// ✅ ALWAYS cancel stream subscriptions
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
    if (snapshot.hasError) return ErrorWidget(snapshot.error);
    if (!snapshot.hasData) return const LoadingIndicator();
    return MessageWidget(snapshot.data!);
  },
)
```

## Navigation & Routing

```dart
// ✅ Use GoRouter with type safety
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
  ],
);

// ✅ Navigate with context
context.go('/chat/123');
context.push('/profile');
context.pop();

// ✅ Pass complex objects via extra
context.push('/chat/123', extra: ChatPageArgs(chatId: '123'));
```

## Responsive Design

```dart
// ✅ Use LayoutBuilder for responsive layouts
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth > 600) {
      return DesktopLayout();
    }
    return MobileLayout();
  },
)

// ✅ Use MediaQuery for screen info
final size = MediaQuery.of(context).size;
final padding = MediaQuery.of(context).padding;

// ✅ Use Flexible/Expanded properly
Row(
  children: [
    Flexible(flex: 1, child: Container()),
    Flexible(flex: 2, child: Container()),
  ],
)
```

## Security & Validation

```dart
// ✅ Use flutter_secure_storage for sensitive data
final storage = FlutterSecureStorage();
await storage.write(key: 'token', value: token);
final token = await storage.read(key: 'token');

// ✅ Validate user input
String? validateEmail(String? value) {
  if (value == null || value.isEmpty) return 'Email is required';
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  if (!emailRegex.hasMatch(value)) return 'Invalid email';
  return null;
}

// ✅ Use HTTPS only
final dio = Dio(BaseOptions(
  baseUrl: 'https://api.example.com',
  validateStatus: (status) => status! < 500,
));
```$'## Critical Mistakes to Avoid

```dart
// ❌ FORBIDDEN: setState directly (use safeSetState from BaseState)
setState(() => _data = data); // Can crash if disposed!

// ❌ FORBIDDEN: Logger directly (use AppLogger via DI)
final Logger _logger = Logger();

// ❌ FORBIDDEN: BuildContext across async gaps without checking
Future<void> loadData() async {
  await Future.delayed(Duration(seconds: 1));
  Navigator.of(context).push(...); // Context might be invalid!
}
// ✅ CORRECT: Check mounted
Future<void> loadData() async {
  await Future.delayed(Duration(seconds: 1));
  if (mounted) Navigator.of(context).push(...);
}

// ❌ FORBIDDEN: Creating functions in build method
Widget build(BuildContext context) {
  return ElevatedButton(
    onPressed: () => print('Pressed'), // Creates new function every build!
    child: const Text('Press'),
  );
}
// ✅ CORRECT: Use method reference
Widget build(BuildContext context) {
  return ElevatedButton(
    onPressed: _onPressed,
    child: const Text('Press'),
  );
}

// ❌ FORBIDDEN: Empty catch blocks
try {
  await operation();
} catch (e) {} // Don't ignore errors!
// ✅ CORRECT: Log errors
try {
  await operation();
} catch (e) {
  _logger.error('Operation failed', e);
}

// ❌ FORBIDDEN: Unnecessary GlobalKey usage
// Use only when you need to access widget state from outside

// ❌ FORBIDDEN: ListView without builder for long lists
ListView(children: items.map((item) => ItemWidget(item)).toList());
// ✅ CORRECT: Use ListView.builder
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)
```

## Performance Monitoring

```dart
// ✅ Use Firebase Performance for tracking
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
```

## Documentation Guidelines

### CRITICAL: Minimize Documentation Files

**DO NOT create markdown documentation files after every fix unless explicitly requested.**

**When to Create Documentation:**
- ✅ User explicitly requests it
- ✅ Major architectural changes requiring explanation
- ✅ Complex features needing usage guides
- ✅ API documentation for public interfaces

**When NOT to Create Documentation:**
- ❌ After bug fixes
- ❌ After refactoring
- ❌ After error fixes
- ❌ For routine maintenance

**What to Do Instead:**
- ✅ Write clear commit messages
- ✅ Add inline code comments
- ✅ Update existing documentation if needed
- ✅ Provide verbal summary to user

**Examples:**
```
❌ BAD: Create INJECTABLE_FIXES_COMPLETE.md after fixing 2 files
✅ GOOD: Fix files, commit with clear message, summarize verbally

❌ BAD: Create PHASE_3_COMPLETE.md after fixing BLoC errors
✅ GOOD: Fix errors, commit, summarize in chat

✅ GOOD: Create ARCHITECTURE.md when user asks "document the architecture"
✅ GOOD: Update README.md when adding new features
```

---

**Remember**: Profile first, then optimize. Keep code clean, documentation minimal.
