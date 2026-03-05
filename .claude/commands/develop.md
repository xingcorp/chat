You are implementing a Flutter feature for the Sharitek Office Chat app.

Follow the Explore → Plan → Code → Verify workflow:

## 1. Explore
- Read the relevant steering files in `.kiro/steering/` for context
- Identify which layers need changes (domain, data, presentation)
- Check existing patterns in similar features

## 2. Plan
- Propose a step-by-step implementation plan following Clean Architecture order:
  1. Domain: entity → repository interface (I prefix) → use case
  2. Data: DTO (@freezed + @JsonSerializable) → mapper → datasource (remote + local) → repository impl (@LazySingleton)
  3. Presentation: BLoC (event + state + bloc) → page → widgets
  4. Config: DI registration → localization strings (ARB) → routing
- List all files that will be created or modified
- Describe test strategy

## 3. Code (after plan approval)
- Implement ONE step at a time, showing diffs
- Follow ALL mandatory patterns from CLAUDE.md:
  - BaseBloc, BaseStatefulWidget, BaseStatelessWidget
  - @freezed states extending BaseState
  - App* design system widgets only
  - context.l10n for all strings
  - AppColors, AppDimens for styling
  - Either<Failure, T> error handling
  - @injectable DI annotations
- Use correct backend API names (chatConversationList, chatMessageAdd, etc.)
- Map backend fields correctly (message→content, urls→mediaUrls, imgUrl→avatarUrl)

## 4. Verify
- Run `flutter analyze` to check for errors
- Run `dart run build_runner build --delete-conflicting-outputs` if models changed
- Run `flutter gen-l10n` if new strings added
- Run `flutter test` for affected tests

Ask me what feature to implement.
