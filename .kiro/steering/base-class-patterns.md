# Base Class Patterns - MANDATORY

> All code MUST follow these patterns. No exceptions.

## 1. BLoC - Extend BaseBloc

```dart
// ✅ CORRECT
@injectable
class ChatBloc extends BaseBloc<ChatEvent, ChatState> {
  ChatBloc({required UseCase useCase, required Logger logger})
      : super(const ChatState.initial()) {
    on<Event>(_onEvent);
  }
  
  Future<void> _onEvent(Event event, Emitter<State> emit) async {
    emitLoading(message: 'Loading...');
    final result = await useCase();
    result.fold(
      (failure) => emitError(failure.message, error: failure),
      (data) => emit(State.success(data)),
    );
  }
}

// ❌ WRONG - Don't extend Bloc directly
class ChatBloc extends Bloc<ChatEvent, ChatState> { }
```

## 2. State - Extend BaseState

```dart
// ✅ CORRECT
@freezed
class ChatState extends BaseState with _$ChatState {
  const factory ChatState.initial() = ChatInitial;
  const factory ChatState.loading({String? message}) = ChatLoading;
  const factory ChatState.loaded({required List<Data> data}) = ChatLoaded;
  const factory ChatState.error({required String message}) = ChatError;
}

// ❌ WRONG
abstract class ChatState extends Equatable { }
```

## 3. StatefulWidget - Extend BaseStatefulWidget

```dart
// ✅ CORRECT
class MyWidget extends BaseStatefulWidget {
  const MyWidget({super.key});
  
  @override
  MyWidgetState createState() => MyWidgetState();
}

class MyWidgetState extends BaseState<MyWidget> {
  @override
  void onAppResumed() { }
  
  void _update() {
    safeSetState(() { }); // Use safeSetState, not setState
  }
  
  @override
  Widget build(BuildContext context) => Container();
}

// ❌ WRONG
class MyWidget extends StatefulWidget { }
```

## 4. StatelessWidget - Extend BaseStatelessWidget

```dart
// ✅ CORRECT
class MyWidget extends BaseStatelessWidget {
  const MyWidget({super.key});
  
  @override
  Widget buildContent(BuildContext context) => Container();
}

// ❌ WRONG
class MyWidget extends StatelessWidget { }
```

## 5. Constants - Use AppConstants

```dart
// ✅ CORRECT
Container(
  padding: const EdgeInsets.all(AppConstants.kDefaultPadding),
  margin: const EdgeInsets.symmetric(horizontal: AppConstants.kSmallPadding),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(AppConstants.kDefaultBorderRadius),
  ),
)

AnimatedOpacity(duration: AppConstants.kDefaultAnimationDuration)

if (file.size > AppConstants.kMaxAttachmentSize) { }

// ❌ WRONG - Hardcoded values
padding: const EdgeInsets.all(16.0)
margin: const EdgeInsets.symmetric(horizontal: 8.0)
borderRadius: BorderRadius.circular(12.0)
duration: Duration(milliseconds: 300)
if (file.size > 25 * 1024 * 1024) { }
```

## 6. Logging - Use Logger

```dart
// ✅ CORRECT
@injectable
class UseCase {
  final Logger _logger;
  
  UseCase({required Logger logger}) : _logger = logger;
  
  Future<void> call() async {
    _logger.i('Starting operation');
    _logger.e('Error occurred', error: exception);
  }
}

// ❌ WRONG
print('Starting operation');
debugPrint('Error occurred');
```

## 7. Localization - Use context.l10n

```dart
// ✅ CORRECT
Text(context.l10n.addReaction)
Text(context.l10n.editMessage)
SnackBar(content: Text(context.l10n.errorAddingReaction))

// ❌ WRONG
Text('Add Reaction')
Text('Edit Message')
```

## 8. DI - Use @injectable

```dart
// ✅ CORRECT
@injectable
class UseCase {
  final Repository _repository;
  final Logger _logger;
  
  UseCase({required Repository repository, required Logger logger})
      : _repository = repository, _logger = logger;
}

@LazySingleton(as: IRepository)
class RepositoryImpl implements IRepository { }

// ❌ WRONG
class UseCase {
  final repository = RepositoryImpl();
}
```

## 9. Reuse Widgets

```dart
// ✅ CORRECT
ErrorDisplayWidget(failure: failure, onRetry: onRetry)
ConnectionStatusWidget(showDetails: true)

// ❌ WRONG - Don't recreate
Widget _buildError(String message) => Container(child: Text(message));
```

## 10. Use const

```dart
// ✅ CORRECT
const SizedBox(height: AppConstants.kDefaultPadding)
const Divider()
const CircularProgressIndicator()

// ❌ WRONG
SizedBox(height: AppConstants.kDefaultPadding)
Divider()
```

## Checklist

- [ ] BLoCs extend `BaseBloc<Event, State>`
- [ ] States extend `BaseState`
- [ ] StatefulWidgets extend `BaseStatefulWidget`
- [ ] StatelessWidgets extend `BaseStatelessWidget`
- [ ] Use `AppConstants` for dimensions/durations
- [ ] Use `Logger` (no `print()`)
- [ ] Use `context.l10n` for strings
- [ ] Use `@injectable` for DI
- [ ] Reuse common widgets
- [ ] Use `const` constructors

---

**Status**: MANDATORY | **Updated**: 2025-01-28
