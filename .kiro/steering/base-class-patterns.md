---
inclusion: always
---

# Base Class Patterns - MANDATORY

> All code MUST use these base classes and patterns. No exceptions.

## Source Files

- BaseWidget/BaseState: #[[file:flutter_chat_app/lib/core/base/base_widget.dart]]
- BaseBloc: #[[file:flutter_chat_app/lib/presentation/blocs/base/base_bloc.dart]]
- BaseBlocState: #[[file:flutter_chat_app/lib/presentation/blocs/base/base_state.dart]]
- BaseUseCase: #[[file:flutter_chat_app/lib/core/base/base_usecase.dart]]
- BaseRepository: #[[file:flutter_chat_app/lib/core/base/base_repository.dart]]
- AppConstants: #[[file:flutter_chat_app/lib/core/constants/app_constants.dart]]
- Logger: #[[file:flutter_chat_app/lib/core/utils/logger.dart]]

## 1. BLoC → extend BaseBloc

```dart
// ✅ CORRECT
@injectable
class ChatBloc extends BaseBloc<ChatEvent, ChatState> {
  ChatBloc({required IRepository repository, required Logger logger})
      : super(const ChatState.initial()) { on<Event>(_onEvent); }
  
  Future<void> _onEvent(Event event, Emitter<State> emit) async {
    emitLoading(message: 'Loading...');
    final result = await _repository.getData();
    result.fold(
      (failure) => emitError(failure.message, error: failure),
      (data) => emit(State.loaded(data: data)),
    );
  }
}
// ❌ WRONG: class ChatBloc extends Bloc<...> { }
```

## 2. State → extend BaseState + @freezed

```dart
@freezed
class ChatState extends BaseState with _$ChatState {
  const factory ChatState.initial() = ChatInitial;
  const factory ChatState.loading({String? message}) = ChatLoading;
  const factory ChatState.loaded({required List<Data> data}) = ChatLoaded;
  const factory ChatState.error({required String message}) = ChatError;
}
// ❌ WRONG: abstract class ChatState extends Equatable { }
```

## 3. Widgets → extend BaseStatefulWidget / BaseStatelessWidget

```dart
// StatefulWidget
class MyWidget extends BaseStatefulWidget {
  const MyWidget({super.key});
  @override
  MyWidgetState createState() => MyWidgetState();
}
class MyWidgetState extends BaseState<MyWidget> {
  void _update() { safeSetState(() { }); } // NOT setState
  @override
  Widget build(BuildContext context) => Container();
}

// StatelessWidget
class MyWidget extends BaseStatelessWidget {
  const MyWidget({super.key});
  @override
  Widget buildContent(BuildContext context) => Container();
}
// ❌ WRONG: extends StatefulWidget / StatelessWidget
```

## 4. Constants → AppConstants / AppDimens

```dart
// ✅ padding: EdgeInsets.all(AppConstants.kDefaultPadding)
// ✅ borderRadius: BorderRadius.circular(AppConstants.kDefaultBorderRadius)
// ✅ duration: AppConstants.kDefaultAnimationDuration
// ❌ padding: EdgeInsets.all(16.0)  — no hardcoded values
```

## 5. Logging → Logger (never print)

```dart
// ✅ _logger.i('Operation completed');  _logger.e('Failed', error: e);
// ❌ print('...');  debugPrint('...');
```

## 6. Localization → context.l10n (never hardcode strings)

```dart
// ✅ AppText(context.l10n.save)   AppButton(label: context.l10n.confirm)
// ❌ AppText('Save')   AppButton(label: 'Confirm')
```

## 7. DI → @injectable annotations

```dart
// ✅ @injectable class UseCase { UseCase({required IRepo repo}); }
// ✅ @LazySingleton(as: IRepo) class RepoImpl implements IRepo { }
// ❌ final repo = RepoImpl();  — no manual instantiation
```

## 8. Other Rules

- Use `const` constructors wherever possible
- Use `final` over `var` for immutables
- Use `is` checks, not `as` casts
- Use `??` / `?.`, not `!` null assertion
- Dispose streams/subscriptions in `close()` / `dispose()`
- Reuse existing widgets (ErrorDisplayWidget, ConnectionStatusWidget)
