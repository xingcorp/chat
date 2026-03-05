# Presentation Layer Rules
# Applies to: flutter_chat_app/lib/presentation/**/*.dart

## BLoC Rules

1. **MUST extend `BaseBloc`** — never raw `Bloc`
   ```dart
   // ✅ CORRECT
   @injectable
   class ChatBloc extends BaseBloc<ChatEvent, ChatState> { ... }

   // ❌ WRONG
   class ChatBloc extends Bloc<ChatEvent, ChatState> { ... }
   ```

2. **States MUST use `@freezed` + extend `BaseState`**
   ```dart
   @freezed
   class ChatState extends BaseState with _$ChatState {
     const factory ChatState.initial() = ChatInitial;
     const factory ChatState.loading({String? message}) = ChatLoading;
     const factory ChatState.loaded({required List<Chat> data}) = ChatLoaded;
     const factory ChatState.error({required String message}) = ChatError;
   }
   ```

3. **BLoCs MUST be `@injectable`**

4. **Dispose all stream subscriptions in `close()`**

## Widget Rules

1. **MUST extend base classes**
   - `BaseStatefulWidget` / `BaseState<T>` — not `StatefulWidget` / `State<T>`
   - `BaseStatelessWidget` — not `StatelessWidget`

2. **Use `safeSetState()` not `setState()`** in BaseState

3. **All UI components MUST use App* design system**
   - `AppText()` not `Text()`
   - `AppButton()` not `ElevatedButton()`
   - `AppTextField()` not `TextField()`
   - `AppListView()` not `ListView()`
   - `AppAlertDialog` not `AlertDialog`
   - `AppSnackBar` not `SnackBar`
   - `AppProgressIndicator()` not `CircularProgressIndicator()`
   - `AppAvatar()` not `CircleAvatar()`

4. **All strings via `context.l10n`**
   - ✅ `AppText(context.l10n.save)`
   - ❌ `AppText('Save')`

5. **All colors via `AppColors`**
   - ✅ `AppColors.textPrimaryDarkMode`
   - ❌ `Colors.white`
   - ❌ `Color(0xFF000000)`

6. **All dimensions via `AppDimens`**
   - ✅ `EdgeInsets.all(AppDimens.paddingMedium)`
   - ❌ `EdgeInsets.all(16.0)`

7. **No Presentation → Data imports**
   - ❌ `import 'package:flutter_chat_app/data/models/...';`
   - ✅ `import 'package:flutter_chat_app/domain/entities/...';`
